import 'package:flutter_bloc/flutter_bloc.dart';
import 'resolve_ticket_state.dart';
import '../../../domain/use_cases/resolve_ticket_use_case.dart';
import '../../../domain/use_cases/get_ticket_by_id_use_case.dart';

class ResolveTicketCubit extends Cubit<ResolveTicketState> {
  final ResolveTicketUseCase _resolveUseCase;
  final GetTicketByIdUseCase _getTicketUseCase;

  ResolveTicketCubit(this._resolveUseCase, this._getTicketUseCase)
      : super(ResolveTicketState.initial());

  Future<void> fetchTicket(String ticketId) async {
    emit(state.copyWith(loading: true, error: null, success: false));
    try {
      final ticket = await _getTicketUseCase.execute(ticketId);
      if (ticket == null) {
        emit(state.copyWith(loading: false, error: "Ticket not found", ticket: null));
      } else {
        emit(state.copyWith(loading: false, ticket: ticket, error: null));
      }
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> resolveTicket(String ticketId, String resolution) async {
    if (state.ticket == null) {
      emit(state.copyWith(error: "No ticket loaded"));
      return;
    }
    emit(state.copyWith(loading: true, error: null));
    try {
      await _resolveUseCase.execute(ticketId, resolution);
      emit(state.copyWith(loading: false, success: true));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  void reset() {
    emit(ResolveTicketState.initial());
  }
}