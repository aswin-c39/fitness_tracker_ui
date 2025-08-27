import 'dart:math';
import '../models/person.dart';

class MockApiService {
  // Mock database
  static List<Person> _mockPeople = [
    Person(
      id: '1',
      name: 'Alice Johnson',
      heartRate: 72,
      spo2: 98.5,
      timestamp: DateTime.now().subtract(Duration(minutes: 2)),
      condition: PhysicalConditionExtension.fromValues(72, 98.5),
    ),
    Person(
      id: '2',
      name: 'Bob Wilson',
      heartRate: 125,
      spo2: 89.0,
      timestamp: DateTime.now().subtract(Duration(minutes: 1)),
      condition: PhysicalConditionExtension.fromValues(125, 89.0),
    ),
    Person(
      id: '3',
      name: 'Carol Davis',
      heartRate: 88,
      spo2: 96.2,
      timestamp: DateTime.now().subtract(Duration(minutes: 5)),
      condition: PhysicalConditionExtension.fromValues(88, 96.2),
    ),
    Person(
      id: '4',
      name: 'David Brown',
      heartRate: 45,
      spo2: 97.8,
      timestamp: DateTime.now().subtract(Duration(minutes: 3)),
      condition: PhysicalConditionExtension.fromValues(45, 97.8),
    ),
    Person(
      id: '5',
      name: 'Emma Taylor',
      heartRate: 78,
      spo2: 99.1,
      timestamp: DateTime.now().subtract(Duration(seconds: 30)),
      condition: PhysicalConditionExtension.fromValues(78, 99.1),
    ),
  ];

  static int _nextId = 6;

  // Simulate network delay
  static Future<void> _simulateDelay() async {
    await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
  }

  // Get all people
  static Future<List<Person>> getAllPeople() async {
    await _simulateDelay();
    
    // Simulate random data changes (like real sensor readings)
    _updateRandomData();
    
    return List.from(_mockPeople);
  }

  // Get specific person
  static Future<Person> getPerson(String personId) async {
    await _simulateDelay();
    
    final person = _mockPeople.firstWhere(
      (p) => p.id == personId,
      orElse: () => throw Exception('Person not found'),
    );
    
    return person;
  }

  // Add new person
  static Future<Person> addPerson(String name) async {
    await _simulateDelay();
    
    final newPerson = Person(
      id: _nextId.toString(),
      name: name,
      heartRate: 60 + Random().nextInt(40), // Random heart rate 60-100
      spo2: 95.0 + Random().nextDouble() * 5.0, // Random SpO2 95-100%
      timestamp: DateTime.now(),
      condition: PhysicalCondition.excellent, // Will be calculated
    );
    
    // Recalculate condition based on values
    final updatedPerson = Person(
      id: newPerson.id,
      name: newPerson.name,
      heartRate: newPerson.heartRate,
      spo2: newPerson.spo2,
      timestamp: newPerson.timestamp,
      condition: PhysicalConditionExtension.fromValues(newPerson.heartRate, newPerson.spo2),
    );
    
    _mockPeople.add(updatedPerson);
    _nextId++;
    
    return updatedPerson;
  }

  // Start measurement (simulates taking new readings)
  static Future<void> startMeasurement(String personId) async {
    await _simulateDelay();
    
    final index = _mockPeople.indexWhere((p) => p.id == personId);
    if (index == -1) throw Exception('Person not found');
    
    final person = _mockPeople[index];
    
    // Generate new realistic readings
    final newHeartRate = _generateRealisticHeartRate(person.heartRate);
    final newSpo2 = _generateRealisticSpO2(person.spo2);
    
    // Update person with new data
    _mockPeople[index] = Person(
      id: person.id,
      name: person.name,
      heartRate: newHeartRate,
      spo2: newSpo2,
      timestamp: DateTime.now(),
      condition: PhysicalConditionExtension.fromValues(newHeartRate, newSpo2),
    );
  }

  // Check connection (always returns true for mock)
  static Future<bool> checkConnection() async {
    await Future.delayed(Duration(milliseconds: 200));
    return true;
  }

  // Simulate real-time data updates
  static Stream<List<Person>> getRealTimeData() async* {
    while (true) {
      try {
        final people = await getAllPeople();
        yield people;
        await Future.delayed(Duration(seconds: 3)); // Update every 3 seconds
      } catch (e) {
        print('Mock data stream error: $e');
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }

  // Helper method to update random data (simulates sensor changes)
  static void _updateRandomData() {
    final random = Random();
    
    // Randomly update 1-2 people each time
    final peopleToUpdate = random.nextInt(3);
    
    for (int i = 0; i < peopleToUpdate; i++) {
      if (_mockPeople.isEmpty) break;
      
      final index = random.nextInt(_mockPeople.length);
      final person = _mockPeople[index];
      
      final newHeartRate = _generateRealisticHeartRate(person.heartRate);
      final newSpo2 = _generateRealisticSpO2(person.spo2);
      
      _mockPeople[index] = Person(
        id: person.id,
        name: person.name,
        heartRate: newHeartRate,
        spo2: newSpo2,
        timestamp: DateTime.now(),
        condition: PhysicalConditionExtension.fromValues(newHeartRate, newSpo2),
      );
    }
  }

  // Generate realistic heart rate changes
  static int _generateRealisticHeartRate(int currentHR) {
    final random = Random();
    // Small variations (-5 to +5 BPM)
    final change = random.nextInt(11) - 5;
    final newHR = currentHR + change;
    
    // Keep within reasonable bounds
    return newHR.clamp(40, 150);
  }

  // Generate realistic SpO2 changes
  static double _generateRealisticSpO2(double currentSpO2) {
    final random = Random();
    // Small variations (-1.0 to +1.0%)
    final change = (random.nextDouble() * 2.0) - 1.0;
    final newSpO2 = currentSpO2 + change;
    
    // Keep within reasonable bounds
    return double.parse((newSpO2.clamp(85.0, 100.0)).toStringAsFixed(1));
  }
}