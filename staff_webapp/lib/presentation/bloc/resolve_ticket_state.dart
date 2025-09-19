import 'package:equatable/equatable.dart';
import '../../../domain/entities/ticket_entity.dart';

class ResolveTicketState extends Equatable {
  final bool loading;
  final bool success;
  final String? error;
  final TicketEntity? ticket;

  const ResolveTicketState({
    this.loading = false,
    this.success = false,
    this.error,
    this.ticket,
  });

  factory ResolveTicketState.initial() => const ResolveTicketState();

  ResolveTicketState copyWith({
    bool? loading,
    bool? success,
    String? error,
    TicketEntity? ticket,
  }) {
    return ResolveTicketState(
      loading: loading ?? this.loading,
      success: success ?? this.success,
      error: error,
      ticket: ticket ?? this.ticket,
    );
  }

  @override
  List<Object?> get props => [loading, success, error, ticket];
}