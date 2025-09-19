import 'package:equatable/equatable.dart';

class TicketEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String status; // 👈 new field (e.g. "open", "resolved")

  const TicketEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.status,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        createdAt,
        status, // 👈 include in equality check
      ];
}