import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ✅ added

class OnBoardScreen extends StatefulWidget {
  final String crowdLevel;
  final bool isLate;

  const OnBoardScreen({
    Key? key,
    required this.crowdLevel,
    required this.isLate,
  }) : super(key: key);

  @override
  State<OnBoardScreen> createState() => _OnBoardScreenState();
}

class _OnBoardScreenState extends State<OnBoardScreen> {
  // Existing state
  late String _selectedCrowdLevel;
  late String _selectedStatus;
  late int _selectedTime;

  // ✅ Route numbers & selection
  final List<String> _routeNumbers = ['138', '255', '117'];
  late String _selectedRouteNumber;

  // ✅ Halts by route
  final Map<String, List<String>> _haltsByRoute = const {
    '255': [
      'Kottawa',
      'Pinhena Junction',
      'Siddamulla',
      'Kudamaduwa',
      'Mawiththara',
      'Miriswatta / Miriswaththa Junction',
      'Piliyandala',
      'Suwarapola',
      'University of Moratuwa',
      'Katubedda / Katubedda Junction',
      'Rathmalana',
      'Mount Lavinia (Galkissa)',
    ],
    '138': [
      'Pettah',
      'Fort',
      'Lake House',
      'Slave Island',
      'Ibbanwala Junction',
      'Town Hall',
      'Thummulla',
      'Thimbirigasyaya Junction',
      'Havelock Town',
      'Kirillapone',
      'Nugegoda',
      'Delkanda',
      'Nawinna (Navinna)',
      'Maharagama',
    ],
    '117': [
      'Nugegoda',
      'Old Kesbewa Road',
      'Kattiya Junction',
      'Gamsabha Junction',
      'Pepiliyana Road',
      'Pepiliyana',
      'Bellanthota Junction',
      'Attidiya Road',
      'Ratmalana',
    ],
  };

  // ✅ Active halts list & selection (changes when route changes)
  late List<String> _busHalts;
  late String _selectedBusHalt;

  final List<String> _crowdLevels = ['Low', 'Medium', 'High'];
  final List<String> _statuses = ['On Time', 'Late'];
  final List<int> _times = List.generate(7, (index) => index * 5); // 0..30

  @override
  void initState() {
    super.initState();
    _selectedCrowdLevel = widget.crowdLevel;
    _selectedStatus = widget.isLate ? 'Late' : 'On Time';
    _selectedTime = 0;

    // Defaults for new dropdowns
    _selectedRouteNumber = _routeNumbers.first;
    _busHalts = List<String>.from(_haltsByRoute[_selectedRouteNumber]!);
    _selectedBusHalt = _busHalts.first;
  }

  Color _getCrowdColor(String level) {
    switch (level.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// ✅ Broadcast to all users (anonymous) by creating a Firestore alert
  Future<void> _broadcastUpdate() async {
    // derive a simple alert "type" for styling on AlertScreen
    final String type = _selectedStatus == 'Late'
        ? 'warning'
        : (_selectedTime > 0 ? 'delay' : 'info');

    final payload = {
      'route': _selectedRouteNumber,
      'halt': _selectedBusHalt,
      'crowd': _selectedCrowdLevel,
      'status': _selectedStatus,
      'etaMins': _selectedTime,
      'type': type, // 'delay' | 'warning' | 'info'
      'createdAt':
          FieldValue.serverTimestamp(), // server time so ordering is correct
      // No user identifiers stored -> anonymous
    };

    await FirebaseFirestore.instance.collection('alerts').add(payload);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bus Live Status"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),

            // Keep overflow-safe
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.directions_bus,
                    size: 60,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 20),

                  /// ✅ Route Number Dropdown (ABOVE crowd level)
                  Text(
                    "Select Route Number",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: _selectedRouteNumber,
                    isExpanded: true,
                    items: _routeNumbers
                        .map(
                          (route) => DropdownMenuItem(
                            value: route,
                            child: Text(route),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedRouteNumber = value;

                        // 🔁 Update the halts list based on the chosen route
                        _busHalts = List<String>.from(
                          _haltsByRoute[value] ?? const [],
                        );
                        // Reset to first halt to avoid stale selection
                        _selectedBusHalt = _busHalts.isNotEmpty
                            ? _busHalts.first
                            : '';
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  /// ✅ Crowd Level Dropdown (existing)
                  Text(
                    "Select Crowd Level",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: _selectedCrowdLevel,
                    isExpanded: true,
                    items: _crowdLevels
                        .map(
                          (level) => DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedCrowdLevel = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  /// ✅ Bus Halt Dropdown (changes with route)
                  Text("Select Bus Halt", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: _busHalts.contains(_selectedBusHalt)
                        ? _selectedBusHalt
                        : (_busHalts.isNotEmpty ? _busHalts.first : null),
                    isExpanded: true,
                    items: _busHalts
                        .map(
                          (halt) =>
                              DropdownMenuItem(value: halt, child: Text(halt)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedBusHalt = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  /// ✅ Status Dropdown (existing)
                  Text("Select Status", style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  DropdownButton<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: _statuses
                        .map(
                          (status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedStatus = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  /// ✅ Time Dropdown (0-30 mins) (existing)
                  Text(
                    "Select Time (mins)",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  DropdownButton<int>(
                    value: _selectedTime,
                    isExpanded: true,
                    items: _times
                        .map(
                          (time) => DropdownMenuItem(
                            value: time,
                            child: Text("$time mins"),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedTime = value);
                    },
                  ),
                  const SizedBox(height: 30),

                  /// ✅ Update Button (broadcast + snackbar)
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _broadcastUpdate(); // <-- 🔔 write alert (anonymous)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Updated: Route=$_selectedRouteNumber, "
                              "Halt=$_selectedBusHalt, "
                              "Crowd=$_selectedCrowdLevel, "
                              "Status=$_selectedStatus, "
                              "Time=$_selectedTime mins",
                            ),
                            backgroundColor: Colors.blue,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to broadcast update: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.update),
                    label: const Text("Update"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  /// ✅ Display Current Selection (expanded summary)
                  Text(
                    "Route: $_selectedRouteNumber",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Halt: $_selectedBusHalt",
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Crowd Level: $_selectedCrowdLevel",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _getCrowdColor(_selectedCrowdLevel),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Status: $_selectedStatus",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: _selectedStatus == "Late"
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
