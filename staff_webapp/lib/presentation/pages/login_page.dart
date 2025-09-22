import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:staff_webapp/di.dart';
import 'package:staff_webapp/domain/use_cases/login_use_case.dart';
import 'package:staff_webapp/main.dart';
import 'package:staff_webapp/presentation/bloc/login_cubit.dart';
import 'package:staff_webapp/presentation/bloc/login_state.dart';
import 'package:staff_webapp/presentation/pages/waiting_page.dart';

class LoginPage extends StatelessWidget {
  final LoginCubit _loginCubit = LoginCubit(getIt<LoginUseCase>());
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _loginCubit,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Big header
                Text(
                  "Login",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
                const SizedBox(height: 40),

                // Card-style container
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: BlocConsumer<LoginCubit, LoginState>(
                    listener: (context, state) {
                      if (state.success) {
                        if (state.user!.isAuthorized) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                        } else {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => WaitingPage()));
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("✅ Login successful"),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // Navigate to home or dashboard here
                        // Navigator.pushReplacementNamed(context, "/home");
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
                      return Column(
                        children: [
                          // Username
                          TextField(
                            controller: usernameController,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.person),
                              labelText: "Username",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.lock),
                              labelText: "Password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.loading
                                  ? null
                                  : () {
                                      String username = usernameController.text;
                                      String password = passwordController.text;
                                      context
                                          .read<LoginCubit>()
                                          .attemptLogin(username, password);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: state.loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Login",
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Small footer
                TextButton(
                  onPressed: () {
                    // Handle "forgot password" or navigation
                  },
                  child: Text(
                    "Forgot password?",
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
