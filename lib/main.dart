import 'package:flutter/material.dart';

void main() {
  // FIXED: Corrected the initialization syntax so the compiler recognizes it properly
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @key
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // FIXED: Points to the single, clean LoginScreen below
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FIXED: Embedded SafeArea to prevent elements from sliding under Android 15 status bars
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Dashboard()),
                    );
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // FIXED: Embedded SafeArea for systemic layout alignment
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: const SafeArea(
        child: Center(
          child: Text(
            'Dashboard View',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}void 
