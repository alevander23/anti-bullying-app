import 'package:staff_webapp/data/data_sources/staff_remote_data_source.dart';
import 'package:staff_webapp/domain/entities/ticket_entity.dart';
import 'package:staff_webapp/domain/repository_contracts/ticket_repository.dart';


class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;

  TicketRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> resolveTicket(String ticketId, String resolution) {
    return remoteDataSource.resolveTicket(ticketId, resolution);
  }

  @override
  Future<TicketEntity?> getTicketById(String ticketId) {
    return remoteDataSource.getTicketById(ticketId);
  }
}