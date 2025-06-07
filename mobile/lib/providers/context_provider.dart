import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ContextProvider extends ChangeNotifier {
  List<String> _selectedCategories = [];
  String? _readingPurpose;
  String? _currentGoal;
  int _dailyReadingGoal = 30; // minutes
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  
  List<String> get selectedCategories => _selectedCategories;
  String? get readingPurpose => _readingPurpose;
  String? get currentGoal => _currentGoal;
  int get dailyReadingGoal => _dailyReadingGoal;
  bool get reminderEnabled => _reminderEnabled;
  TimeOfDay get reminderTime => _reminderTime;
  
  ContextProvider() {
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    _selectedCategories = prefs.getStringList('selectedCategories') ?? [];
    _readingPurpose = prefs.getString('readingPurpose');
    _currentGoal = prefs.getString('currentGoal');
    _dailyReadingGoal = prefs.getInt('dailyReadingGoal') ?? 30;
    _reminderEnabled = prefs.getBool('reminderEnabled') ?? false;
    
    final hour = prefs.getInt('reminderHour');
    final minute = prefs.getInt('reminderMinute');
    if (hour != null && minute != null) {
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    }
    
    notifyListeners();
  }
  
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setStringList('selectedCategories', _selectedCategories);
    if (_readingPurpose != null) {
      await prefs.setString('readingPurpose', _readingPurpose!);
    }
    if (_currentGoal != null) {
      await prefs.setString('currentGoal', _currentGoal!);
    }
    await prefs.setInt('dailyReadingGoal', _dailyReadingGoal);
    await prefs.setBool('reminderEnabled', _reminderEnabled);
    await prefs.setInt('reminderHour', _reminderTime.hour);
    await prefs.setInt('reminderMinute', _reminderTime.minute);
  }
  
  void addCategory(String category) {
    if (!_selectedCategories.contains(category)) {
      _selectedCategories.add(category);
      _savePreferences();
      notifyListeners();
    }
  }
  
  void removeCategory(String category) {
    _selectedCategories.remove(category);
    _savePreferences();
    notifyListeners();
  }
  
  void setReadingPurpose(String purpose) {
    _readingPurpose = purpose;
    _savePreferences();
    notifyListeners();
  }
  
  void setCurrentGoal(String goal) {
    _currentGoal = goal;
    _savePreferences();
    notifyListeners();
  }
  
  void setDailyReadingGoal(int minutes) {
    _dailyReadingGoal = minutes;
    _savePreferences();
    notifyListeners();
  }
  
  void setReminderEnabled(bool enabled) {
    _reminderEnabled = enabled;
    _savePreferences();
    notifyListeners();
  }
  
  void setReminderTime(TimeOfDay time) {
    _reminderTime = time;
    _savePreferences();
    notifyListeners();
  }
}