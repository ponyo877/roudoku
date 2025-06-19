import 'package:flutter/material.dart';

class SimpleSwipeCard extends StatelessWidget {
  final Map<String, dynamic> quoteData;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  const SimpleSwipeCard({
    super.key,
    required this.quoteData,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  @override
  Widget build(BuildContext context) {
    final quote = quoteData['quote'] as Map<String, dynamic>;
    final book = quoteData['book'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minHeight: 400, maxHeight: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Quote text
            Expanded(
              child: Center(
                child: Text(
                  quote['text'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Book information
            Column(
              children: [
                Text(
                  book['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  book['author'] ?? '',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onSwipeLeft,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                ElevatedButton(
                  onPressed: onSwipeRight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
