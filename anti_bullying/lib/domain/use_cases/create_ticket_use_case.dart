import '../entities/ticket_entity.dart';
import '../repository_contracts/ticket_repository.dart';

class CreateTicketUseCase {
  final TicketRepository repository;

  CreateTicketUseCase(this.repository);

  Future<void> call(CreateTicketParams params) async {
    final ticket = TicketEntity(
      studentID: params.studentID,
      title: params.title,
      description: params.description,
      createdAt: DateTime.now(),
    );

    await repository.createTicket(ticket);
  }
}

class CreateTicketParams {
  final String? studentID;
  final String title;
  final String description;

  CreateTicketParams({
    this.studentID,
    required this.title,
    required this.description,
  });
}