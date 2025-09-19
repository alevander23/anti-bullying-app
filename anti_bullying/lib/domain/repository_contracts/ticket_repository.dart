import '../entities/ticket_entity.dart';

abstract class TicketRepository {
  Future<void> createTicket(TicketEntity ticket);
}