import '../../domain/entities/ticket_entity.dart';

class TicketModel extends TicketEntity {

  TicketModel({
    required super.studentID,
    required super.title,
    required super.description,
    required super.createdAt
  });

  // Convert from database map (you'll implement this based on your SQL schema)
  factory TicketModel.fromMap(Map<String, dynamic> map, String id) {
    return TicketModel(
      studentID: map['student_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentID': studentID,  // Firestore uses camelCase
      'title': title,
      'description': description,
      'createdAt': createdAt
    };
  }
}