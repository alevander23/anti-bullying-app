import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Import your Cubit and States here

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is AuthSuccess) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        },
        builder: (context, state) {
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Welcome Back",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 40),
                  
                  // Email Field
                  const TextField(
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Login Button (Straight Email)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: state is AuthLoading ? null : () {
                        // Logic for email login
                      },
                      child: state is AuthLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Login with Email"),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text("OR"),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Google SSO Button
                  _SSOButton(
                    label: "Continue with Google",
                    icon: Icons.g_mobiledata, // Replace with actual Google Asset
                    color: Colors.white,
                    textColor: Colors.black87,
                    onPressed: () => context.read<AuthCubit>().signInWithGoogle(),
                  ),
                  
                  const SizedBox(height: 12),

                  // Microsoft SSO Button
                  _SSOButton(
                    label: "Continue with Microsoft",
                    icon: Icons.window, // Replace with actual MS Asset
                    color: const Color(0xFF2F2F2F),
                    textColor: Colors.white,
                    onPressed: () => context.read<AuthCubit>().signInWithMicrosoft(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}