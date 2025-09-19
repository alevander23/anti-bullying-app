import '../entities/ticket_entity.dart';
import '../repository_contracts/ticket_repository.dart';

class GetTicketByIdUseCase {
  final TicketRepository repository;
  GetTicketByIdUseCase(this.repository);

  Future<TicketEntity?> execute(String ticketId) {
    return repository.getTicketById(ticketId);
  }
}