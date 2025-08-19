import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/person.dart';

class ApiService {
  // Replace with your FastAPI backend URL
  static const String baseUrl = 'http://192.168.1.100:8000'; // Update this to your Pi's IP
  
  static const Duration timeout = Duration(seconds: 10);

  // Get all people's fitness data
  static Future<List<Person>> getAllPeople() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/people'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Person.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load people data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get specific person's data
  static Future<Person> getPerson(String personId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/people/$personId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Person.fromJson(data);
      } else {
        throw Exception('Failed to load person data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Add a new person
  static Future<Person> addPerson(String name) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/people'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name}),
      ).timeout(timeout);

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Person.fromJson(data);
      } else {
        throw Exception('Failed to add person: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Start measurement for a person
  static Future<void> startMeasurement(String personId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/people/$personId/measure'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to start measurement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get real-time data stream (if your backend supports WebSocket or SSE)
  static Stream<List<Person>> getRealTimeData() async* {
    while (true) {
      try {
        final people = await getAllPeople();
        yield people;
        await Future.delayed(Duration(seconds: 2)); // Poll every 2 seconds
      } catch (e) {
        // Handle error and continue streaming
        print('Error in real-time data: $e');
        await Future.delayed(Duration(seconds: 5)); // Wait longer on error
      }
    }
  }

  // Check server connectivity
  static Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}