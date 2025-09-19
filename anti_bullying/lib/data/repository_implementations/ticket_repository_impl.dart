// data/repository_implementations/ticket_repository_impl.dart
import '../../domain/entities/ticket_entity.dart';
import '../../domain/repository_contracts/ticket_repository.dart';
import '../data_sources/ticket_remote_data_source.dart';
import '../data_models/ticket_model.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;

  TicketRepositoryImpl(this.remoteDataSource);

  @override
  Future<String> createTicket(TicketEntity ticket) async {
    try {
      // Convert entity to model - since TicketModel extends TicketEntity
      final ticketModel = TicketModel(
        studentID: ticket.studentID,
        title: ticket.title,
        description: ticket.description,
        createdAt: ticket.createdAt
      );
      
      // Delegate to data source
      return await remoteDataSource.createTicket(ticketModel);
    } catch (e) {
      throw Exception('Repository error: $e');
    }
  }
}