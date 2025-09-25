import 'package:flutter/material.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Page"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile section
            Center(
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage("assets/images/default_user.png"),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "John Doe",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "john.doe@email.com",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Actions
            const Text(
              "Actions",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.lock),
              title: const Text("Change Password"),
              onTap: () {
                // TODO: implement navigation
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("View Reports"),
              onTap: () {
                // TODO: implement navigation
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                // TODO: implement logout
              },
            ),
          ],
        ),
      ),
    );
  }
}
