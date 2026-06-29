// lib/data/data_sources/group_remote_data_source.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:staff_webapp/data/data_models/group_model.dart';
import 'package:staff_webapp/domain/entities/group_entity.dart';

class GroupRemoteDataSource {
  final FirebaseFirestore _firestore;

  GroupRemoteDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // Convenience property for accessing the groups collection
  CollectionReference get _groups => _firestore.collection('groups');

  // Returns the timeline subcollection for a specific group
  CollectionReference _timeline(String groupId) =>
      _groups.doc(groupId).collection('timeline');

  // ── Read ──────────────────────────────────────────────────────────────────

  // Retrieves all groups associated with a specific school, ordered by most recent update
  Future<List<IncidentGroup>> getGroupsForSchool(String schoolId) async {
    final snap = await _groups
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs.map(GroupModel.fromFirestore).toList();
  }

  // Retrieves all groups, ordered by most recent update
  Future<List<IncidentGroup>> getAllGroups() async {
    final snap = await _groups
        .orderBy('updatedAt', descending: true)
        .get();
    return snap.docs.map(GroupModel.fromFirestore).toList();
  }

  // Retrieves a single group by ID, returns null if not found
  Future<IncidentGroup?> getGroup(String groupId) async {
    final doc = await _groups.doc(groupId).get();
    if (!doc.exists) return null;
    return GroupModel.fromFirestore(doc);
  }

  // Retrieves timeline entries for a specific group, ordered by timestamp
  Future<List<GroupTimelineEntry>> getTimeline(String groupId) async {
    final snap = await _timeline(groupId)
        .orderBy('timestamp', descending: true)
        .get();
    return snap.docs.map((d) {
      final m = d.data() as Map<String, dynamic>;
      return GroupTimelineEntry(
        id: d.id,
        message: m['message'] as String? ?? '',
        adminName: m['adminName'] as String? ?? '',
        timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    }).toList();
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  // Creates a new group and initializes its timeline with a creation event
  Future<String> createGroup(IncidentGroup group) async {
    final ref = await _groups.add(GroupModel.toFirestore(group));
    // Write the initial timeline entry
    await _addTimelineEntry(ref.id, GroupTimelineEntry(
      id: '',
      message: 'Group created by ${group.createdBy}',
      adminName: group.createdBy,
      timestamp: DateTime.now(),
    ));
    return ref.id;
  }

  // Updates an existing group with new data
  Future<void> updateGroup(String groupId, Map<String, dynamic> data) =>
      _groups.doc(groupId).update(data);

  // Deletes a group and its associated data
  Future<void> deleteGroup(String groupId) =>
      _groups.doc(groupId).delete();

  // Adds a new timeline entry to a group's timeline
  Future<void> addTimelineEntry(String groupId, GroupTimelineEntry entry) =>
      _addTimelineEntry(groupId, entry);

  // Internal method to add a timeline entry with server timestamp
  Future<void> _addTimelineEntry(
      String groupId, GroupTimelineEntry entry) async {
    await _timeline(groupId).add({
      'message': entry.message,
      'adminName': entry.adminName,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}