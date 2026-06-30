require('dotenv').config();
const express     = require('express');
const multer      = require('multer');
const path         = require('path');
const fs           = require('fs');
const { v4: uuidv4 } = require('uuid');
const cors          = require('cors');
const helmet        = require('helmet');
const rateLimit      = require('express-rate-limit');
const admin          = require('firebase-admin');
const { fileTypeFromFile } = require('file-type');

// ── Firebase Admin setup ─────────────────────────────────────────────────
admin.initializeApp({
  credential: admin.credential.cert(
    require(process.env.FIREBASE_SERVICE_ACCOUNT_PATH)
  ),
});

const app = express();
app.use(cors());
app.use(helmet());

// ── Storage location ─────────────────────────────────────────────────────
const UPLOAD_DIR = path.resolve(process.env.UPLOAD_DIR || './uploads');
fs.mkdirSync(UPLOAD_DIR, { recursive: true });

// ── Multer config ────────────────────────────────────────────────────────
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const subdir = file.mimetype.startsWith('video/') ? 'videos' : 'images';
    const dest = path.join(UPLOAD_DIR, subdir);
    fs.mkdirSync(dest, { recursive: true });
    cb(null, dest);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${uuidv4()}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100 MB
    files: 5,
  },
  fileFilter: (req, file, cb) => {
    const allowedMimes = [
      'image/jpeg', 'image/png', 'image/webp', 'image/gif',
      'video/mp4', 'video/quicktime', 'video/webm', 'video/mov',
    ];
    const allowedExts = /\.(jpg|jpeg|png|webp|gif|mp4|mov|webm)$/i;

    const mimeOk = allowedMimes.includes(file.mimetype);
    const extOk  = allowedExts.test(file.originalname);

    if (mimeOk && extOk) {
      cb(null, true);
    } else {
      cb(new Error(`Rejected file type: ${file.mimetype}`));
    }
  },
});

// ── Auth middleware: any signed-in Firebase user (client app) ───────────
async function verifyFirebaseToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing auth token' });
  }
  try {
    req.firebaseUser = await admin.auth().verifyIdToken(
      authHeader.split('Bearer ')[1]
    );
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

// ── Auth middleware: must be an active admin (staff app) ────────────────
async function verifyStaffToken(req, res, next) {
  const authHeader = req.headers['authorization'];
  if (!authHeader?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorised' });
  }
  try {
    const decoded = await admin.auth().verifyIdToken(
      authHeader.split('Bearer ')[1]
    );
    const adminDoc = await admin.firestore()
      .collection('admins')
      .doc(decoded.uid)
      .get();

    if (!adminDoc.exists || !adminDoc.data().isActive) {
      return res.status(403).json({ error: 'Not an active admin' });
    }
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

// ── Rate limiting ─────────────────────────────────────────────────────────
const uploadLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { error: 'Too many uploads, try again later' },
});
const fetchLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
});

// ── Upload endpoint (client app to server) ─────────────────────────────────
app.post(
  '/upload',
  uploadLimiter,
  verifyFirebaseToken,
  upload.single('file'),
  async (req, res) => {
    if (!req.file) {
      return res.status(400).json({ error: 'No file received' });
    }

    try {
      const detected = await fileTypeFromFile(req.file.path);

      const allowedMimes = [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/gif',
        'video/mp4',
        'video/quicktime',
        'video/webm',
      ];

      if (!detected || !allowedMimes.includes(detected.mime)) {
        fs.unlinkSync(req.file.path);

        return res.status(400).json({
          error: 'Invalid file contents',
        });
      }

      const subdir = detected.mime.startsWith('video/')
        ? 'videos'
        : 'images';

      const fileUrl = `${req.protocol}://${req.get('host')}/uploads/${subdir}/${req.file.filename}`;

      console.log(
        `Saved: ${req.file.path} (${(req.file.size / 1024).toFixed(1)} KB)`
      );

      res.json({
        url: fileUrl,
        filename: req.file.filename,
        size: req.file.size,
        mimetype: detected.mime,
      });
    } catch (err) {
      if (req.file && fs.existsSync(req.file.path)) {
        fs.unlinkSync(req.file.path);
      }

      res.status(500).json({
        error: 'File validation failed',
      });
    }
  }
);

// ── File serving endpoint (staff app only) ────────────────────────────────
app.get(
  '/uploads/:type/:filename',
  fetchLimiter,
  verifyStaffToken,
  (req, res) => {
    const { type, filename } = req.params;

    if (!['images', 'videos'].includes(type)) {
      return res.status(400).json({ error: 'Invalid type' });
    }
    if (!/^[a-zA-Z0-9_-]+\.[a-zA-Z0-9]+$/.test(filename)) {
      return res.status(400).json({ error: 'Invalid filename' });
    }

    const filePath = path.join(UPLOAD_DIR, type, filename);
    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'File not found' });
    }
    res.sendFile(filePath);
  }
);

// Error handler
app.use((err, req, res, next) => {
  console.error(err.message);
  res.status(400).json({ error: err.message });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Upload server running on port ${PORT}`));