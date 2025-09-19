import 'package:equatable/equatable.dart';

class TicketEntity extends Equatable {
  final String studentID; 
  final String title;
  final String description;
  final DateTime createdAt;
  
  TicketEntity({
    String? studentID,
    required this.title,
    required this.description,
    required this.createdAt,
  }) : studentID = studentID ?? "anon" {
    // Validate at entity creation
    if (title.isEmpty || title.length > 200) {
      throw ArgumentError('Title must be 1-200 characters');
    }
    if (description.isEmpty || description.length > 2000) {
      throw ArgumentError('Description must be 1-2000 characters');
    }
  }

  @override
  List<Object?> get props => [studentID, title, description, createdAt];
}