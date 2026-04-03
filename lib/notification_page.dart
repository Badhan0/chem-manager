import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chem_manager/services/api_service.dart';
import 'dart:convert';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Neumorphic Design Parameters (Consistent with App Theme)
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

  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) {
      if (mounted) _showErrorDialog('User not logged in locally.');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await ApiService.get('/connections/requests?userId=$userId');

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _notifications = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) _showErrorDialog('Failed to load requests');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) _showErrorDialog('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _respondToRequest(String requestId, String status) async {
    try {
      final response = await ApiService.patch('/connections/respond', {
        'requestId': requestId,
        'status': status
      });

      if (response.statusCode == 200) {
        _showSuccessDialog('Request $status successfully');
        _fetchNotifications(); // Refresh list
      } else {
        final error = jsonDecode(response.body);
        _showErrorDialog(error['message'] ?? 'Action failed');
      }
    } catch (e) {
      _showErrorDialog('Network Error: $e');
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

  Widget _buildNeumorphicButton({required Widget child, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), 
        boxShadow: [_darkShadow, _lightShadow],
        color: _backgroundColor,
      ),
       child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: child,
          ),
        ),
      ),
    );
  }
  
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: _primaryColor),
            onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            'Notifications',
            style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
            ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                        _buildNeumorphicContainer(
                            Padding(
                                padding: EdgeInsets.all(20),
                                child: Icon(Icons.notifications_none_rounded, size: 60, color: _textColor.withOpacity(0.3))
                            )
                        ),
                        SizedBox(height: 25),
                        Text('No notifications', style: TextStyle(color: _textColor.withOpacity(0.5), fontSize: 18, fontWeight: FontWeight.w500))
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(25),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                     final req = _notifications[index];
                     final sender = req['senderId'];
                     String senderName = sender['name'] ?? 'Unknown';
                     String senderCategory = sender['category'] ?? 'Unknown';
                     String identifier = senderCategory == 'Doctor'
                        ? (sender['doctorAuthNumber'] ?? 'N/A')
                        : (sender['gstinNumber'] ?? 'N/A');
                     String requestId = req['_id'];
                     
                     return Padding(
                        padding: const EdgeInsets.only(bottom: 25.0),
                        child: _buildNeumorphicContainer(
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _backgroundColor,
                                            boxShadow: [_darkShadow, _lightShadow]
                                        ),
                                        child: Icon(Icons.person_add_rounded, color: _primaryColor, size: 24)
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                                Text('Request from $senderName', style: TextStyle(fontWeight: FontWeight.bold, color: _textColor, fontSize: 16)),
                                                SizedBox(height: 4),
                                                Text('$senderCategory', style: TextStyle(color: _textColor.withOpacity(0.6), fontSize: 12)),
                                            ]
                                        )
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                    decoration: BoxDecoration(
                                         color: _backgroundColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white.withOpacity(0.5)), // subtle inset hint
                                        boxShadow: [
                                             BoxShadow(color: Colors.white, offset: Offset(1,1), blurRadius: 2), // subtle light
                                        ]
                                    ),
                                    child: Text('ID: $identifier', style: TextStyle(color: _textColor, fontWeight: FontWeight.w500)),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _respondToRequest(requestId, 'rejected'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)
                                      ),
                                      child: Text('Reject', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(width: 10),
                                    _buildNeumorphicButton(
                                       child: Text('Accept', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold)),
                                       onPressed: () => _respondToRequest(requestId, 'accepted')
                                    )
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                  },
                ),
    );
  }
}
