import 'package:staff_webapp/domain/entities/ticket_entity.dart';

abstract class TicketRepository {
  Future<void> resolveTicket(String ticketId, String resolution);
  Future<TicketEntity?> getTicketById(String ticketId);
}