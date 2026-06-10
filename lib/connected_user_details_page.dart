import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chem_manager/services/api_service.dart';
import 'dart:convert';

class ConnectedUserDetailsPage extends StatefulWidget {
  final Map<String, dynamic> userData; // The other user's data
  final String userId; // The other user's ID
  final String currentUserCategory; // 'Doctor' or 'Organisation'

  const ConnectedUserDetailsPage({
    super.key,
    required this.userData,
    required this.userId,
    required this.currentUserCategory,
  });

  @override
  State<ConnectedUserDetailsPage> createState() =>
      _ConnectedUserDetailsPageState();
}

class _ConnectedUserDetailsPageState extends State<ConnectedUserDetailsPage> {
  // Neumorphic Design Parameters
  static const Color _backgroundColor = Color(0xFFE6EBF5);
  static const Color _primaryColor = Color(0xFF3B82F6);
  static const Color _textColor = Color(0xFF475569);
  
  static final BoxShadow _lightShadow = BoxShadow(
    color: Colors.white,
    offset: const Offset(-5, -5),
    blurRadius: 10,
    spreadRadius: 0,
  );

  static final BoxShadow _darkShadow = BoxShadow(
    color: const Color(0xFFC1C9D8),
    offset: const Offset(5, 5),
    blurRadius: 10,
    spreadRadius: 0,
  );

  Map<String, int> _visitCounts = {
    'weekly': 0,
    'monthly': 0,
    'yearly': 0,
    'total': 0
  };
  bool _isLoadingStats = true;

  // For Appointment Days (Only for Organisation -> Doctor)
  List<Map<String, dynamic>> _slots = [];
  bool _isLoadingDays = false;
  bool _isSavingDays = false;

  @override
  void initState() {
    super.initState();
    _fetchVisitStats();
    if (_canSetAppointmentDays()) {
      _fetchAppointmentDays();
    }
  }

  bool _canSetAppointmentDays() {
    return widget.currentUserCategory == 'Organisation' &&
        widget.userData['category'] == 'Doctor';
  }

  Future<void> _fetchVisitStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      if (currentUserId == null) return;

      final bool isDoctor = widget.currentUserCategory == 'Doctor';
      String query = '/patients/stats?';
      
      // If I am Doctor, target is Org.
      // If I am Org, target is Doctor.
      if (isDoctor) {
        query += 'orgId=${widget.userId}&doctorId=$currentUserId';
      } else {
        query += 'doctorId=${widget.userId}&orgId=$currentUserId';
      }

