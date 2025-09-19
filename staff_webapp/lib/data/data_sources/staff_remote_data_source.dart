import 'package:cloud_functions/cloud_functions.dart';
import 'package:staff_webapp/domain/entities/ticket_entity.dart';

abstract class TicketRemoteDataSource {
  Future<void> resolveTicket(String ticketId, String resolution);
  Future<TicketEntity?> getTicketById(String ticketId);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final FirebaseFunctions _functions;

  TicketRemoteDataSourceImpl(this._functions);

  @override
  Future<TicketEntity?> getTicketById(String ticketId) async {
    final callable = _functions.httpsCallable('getTicketInfo');
    final result = await callable.call({'ticketId': ticketId});

    final data = Map<String, dynamic>.from(result.data);

    if (data.isEmpty) return null;

    return TicketEntity(
      id: data['id'] ?? ticketId, // returned by the function
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      createdAt: (data['createdAt'] != null)
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      status: data['status'] ?? 'open', // 👈 NEW FIELD
    );
  }

  @override
  Future<void> resolveTicket(String ticketId, String resolution) async {
    final callable = _functions.httpsCallable('updateTicketResolution');
    await callable.call({
      'ticketId': ticketId,
      'resolution': resolution,
    });
  }
}