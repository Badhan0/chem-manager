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
  List<String> _selectedDays = [];
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
        
        if (mounted) {
           setState(() {
              _selectedDays = List<String>.from(appointmentDays[widget.userId] ?? []);
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
         'days': _selectedDays
      });

      if (response.statusCode == 200) {
        _showSuccessDialog('Days updated successfully');
      } else {
        _showErrorDialog('Failed to update days');
      }
    } catch (e) {
      _showErrorDialog('Error saving days: $e');
    } finally {
      if (mounted) setState(() => _isSavingDays = false);
    }
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
    final daysOfWeek = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

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
                Align(alignment: Alignment.centerLeft, child: Text('Set Visiting Days', style: TextStyle(color: _textColor, fontSize: 18, fontWeight: FontWeight.bold))),
                SizedBox(height: 15),
                if (_isLoadingDays)
                   Center(child: CircularProgressIndicator(color: _primaryColor))
                else
                   Column(
                     children: [
                        Wrap(
                           spacing: 12,
                           runSpacing: 12,
                           children: daysOfWeek.map((day) {
                              final isSelected = _selectedDays.contains(day);
                              return GestureDetector(
                                 onTap: () {
                                    setState(() {
                                       if (isSelected) {
                                          _selectedDays.remove(day);
                                       } else {
                                          _selectedDays.add(day);
                                       }
                                    });
                                 },
                                 child: Container(
                                     padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                     decoration: BoxDecoration(
                                        color: isSelected ? _primaryColor : _backgroundColor,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: isSelected 
                                            ? [] // Pressed effect could be inset, but standard neumorphic often removes shadow or inverts
                                            : [_darkShadow, _lightShadow]
                                     ),
                                     child: Text(
                                         day, 
                                         style: TextStyle(
                                            color: isSelected ? Colors.white : _textColor,
                                            fontWeight: FontWeight.bold
                                         )
                                     ),
                                 ),
                              );
                           }).toList(),
                        ),
                        SizedBox(height: 20),
                        _buildNeumorphicButton(
                           onPressed: _saveAppointmentDays,
                           child: _isSavingDays 
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: _primaryColor, strokeWidth: 2))
                              : Text('Update Days', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 16))
                        )
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
