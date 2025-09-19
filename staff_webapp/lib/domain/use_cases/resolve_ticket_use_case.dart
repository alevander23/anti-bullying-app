import '../repository_contracts/ticket_repository.dart';

class ResolveTicketUseCase {
  final TicketRepository repository;

  ResolveTicketUseCase(this.repository);

  Future<void> execute(String ticketId, String resolution) {
    return repository.resolveTicket(ticketId, resolution);
  }
}