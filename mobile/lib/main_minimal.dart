import 'package:flutter/material.dart';

void main() {
  runApp(const MinimalRoudokuApp());
}

class MinimalRoudokuApp extends StatelessWidget {
  const MinimalRoudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roudoku',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Roudoku Mobile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.book,
              size: 100,
              color: Colors.blue,
            ),
            SizedBox(height: 20),
            Text(
              'Welcome to Roudoku!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Audio book reading app',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 40),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      '✅ Flutter 3.32.2 Running',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '✅ iOS Simulator Working',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '🚀 Ready for Development',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Roudoku is working! 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        },
        tooltip: 'Test App',
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}