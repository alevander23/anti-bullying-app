import 'package:cloud_functions/cloud_functions.dart';
import '../data_models/ticket_model.dart';

abstract class TicketRemoteDataSource {
  Future<String> createTicket(TicketModel ticket);
}

class TicketRemoteDataSourceImpl implements TicketRemoteDataSource {
  final FirebaseFunctions _functions;

  TicketRemoteDataSourceImpl(this._functions);

  @override
  Future<String> createTicket(TicketModel ticket) async {
    try {
      final callable = _functions.httpsCallable('createTicket');

      final result = await callable.call({
        'studentID': ticket.studentID,
        'title': ticket.title,
        'description': ticket.description,
      });

      final ticketId = result.data['ticket_id'] as String;
      return ticketId;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Cloud Function error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }
}