      final response = await ApiService.get(query);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _visitCounts = {
            'weekly': (data['weekly'] as num?)?.toInt() ?? 0,
            'monthly': (data['monthly'] as num?)?.toInt() ?? 0,
            'yearly': (data['yearly'] as num?)?.toInt() ?? 0,
            'total': (data['total'] as num?)?.toInt() ?? 0
          };
        });
      }
    } catch (e) {
      print('Error getting visit counts: $e');
    } finally {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchAppointmentDays() async {
    setState(() => _isLoadingDays = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id'); // Org ID
      
      if (currentUserId == null) return;

      final response = await ApiService.get('/users/$currentUserId');
      if (response.statusCode == 200) {
        final orgData = jsonDecode(response.body);
        final appointmentDays =
            Map<String, dynamic>.from(orgData['appointmentDays'] ?? {});
        
        final rawDays = appointmentDays[widget.userId];
        List<Map<String, dynamic>> loadedSlots = [];
        if (rawDays is List) {
          for (var item in rawDays) {
            if (item is Map) {
              loadedSlots.add(Map<String, dynamic>.from(item));
            } else if (item is String) {
              loadedSlots.add({
                'day': item,
                'startTime': '09:00 AM',
                'endTime': '05:00 PM',
                'maxPatients': 20,
              });
            }
          }
        }
        
        if (mounted) {
           setState(() {
              _slots = loadedSlots;
           });
        }
      }
    } catch (e) {
      print('Error fetching days: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDays = false);
    }
  }

  Future<void> _saveAppointmentDays() async {
    setState(() => _isSavingDays = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      if (currentUserId == null) return;

      final response = await ApiService.patch('/users/appointment-days', {
         'userId': currentUserId,
         'doctorId': widget.userId,
         'days': _slots
      });

      if (response.statusCode == 200) {
        _showSuccessDialog('Visiting schedule updated successfully');
      } else {
        _showErrorDialog('Failed to update visiting schedule');
      }
    } catch (e) {
      _showErrorDialog('Error saving visiting schedule: $e');
    } finally {
      if (mounted) setState(() => _isSavingDays = false);
    }
  }

  void _showAddSlotDialog() {
    String selectedDay = 'Monday';
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);
    final maxPatientsController = TextEditingController(text: '15');

    final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: _backgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              'Add Visiting Slot',
              style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Day:', style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    dropdownColor: _backgroundColor,
                    style: TextStyle(color: _textColor, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: daysOfWeek.map((day) => DropdownMenuItem(value: day, child: Text(day))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedDay = val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Start Time:', style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: startTime);
                      if (picked != null) {
                        setDialogState(() => startTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(startTime.format(context), style: TextStyle(color: _textColor, fontSize: 16)),
                          Icon(Icons.access_time, color: _primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('End Time:', style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: endTime);
                      if (picked != null) {
                        setDialogState(() => endTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(endTime.format(context), style: TextStyle(color: _textColor, fontSize: 16)),
                          Icon(Icons.access_time, color: _primaryColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Max Patients:', style: TextStyle(color: _textColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: maxPatientsController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: _textColor, fontSize: 16),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      hintText: 'e.g. 15',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: _textColor.withOpacity(0.7))),
              ),
              ElevatedButton(
                onPressed: () {
                  final patients = int.tryParse(maxPatientsController.text);
                  if (patients == null || patients <= 0) {
                    _showErrorDialog('Please enter a valid patient count');
                    return;
                  }
                  
                  // Add slot to list
                  setState(() {
                    _slots.add({
                      'day': selectedDay,
                      'startTime': startTime.format(context),
                      'endTime': endTime.format(context),
                      'maxPatients': patients,
                    });
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: _primaryColor),
                child: const Text('Add', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _removeConnection() async {
    // Show confirmation first
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Connection?', style: TextStyle(color: Colors.red)),
        content: Text('Are you sure you want to remove ${widget.userData['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Remove', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      if (currentUserId == null) return;

      final response = await ApiService.delete('/connections?userId=$currentUserId&targetId=${widget.userId}');
      if (response.statusCode == 200) {
        if (mounted) {
            // Pop back to home with result true to indicate refresh needed
            Navigator.pop(context, true); 
        }
      } else {
        _showErrorDialog('Failed to remove connection');
      }
    } catch (e) {
      _showErrorDialog('Error: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success', style: TextStyle(color: _primaryColor)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error', style: TextStyle(color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('OK')),
        ],
      ),
    );
  }

  // Neumorphic Widgets
  Widget _buildNeumorphicContainer(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: child,
    );
  }

  Widget _buildNeumorphicButton({
      required Widget child, 
      required VoidCallback onPressed, 
      Color? color
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
        color: color ?? _backgroundColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count) {
    return _buildNeumorphicContainer(
       Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Text(
               count.toString(),
               style: TextStyle(
                 fontSize: 24,
                 fontWeight: FontWeight.w900,
                 color: _primaryColor,
               ),
             ),
             const SizedBox(height: 5),
             Text(
               label,
               style: TextStyle(
                 fontSize: 14,
                 color: _textColor.withOpacity(0.8),
                 fontWeight: FontWeight.w500
               ),
             ),
           ],
         ),
       )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: _primaryColor),
          onPressed: () => Navigator.pop(context, false), // Return false (no refresh needed) if just back
        ),
        title: Text(
           'User Details',
           style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Profile
            _buildNeumorphicContainer(
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(15),
                      decoration: BoxDecoration(
                         shape: BoxShape.circle,
                         color: _backgroundColor,
                         boxShadow: [_darkShadow, _lightShadow]
                      ),
                      child: Icon(
                        widget.userData['category'] == 'Doctor' 
                            ? Icons.medical_services_rounded 
                            : Icons.business_rounded, 
                        size: 50, 
                        color: _primaryColor
                      )
                    ),
                    SizedBox(height: 15),
                    Text(
                      widget.userData['name'] ?? 'Unknown',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textColor),
                    ),
                    SizedBox(height: 5),
                    Text(
                      widget.userData['category'] ?? 'N/A',
                      style: TextStyle(fontSize: 16, color: _textColor.withOpacity(0.6)),
                    ),
                    SizedBox(height: 5),
                    if (widget.userData['category'] == 'Doctor')
                        Text(widget.userData['specialization'] ?? '', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            ),
            
            SizedBox(height: 30),
            
            // Statistics Section
            Align(alignment: Alignment.centerLeft, child: Text('Visit Statistics', style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold))),
            SizedBox(height: 15),
            if (_isLoadingStats)
               Center(child: CircularProgressIndicator(color: _primaryColor))
            else
               GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.3,
                  children: [
                     _buildStatCard('Weekly', _visitCounts['weekly'] ?? 0),
                     _buildStatCard('Monthly', _visitCounts['monthly'] ?? 0),
                     _buildStatCard('Yearly', _visitCounts['yearly'] ?? 0),
                     _buildStatCard('Total', _visitCounts['total'] ?? 0),
                  ],
               ),

            SizedBox(height: 30),

            // Appointment Days (Conditional)
            if (_canSetAppointmentDays()) ...[
                Align(alignment: Alignment.centerLeft, child: Text('Set Visiting Days & Slots', style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold))),
                SizedBox(height: 15),
                if (_isLoadingDays)
                   Center(child: CircularProgressIndicator(color: _primaryColor))
                else
                   Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                         if (_slots.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'No visiting slots configured yet.',
                                  style: TextStyle(color: _textColor.withOpacity(0.6), fontSize: 15, fontStyle: FontStyle.italic),
                                ),
                              ),
                            )
                         else
                            ListView.builder(
                               shrinkWrap: true,
                               physics: NeverScrollableScrollPhysics(),
                               itemCount: _slots.length,
                               itemBuilder: (context, index) {
                                  final slot = _slots[index];
                                  return Padding(
                                     padding: const EdgeInsets.only(bottom: 12),
                                     child: _buildNeumorphicContainer(
                                        Padding(
                                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                           child: Row(
                                              children: [
                                                 Icon(Icons.calendar_month_rounded, color: _primaryColor),
                                                 const SizedBox(width: 15),
                                                 Expanded(
                                                    child: Column(
                                                       crossAxisAlignment: CrossAxisAlignment.start,
                                                       children: [
                                                          Text(
                                                             slot['day'] ?? 'Unknown Day',
                                                             style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Row(
                                                             children: [
                                                                Icon(Icons.access_time_rounded, color: _textColor.withOpacity(0.6), size: 14),
                                                                const SizedBox(width: 5),
                                                                Text(
                                                                   '${slot['startTime'] ?? 'N/A'} - ${slot['endTime'] ?? 'N/A'}',
                                                                   style: TextStyle(color: _textColor.withOpacity(0.8), fontSize: 13),
                                                                ),
                                                                const SizedBox(width: 15),
                                                                Icon(Icons.people_alt_rounded, color: _textColor.withOpacity(0.6), size: 14),
                                                                const SizedBox(width: 5),
                                                                Text(
                                                                   'Max: ${slot['maxPatients'] ?? 'N/A'}',
                                                                   style: TextStyle(color: _textColor.withOpacity(0.8), fontSize: 13),
                                                                ),
                                                             ],
                                                          )
                                                       ],
                                                    ),
                                                 ),
                                                 IconButton(
                                                    icon: Icon(Icons.delete_rounded, color: Colors.red.shade400),
                                                    onPressed: () {
                                                       setState(() {
                                                          _slots.removeAt(index);
                                                       });
                                                    },
                                                 )
                                              ],
                                           ),
                                        ),
                                     ),
                                  );
                               },
                            ),
                         const SizedBox(height: 15),
                         Row(
                           children: [
                             Expanded(
                               child: _buildNeumorphicButton(
                                  onPressed: _showAddSlotDialog,
                                  child: Row(
                                     mainAxisAlignment: MainAxisAlignment.center,
                                     children: [
                                        Icon(Icons.add_rounded, color: _primaryColor),
                                        const SizedBox(width: 8),
                                        Text('Add Slot', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 16))
                                     ],
                                  )
                               ),
                             ),
                             const SizedBox(width: 15),
                             Expanded(
                               child: _buildNeumorphicButton(
                                  onPressed: _saveAppointmentDays,
                                  color: _primaryColor,
                                  child: _isSavingDays 
                                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('Save Schedule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))
                               ),
                             ),
                           ],
                         ),
                      ],
                    ),
                SizedBox(height: 30),
            ],

            // Remove Connection Button
            _buildNeumorphicButton(
               onPressed: _removeConnection,
               child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.person_remove_rounded, color: Colors.red.shade400),
                     SizedBox(width: 10),
                     Text('Remove Connection', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold, fontSize: 16))
                  ],
               )
            ),
            SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
