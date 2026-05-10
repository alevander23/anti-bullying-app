import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/presentation/bloc/auth_cubit.dart';
import 'package:staff_webapp/presentation/bloc/auth_state.dart';

class SSOLoginPage extends StatelessWidget {
  const SSOLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        // Side effects (navigation, toasts)
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          if (state is AuthSuccess || state is AuthSessionRestored) {
            // Replace the login page so Back doesn't return to it
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
        // Build 
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final cubit = context.read<AuthCubit>();

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Staff Portal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in with your work account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Microsoft button
                    _SSOButton(
                      label: 'Continue with Microsoft',
                      // Using Icons.window as a stand-in; swap for an SVG asset:
                      //   Image.asset('assets/images/ms_logo.svg', width: 20)
                      icon: Icons.window_rounded,
                      backgroundColor: const Color(0xFF2F2F2F),
                      foregroundColor: Colors.white,
                      isLoading: isLoading,
                      onPressed: cubit.signInWithMicrosoft,
                    ),

                    const SizedBox(height: 12),

                    // Google button
                    _SSOButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata_rounded,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      isLoading: isLoading,
                      onPressed: cubit.signInWithGoogle,
                      border: Border.all(color: Colors.grey.shade300),
                    ),

                    const SizedBox(height: 32),

                    // Loading indicator
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Reusable SSO button

class _SSOButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool isLoading;
  final VoidCallback onPressed;
  final BoxBorder? border;

  const _SSOButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.isLoading,
    required this.onPressed,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isLoading ? 0.6 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: isLoading ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: foregroundColor, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      color: foregroundColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
