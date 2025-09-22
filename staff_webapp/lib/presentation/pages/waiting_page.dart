import 'package:flutter/material.dart';

class WaitingPage extends StatelessWidget {
  const WaitingPage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              "Waiting for authorization...",
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
