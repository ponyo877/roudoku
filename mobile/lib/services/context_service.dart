import 'dart:async';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:weather/weather.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/swipe.dart';

class ContextService {
  final SharedPreferences _prefs;
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();
  final WeatherFactory _weatherFactory;
  
  // Weather API key - in production, this should be stored securely
  static const String _weatherApiKey = 'your_openweathermap_api_key';
  
  // Cached context data
  ContextData? _lastKnownContext;
  Position? _lastKnownPosition;
  Timer? _contextUpdateTimer;
  
  // Sensors
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  String _deviceMotion = 'stationary';
  
  ContextService(this._prefs) : _weatherFactory = WeatherFactory(_weatherApiKey) {
    _startContextMonitoring();
  }

  /// Start monitoring context changes
  void _startContextMonitoring() {
    // Monitor device motion
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _updateDeviceMotion(event);
    });
    
    // Update context periodically
    _contextUpdateTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      _updateCachedContext();
    });
  }

  /// Get current context data
  Future<ContextData> getCurrentContext({
    String? userMood,
    String? userSituation,
    int? availableTime,
  }) async {
    try {
      // Get basic time context
      final now = DateTime.now();
      final timeOfDay = _getTimeOfDay(now);
      final dayOfWeek = _getDayOfWeek(now);
      final isWeekend = now.weekday >= 6;
      
      // Get location context (if permission granted)
      double? latitude, longitude;
      String? location;
      try {
        final position = await _getCurrentPosition();
        if (position != null) {
          latitude = position.latitude;
          longitude = position.longitude;
          location = await _getLocationName(position);
        }
      } catch (e) {
        print('Error getting location: $e');
        // Use cached location if available
        if (_lastKnownPosition != null) {
          latitude = _lastKnownPosition!.latitude;
          longitude = _lastKnownPosition!.longitude;
          location = _prefs.getString('last_known_location');
        }
      }

      // Get weather context
      String? weatherCondition;
      double? temperature, humidity;
      try {
        if (latitude != null && longitude != null) {
          final weather = await _getCurrentWeather(latitude, longitude);
          if (weather != null) {
            weatherCondition = weather.weatherMain;
            temperature = weather.temperature?.celsius;
            humidity = weather.humidity?.toDouble();
          }
        }
      } catch (e) {
        print('Error getting weather: $e');
      }

      // Get device context
      final batteryLevel = await _getBatteryLevel();
      final isCharging = await _getChargingStatus();
      final connectionType = await _getConnectionType();
      final screenBrightness = await _getScreenBrightness();

      final context = ContextData(
        latitude: latitude,
        longitude: longitude,
        location: location,
        weatherCondition: weatherCondition,
        temperature: temperature,
        humidity: humidity,
        timeOfDay: timeOfDay,
        dayOfWeek: dayOfWeek,
        isWeekend: isWeekend,
        userMood: userMood,
        userSituation: userSituation,
        availableTime: availableTime,
        batteryLevel: batteryLevel,
        isCharging: isCharging,
        connectionType: connectionType,
        deviceMotion: _deviceMotion,
        screenBrightness: screenBrightness,
      );

      // Cache the context
      _lastKnownContext = context;
      _cacheContext(context);
      
      return context;
    } catch (e) {
      print('Error getting current context: $e');
      // Return basic context if error occurs
      return _getBasicContext(userMood, userSituation, availableTime);
    }
  }

  /// Get cached context data
  ContextData? getCachedContext() {
    return _lastKnownContext;
  }

  /// Check location permission status
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  Future<LocationPermission> requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Get current position with permission check
  Future<Position?> _getCurrentPosition() async {
    final permission = await checkLocationPermission();
    
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      _lastKnownPosition = position;
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  /// Get location name from coordinates
  Future<String?> _getLocationName(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final locationName = [
          placemark.locality,
          placemark.administrativeArea,
          placemark.country,
        ].where((element) => element != null && element.isNotEmpty).join(', ');
        
        // Cache location name
        await _prefs.setString('last_known_location', locationName);
        return locationName;
      }
    } catch (e) {
      print('Error getting location name: $e');
    }
    return null;
  }

  /// Get current weather
  Future<Weather?> _getCurrentWeather(double latitude, double longitude) async {
    try {
      // Check if weather API key is configured
      if (_weatherApiKey == 'your_openweathermap_api_key') {
        print('Weather API key not configured');
        return null;
      }
      
      final weather = await _weatherFactory.currentWeatherByLocation(
        latitude,
        longitude,
      );
      return weather;
    } catch (e) {
      print('Error getting weather: $e');
      return null;
    }
  }

  /// Get battery level
  Future<double?> _getBatteryLevel() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      return batteryLevel / 100.0; // Convert to 0.0-1.0 range
    } catch (e) {
      print('Error getting battery level: $e');
      return null;
    }
  }

  /// Get charging status
  Future<bool?> _getChargingStatus() async {
    try {
      final batteryState = await _battery.batteryState;
      return batteryState == BatteryState.charging;
    } catch (e) {
      print('Error getting charging status: $e');
      return null;
    }
  }

  /// Get connection type
  Future<String?> _getConnectionType() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      switch (connectivityResult) {
        case ConnectivityResult.wifi:
          return 'wifi';
        case ConnectivityResult.mobile:
          return 'cellular';
        case ConnectivityResult.ethernet:
          return 'ethernet';
        case ConnectivityResult.bluetooth:
          return 'bluetooth';
        case ConnectivityResult.none:
          return 'offline';
        default:
          return 'unknown';
      }
    } catch (e) {
      print('Error getting connection type: $e');
      return null;
    }
  }

  /// Get screen brightness
  Future<double?> _getScreenBrightness() async {
    try {
      // Note: Screen brightness retrieval is platform-specific
      // This is a placeholder implementation
      // In a real app, you might use platform channels or specific plugins
      return null;
    } catch (e) {
      print('Error getting screen brightness: $e');
      return null;
    }
  }

  /// Update device motion based on accelerometer data
  void _updateDeviceMotion(AccelerometerEvent event) {
    final acceleration = (event.x.abs() + event.y.abs() + event.z.abs()) / 3;
    
    if (acceleration > 15) {
      _deviceMotion = 'vehicle';
    } else if (acceleration > 5) {
      _deviceMotion = 'walking';
    } else {
      _deviceMotion = 'stationary';
    }
  }

  /// Get time of day category
  String _getTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 18) return 'afternoon';
    return 'evening';
  }

  /// Get day of week
  String _getDayOfWeek(DateTime dateTime) {
    const weekdays = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return weekdays[dateTime.weekday - 1];
  }

  /// Get basic context when full context is unavailable
  ContextData _getBasicContext(String? userMood, String? userSituation, int? availableTime) {
    final now = DateTime.now();
    return ContextData(
      timeOfDay: _getTimeOfDay(now),
      dayOfWeek: _getDayOfWeek(now),
      isWeekend: now.weekday >= 6,
      userMood: userMood,
      userSituation: userSituation,
      availableTime: availableTime,
    );
  }

  /// Cache context data
  void _cacheContext(ContextData context) {
    try {
      // Save timestamp and basic context info
      _prefs.setString('last_context_time', DateTime.now().toIso8601String());
      if (context.location != null) {
        _prefs.setString('last_known_location', context.location!);
      }
      if (context.weatherCondition != null) {
        _prefs.setString('last_weather_condition', context.weatherCondition!);
      }
      if (context.temperature != null) {
        _prefs.setDouble('last_temperature', context.temperature!);
      }
    } catch (e) {
      print('Error caching context: $e');
    }
  }

  /// Update cached context periodically
  void _updateCachedContext() {
    getCurrentContext().then((context) {
      _lastKnownContext = context;
    }).catchError((e) {
      print('Error updating cached context: $e');
    });
  }

  /// Get mood suggestions based on context
  List<String> getMoodSuggestions(ContextData context) {
    final suggestions = <String>[];
    
    // Time-based suggestions
    switch (context.timeOfDay) {
      case 'morning':
        suggestions.addAll(['energetic', 'optimistic', 'focused']);
        break;
      case 'afternoon':
        suggestions.addAll(['productive', 'alert', 'busy']);
        break;
      case 'evening':
        suggestions.addAll(['relaxed', 'peaceful', 'reflective']);
        break;
      case 'night':
        suggestions.addAll(['calm', 'tired', 'contemplative']);
        break;
    }

    // Weather-based suggestions
    switch (context.weatherCondition?.toLowerCase()) {
      case 'clear':
      case 'sunny':
        suggestions.addAll(['happy', 'cheerful', 'upbeat']);
        break;
      case 'clouds':
      case 'cloudy':
        suggestions.addAll(['thoughtful', 'mellow', 'introspective']);
        break;
      case 'rain':
      case 'drizzle':
        suggestions.addAll(['cozy', 'melancholic', 'nostalgic']);
        break;
      case 'snow':
        suggestions.addAll(['serene', 'peaceful', 'contemplative']);
        break;
    }

    // Remove duplicates and return
    return suggestions.toSet().toList();
  }

  /// Get situation suggestions based on context
  List<String> getSituationSuggestions(ContextData context) {
    final suggestions = <String>[];
    
    // Time-based suggestions
    switch (context.timeOfDay) {
      case 'morning':
        suggestions.addAll(['commuting', 'getting ready', 'exercising']);
        break;
      case 'afternoon':
        suggestions.addAll(['working', 'lunch break', 'studying']);
        break;
      case 'evening':
        suggestions.addAll(['relaxing', 'cooking', 'unwinding']);
        break;
      case 'night':
        suggestions.addAll(['before sleep', 'resting', 'reflecting']);
        break;
    }

    // Motion-based suggestions
    switch (context.deviceMotion) {
      case 'walking':
        suggestions.addAll(['walking', 'exercising', 'commuting']);
        break;
      case 'vehicle':
        suggestions.addAll(['traveling', 'commuting', 'in transit']);
        break;
      case 'stationary':
        suggestions.addAll(['at home', 'at work', 'resting']);
        break;
    }

    // Remove duplicates and return
    return suggestions.toSet().toList();
  }

  /// Dispose resources
  void dispose() {
    _contextUpdateTimer?.cancel();
    _accelerometerSubscription?.cancel();
  }
}