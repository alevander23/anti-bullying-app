import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/use_cases/create_ticket_use_case.dart';

// Events
abstract class TicketFormEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TicketFormSubmitted extends TicketFormEvent {
  final String? studentID;
  final String title;
  final String description;

  TicketFormSubmitted({
    this.studentID,
    required this.title,
    required this.description,
  });

  @override
  List<Object?> get props => [studentID, title, description];
}

// States
abstract class TicketFormState extends Equatable {
  @override
  List<Object?> get props => [];
}

class TicketFormInitial extends TicketFormState {}

class TicketFormSubmitting extends TicketFormState {}

class TicketFormSuccess extends TicketFormState {}

class TicketFormError extends TicketFormState {
  final String message;

  TicketFormError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class TicketFormBloc extends Bloc<TicketFormEvent, TicketFormState> {
  final CreateTicketUseCase createTicketUseCase;

  TicketFormBloc(this.createTicketUseCase) : super(TicketFormInitial()) {
    on<TicketFormSubmitted>(_onTicketFormSubmitted);
  }

  Future<void> _onTicketFormSubmitted(
    TicketFormSubmitted event,
    Emitter<TicketFormState> emit,
  ) async {
    emit(TicketFormSubmitting());

    try {
      final params = CreateTicketParams(
        studentID: event.studentID,
        title: event.title,
        description: event.description,
      );

      await createTicketUseCase(params);
      emit(TicketFormSuccess());
    } catch (e) {
      emit(TicketFormError(e.toString()));
    }
  }
}