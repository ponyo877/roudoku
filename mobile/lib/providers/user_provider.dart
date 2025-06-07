import 'package:flutter/material.dart';
import '../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  
  String _subscriptionType = 'free';
  int _listenedBooksCount = 0;
  int _totalListeningHours = 0;
  int _streakDays = 0;
  
  String get subscriptionType => _subscriptionType;
  int get listenedBooksCount => _listenedBooksCount;
  int get totalListeningHours => _totalListeningHours;
  int get streakDays => _streakDays;
  
  Future<void> loadUserStats(String userId) async {
    try {
      final stats = await _userService.getUserStats(userId);
      _subscriptionType = stats['subscriptionType'] ?? 'free';
      _listenedBooksCount = stats['listenedBooksCount'] ?? 0;
      _totalListeningHours = stats['totalListeningHours'] ?? 0;
      _streakDays = stats['streakDays'] ?? 0;
      notifyListeners();
    } catch (e) {
      print('Error loading user stats: $e');
    }
  }
  
  void updateListeningTime(int minutes) {
    _totalListeningHours = (_totalListeningHours * 60 + minutes) ~/ 60;
    notifyListeners();
  }
  
  void incrementListenedBooks() {
    _listenedBooksCount++;
    notifyListeners();
  }
  
  void updateStreak(int days) {
    _streakDays = days;
    notifyListeners();
  }
  
  void setSubscriptionType(String type) {
    _subscriptionType = type;
    notifyListeners();
  }
}