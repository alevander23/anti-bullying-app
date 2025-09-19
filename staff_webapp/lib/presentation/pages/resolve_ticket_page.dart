import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:staff_webapp/presentation/bloc/resolve_ticket_cubit.dart';
import 'package:staff_webapp/presentation/bloc/resolve_ticket_state.dart';
import '../../domain/use_cases/resolve_ticket_use_case.dart';
import '../../domain/use_cases/get_ticket_by_id_use_case.dart';

class ResolveTicketPage extends StatefulWidget {
  const ResolveTicketPage({super.key});

  @override
  State<ResolveTicketPage> createState() => _ResolveTicketPageState();
}

class _ResolveTicketPageState extends State<ResolveTicketPage> {
  final _ticketIdController = TextEditingController();
  String? _selectedResolution;
  late final ResolveTicketCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = ResolveTicketCubit(
      GetIt.I<ResolveTicketUseCase>(),
      GetIt.I<GetTicketByIdUseCase>(),
    );
  }

  bool get _isTicketIdValid => _ticketIdController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final brandColor = Colors.indigo;

    return BlocProvider(
      create: (_) => _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F8),
        appBar: AppBar(
          backgroundColor: brandColor,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Resolve Incident',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: BlocConsumer<ResolveTicketCubit, ResolveTicketState>(
                listener: (context, state) {
                  if (state.success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Ticket resolved successfully"),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Reset the cubit after a small delay so user sees success
                    Future.delayed(const Duration(seconds: 1), () {
                      context.read<ResolveTicketCubit>().reset();
                    });
                  }
                  if (state.error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("❌ ${state.error}"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final isFormEnabled = _isTicketIdValid && !state.loading;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // HERO CARD
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [brandColor.shade700, brandColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield_outlined,
                                size: 48, color: Colors.white),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    "Safe Resolution",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "Incidents are confidential and will be resolved with care.",
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // FORM CARD
                      Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              // Ticket ID
                              TextField(
                                controller: _ticketIdController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.confirmation_number),
                                  labelText: 'Ticket ID',
                                  hintText: 'Enter the ticket ID',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: state.loading || !_isTicketIdValid
                                        ? null
                                        : () => _cubit.fetchTicket(
                                            _ticketIdController.text.trim(),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Ticket Display
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: state.ticket == null
                                    ? const Center(
                                        child: Text(
                                          "No ticket loaded yet",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  state.ticket!.title,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              // 👇 Status chip (label)
                                              Chip(
                                                label: Text(
                                                  "STATUS: ${state.ticket!.status.toUpperCase()}",
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                backgroundColor: state.ticket!.status == "resolved"
                                                    ? Colors.redAccent
                                                    : Colors.green,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(state.ticket!.description),
                                          const SizedBox(height: 10),
                                          Text(
                                            "Created: ${state.ticket!.createdAt.toLocal()}",
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                              ),

                              const SizedBox(height: 20),

                              // Resolution dropdown
                              DropdownButtonFormField<String>(
                                value: _selectedResolution,
                                items: const [
                                  DropdownMenuItem(value: 'genuine', child: Text('Genuine')),
                                  DropdownMenuItem(value: 'malicious', child: Text('Malicious')),
                                ],
                                onChanged: (state.ticket != null && !state.loading && state.ticket!.status != "closed")
                                  ? (val) => setState(() => _selectedResolution = val)
                                  : null,
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(Icons.rule_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  labelText: 'Resolution',
                                ),
                              ),

                              const SizedBox(height: 30),

                              // SUBMIT BUTTON
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: state.ticket != null &&
                                            _selectedResolution != null &&
                                            state.ticket!.status != "resolved"
                                        ? brandColor // enabled & open
                                        : state.ticket != null && state.ticket!.status == "resolved"
                                            ? Colors.redAccent // style for closed tickets exit button
                                            : Colors.grey[300], // disabled
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: state.ticket != null && !state.loading
                                      ? () {
                                          if (state.ticket!.status == "resolved") {
                                            // 👇 Exit just resets everything
                                            context.read<ResolveTicketCubit>().reset();
                                            _ticketIdController.clear();
                                            setState(() {
                                              _selectedResolution = null;
                                            });
                                          } else if (_selectedResolution != null) {
                                            // 👇 Regular close issue flow
                                            _cubit.resolveTicket(
                                              _ticketIdController.text.trim(),
                                              _selectedResolution!,
                                            );
                                          }
                                        }
                                      : null,
                                  child: state.loading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          state.ticket != null && state.ticket!.status == "resolved"
                                              ? "Exit Incident Issue" // 👈 new text for closed
                                              : "Close Incident",
                                          style: const TextStyle(fontSize: 16, color: Colors.white),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}