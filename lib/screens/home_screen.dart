import 'package:flutter/material.dart';
import 'dart:async';
import '../models/person.dart';
import '../services/api_service.dart';
import '../widgets/person_card.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Person> _people = [];
  bool _isLoading = true;
  bool _isConnected = false;
  String _errorMessage = '';
  Timer? _refreshTimer;
  StreamSubscription<List<Person>>? _dataSubscription;
  
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkConnection();
    _loadInitialData();
    _startRealTimeUpdates();
  }

  void _initializeAnimations() {
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    _fabAnimationController.forward();
  }

  Future<void> _checkConnection() async {
    try {
      final connected = await ApiService.checkConnection();
      setState(() {
        _isConnected = connected;
        if (!connected) {
          _errorMessage = 'Cannot connect to Raspberry Pi. Check your network connection.';
        }
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _errorMessage = 'Connection error: ${e.toString()}';
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      final people = await ApiService.getAllPeople();
      setState(() {
        _people = _sortPeopleByCondition(people);
        _isLoading = false;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  void _startRealTimeUpdates() {
    _dataSubscription = ApiService.getRealTimeData().listen(
      (people) {
        setState(() {
          _people = _sortPeopleByCondition(people);
          _isConnected = true;
          _errorMessage = '';
        });
      },
      onError: (error) {
        setState(() {
          _isConnected = false;
          _errorMessage = 'Real-time update error: ${error.toString()}';
        });
      },
    );
  }

  List<Person> _sortPeopleByCondition(List<Person> people) {
    people.sort((a, b) => a.condition.priority.compareTo(b.condition.priority));
    return people;
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    await _checkConnection();
    await _loadInitialData();
  }

  void _showAddPersonDialog() {
    String newPersonName = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (value) => newPersonName = value,
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter person\'s name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPersonName.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  await _addPerson(newPersonName.trim());
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addPerson(String name) async {
    try {
      await ApiService.addPerson(name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding person: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _dataSubscription?.cancel();
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.monitor_heart, size: 28),
            SizedBox(width: 8),
            Text('Fitness Tracker'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  _isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          onPressed: _showAddPersonDialog,
          icon: Icon(Icons.person_add),
          label: Text('Add Person'),
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _people.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading fitness data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty && _people.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: 16),
            Text(
              'Connection Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshData,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_people.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'No People Added Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add people to start tracking their fitness data',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddPersonDialog,
              icon: Icon(Icons.person_add),
              label: Text('Add First Person'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary header
        Container(
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[600]!, Colors.blue[400]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total People', '${_people.length}', Icons.people),
              _buildSummaryItem(
                'Critical Cases', 
                '${_people.where((p) => p.condition == PhysicalCondition.critical).length}',
                Icons.emergency,
              ),
              _buildSummaryItem(
                'Last Update', 
                _people.isNotEmpty ? _formatLastUpdate() : 'Never',
                Icons.update,
              ),
            ],
          ),
        ),
        
        // People list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: _people.length,
              itemBuilder: (context, index) {
                return PersonCard(
                  person: _people[index],
                  onRefresh: _refreshData,
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatLastUpdate() {
    if (_people.isEmpty) return 'Never';
    
    final latestUpdate = _people
        .map((p) => p.timestamp)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    
    final difference = DateTime.now().difference(latestUpdate);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }
}