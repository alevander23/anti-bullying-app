import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/di.dart';
import 'package:staff_webapp/domain/use_cases/login_use_case.dart';
import 'package:staff_webapp/main.dart';
import 'package:staff_webapp/presentation/bloc/login_cubit.dart';
import 'package:staff_webapp/presentation/bloc/login_state.dart';
import 'package:staff_webapp/presentation/pages/accounts/create_user_page.dart';
import 'package:staff_webapp/presentation/pages/dashboard/dashboard_page.dart';
import 'package:staff_webapp/presentation/pages/waiting_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final LoginCubit _loginCubit;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideIn;

  // Brand colours — kept close to original blueGrey/blueAccent palette
  static const Color _bg = Color(0xFFF0F4F8);
  static const Color _cardBg = Colors.white;
  static const Color _accent = Color(0xFF1565C0); // deep blue
  static const Color _accentLight = Color(0xFF1E88E5);
  static const Color _textDark = Color(0xFF1A2B4A);
  static const Color _textMid = Color(0xFF546E7A);
  static const Color _border = Color(0xFFCFD8DC);
  static const Color _inputFill = Color(0xFFF7FAFC);

  @override
  void initState() {
    super.initState();
    _loginCubit = LoginCubit(getIt<LoginUseCase>());
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideIn = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textMid, fontSize: 14, fontWeight: FontWeight.w500),
      prefixIcon: Icon(icon, color: _textMid, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _accentLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _loginCubit,
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // Subtle decorative gradient orbs in background
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accentLight.withOpacity(0.12),
                      _accentLight.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accent.withOpacity(0.08),
                      _accent.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideIn,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo / App icon area
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_accent, _accentLight],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: _accent.withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Title + subtitle
                          const Text(
                            'Staff Portal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Sign in to your account to continue',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: _textMid,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Card
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: _cardBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE8EDF2), width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1A2B4A).withOpacity(0.06),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF1A2B4A).withOpacity(0.03),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: BlocConsumer<LoginCubit, LoginState>(
                              listener: (context, state) {
                                if (state.success) {
                                  if (state.user!.isAuthorized) {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => DashboardPage()));
                                  } else {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) => WaitingPage()));
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Row(
                                        children: [
                                          Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                                          SizedBox(width: 8),
                                          Text('Login successful'),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF2E7D32),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                }
                                if (state.error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(state.error!)),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFFC62828),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                      margin: const EdgeInsets.all(16),
                                    ),
                                  );
                                }
                              },
                              builder: (context, state) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Email field label
                                    const Text(
                                      'Email address',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(fontSize: 15, color: _textDark),
                                      decoration: _fieldDecoration(
                                        label: 'you@example.com',
                                        icon: Icons.mail_outline_rounded,
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Password field label
                                    const Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    StatefulBuilder(
                                      builder: (context, setLocalState) => TextField(
                                        controller: passwordController,
                                        obscureText: _obscurePassword,
                                        style: const TextStyle(fontSize: 15, color: _textDark),
                                        decoration: _fieldDecoration(
                                          label: '••••••••',
                                          icon: Icons.lock_outline_rounded,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: _textMid,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() => _obscurePassword = !_obscurePassword);
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),

                                    // Sign in button
                                    SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: state.loading
                                            ? null
                                            : () {
                                                context.read<LoginCubit>().attemptLogin(
                                                      emailController.text,
                                                      passwordController.text,
                                                    );
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _accent,
                                          disabledBackgroundColor: _accent.withOpacity(0.6),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ).copyWith(
                                          overlayColor: WidgetStateProperty.resolveWith(
                                            (states) => states.contains(WidgetState.hovered)
                                                ? Colors.white.withOpacity(0.08)
                                                : null,
                                          ),
                                        ),
                                        child: state.loading
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Sign in',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.2,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Footer links
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  // Handle forgot password
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: _textMid,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                child: const Text('Forgot password?'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => CreateUserPage()),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: _accentLight,
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('Create account →'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}