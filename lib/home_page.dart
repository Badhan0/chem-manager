import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chem_manager/controllers/auth_controller.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chem_manager/services/google_signin_api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data_details.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:chem_manager/services/api_service.dart';
import 'dart:convert';
import 'notification_page.dart';
import 'find_user_page.dart';
import 'connected_user_details_page.dart';
import 'payment_gateway_setup_page.dart';

class NeumorphicDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final double? maxHeight;
  final double? maxWidth;

  const NeumorphicDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.maxHeight,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? MediaQuery.of(context).size.width * 0.9,
          maxHeight: maxHeight ?? MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: HomePage.backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              HomePage.darkShadow,
              HomePage.lightShadow,
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: HomePage.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: content,
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: actions,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  // Neumorphic Design Parameters
  static const Color backgroundColor = Color(0xFFE6EBF5); // Lighter blue-grey
  static const Color primaryColor = Color(0xFF3B82F6); // Bright Blue
  static const Color textColor = Color(0xFF475569); // Slate 600

  static final BoxShadow lightShadow = BoxShadow(
    color: Colors.white,
    offset: const Offset(-5, -5),
    blurRadius: 10,
    spreadRadius: 0,
  );

  static final BoxShadow darkShadow = BoxShadow(
    color: const Color(0xFFC1C9D8),
    offset: const Offset(5, 5),
    blurRadius: 10,
    spreadRadius: 0,
  );
}

class _HomePageState extends State<HomePage> {



  void _showProfileDialog(BuildContext context) async {
    final AuthController authController = AuthController();
    final result = await authController.fetchUserProfile();

    if (result['success']) {
      final data = result['data'];
      String displayName = data['name'] ?? 'User';
      String email = data['email'] ?? '';
      String initialLetter = email.isNotEmpty ? email[0].toUpperCase() : '';
      
      // Get photoURL from Database/Backend first, fallback to FirebaseAuth
      String photoUrl = data['photoURL'] ?? FirebaseAuth.instance.currentUser?.photoURL ?? '';

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => NeumorphicDialog(
          title: 'Profile',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: HomePage.backgroundColor,
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          initialLetter,
                          style: TextStyle(
                            fontSize: 22,
                            color: HomePage.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: HomePage.textColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                email,
                style: TextStyle(
                  fontSize: 12,
                  color: HomePage.textColor.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 10),
              _buildNeumorphicButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PaymentGatewaySetupPage()),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payment_rounded,
                        color: HomePage.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text('Manage payment option'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildNeumorphicButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfilePage()),
                  );
                  if (mounted) {
                    setState(() {});
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded,
                        color: HomePage.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    const Text('Edit Profile'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildNeumorphicButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close_rounded,
                        color: HomePage.textColor.withOpacity(0.6), size: 20),
                    const SizedBox(width: 8),
                    const Text('Close'),
                  ],
                ),
              ),
            ],
          ),
          actions: const [],
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.45, // Reduced height significantly
        ),
      );
    }
  }

  void _logout(BuildContext context) async {
    await AuthController().logout();

    if (!context.mounted) return;
    // Navigate to the login page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchConnectionsDetails(List<String> connectionIds) async {
    List<Map<String, dynamic>> details = [];
    for (String id in connectionIds) {
      try {
        final response = await ApiService.get('/users/$id');
        if (response.statusCode == 200) {
           details.add(jsonDecode(response.body));
        }
      } catch (e) {
        print('Error fetching user $id: $e');
      }
    }
    return details;
  }

  void _showNotifications(BuildContext context) async {
    // Navigate to the new Notification Screen
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );
    
    // Refresh the home page state when returning (to update connected users list if changed)
    if (mounted) {
      setState(() {});
    }

    /* 
    // OLD NOTIFICATION POPUP LOGIC (Commented out for future reference)
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) {
      _showErrorDialog(context, 'User not logged in locally.');
      return;
    }

    try {
      final response = await ApiService.get('/connections/requests?userId=$userId');

      List<Widget> notifications = [];

      if (response.statusCode == 200) {
        final List<dynamic> requests = jsonDecode(response.body);

        if (requests.isEmpty) {
          notifications.add(
            _buildNeumorphicContainer(
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No new connection requests',
                  style: TextStyle(color: HomePage.textColor.withOpacity(0.7)),
                ),
              ),
            ),
          );
        } else {
          for (var req in requests) {
             final sender = req['senderId']; // Populated sender object
             String senderName = sender['name'] ?? 'Unknown';
             String senderCategory = sender['category'] ?? 'Unknown';
             String identifier = senderCategory == 'Doctor'
                ? (sender['doctorAuthNumber'] ?? 'N/A')
                : (sender['gstinNumber'] ?? 'N/A');
             String requestId = req['_id'];

             notifications.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildNeumorphicContainer(
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.notifications_active, color: HomePage.primaryColor, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text('Request from $senderName', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 8),
                         Text('$senderCategory | ID: $identifier', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                _respondToRequest(context, requestId, 'rejected');
                                Navigator.pop(context); // Close dialog to refresh or handle state better
                              },
                              child: Text('Reject', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 10),
                            _buildNeumorphicButton(
                               child: Text('Accept', style: TextStyle(color: HomePage.primaryColor, fontWeight: FontWeight.bold)),
                               onPressed: () {
                                  _respondToRequest(context, requestId, 'accepted');
                                  Navigator.pop(context);
                               }
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        }
      } else {
         notifications.add(Text('Failed to load requests'));
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => NeumorphicDialog(
          title: 'Notifications',
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: notifications,
            ),
          ),
          actions: [
            _buildNeumorphicDialogButton(
              text: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );

    } catch (e) {
      if (!context.mounted) return;
      _showErrorDialog(context, 'Error fetching notifications: $e');
    }
    */
  }

  Future<void> _respondToRequest(BuildContext context, String requestId, String status) async {
      try {
        final response = await ApiService.patch('/connections/respond', {
          'requestId': requestId,
          'status': status
        });

        if (response.statusCode == 200) {
           _showSuccessDialog(context, 'Request $status successfully');
        } else {
           final error = jsonDecode(response.body);
           _showErrorDialog(context, error['message'] ?? 'Action failed');
        }
      } catch (e) {
         _showErrorDialog(context, 'Network Error: $e');
      }
  }

  // Deprecated usage replaced by _respondToRequest, keeping signature compatible if called elsewhere or removing if unused
  // Removing unused methods _acceptConnectionRequest and _addConnection as they are backend handled now.


  void _showFindUserDialog(BuildContext context) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check if profile is complete before allowing search
    bool isComplete = await _isProfileComplete();
    if (!isComplete) {
      if (!context.mounted) return;
      _showErrorDialog(context, 'Please complete your profile first.');
      return;
    }

    // New logic: Navigate to FindUserPage
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FindUserPage()),
    );
    
    // Refresh connection list when returning (if a request was sent)
    if (mounted) {
      setState(() {});
    }

    /* OLD LOGIC
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    String userCategory = userDoc['category'];
    bool isDoctor = userCategory == 'Doctor';
    String searchLabel =
        isDoctor ? 'Enter Organisation GSTIN' : 'Enter Doctor Auth No';
    String searchQuery = '';
    
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Map<String, dynamic>? searchResult;
        String? errorMessage;
        TextEditingController searchController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return NeumorphicDialog(
              title: 'Find ${isDoctor ? 'Organisation' : 'Doctor'}',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNeumorphicTextField(
                    controller: searchController,
                    label: searchLabel,
                    icon: Icons.search,
                    onChanged: (value) {
                      searchQuery = value;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (searchQuery.isEmpty && searchResult == null)
                     Column(
                      children: [
                        _buildNeumorphicButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            await _scanQRAndConnect(context, isDoctor);
                          },
                          child: Row(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                               Icon(Icons.qr_code_scanner, color: HomePage.primaryColor),
                               const SizedBox(width: 8),
                               const Text('Connect with QR'),
                             ]
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),

                  _buildNeumorphicButton(
                    onPressed: () async {
                      if (searchQuery.isEmpty) return;
                      FocusScope.of(context).unfocus();
                      setState(() {
                         searchResult = null;
                         errorMessage = null; 
                      });

                      Map<String, dynamic>? result; 
                      if (isDoctor) {
                         result = await _findOrganizationByGstin(context, searchQuery);
                      } else {
                         result = await _findDoctorByAuthNumber(context, searchQuery);
                      }

                      setState(() {
                        if (result != null) {
                           searchResult = result;
                        } else {
                           errorMessage = 'No user found with these details.';
                        }
                      });
                    },
                    child: const Text('Search'),
                  ),
                  const SizedBox(height: 20),
                  
                  if (errorMessage != null)
                     Text(errorMessage!, style: const TextStyle(color: Colors.red)),

                  if (searchResult != null)
                    _buildNeumorphicContainer(
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              searchResult!['name'] ?? 'Unknown',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: HomePage.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ListTile(
                              leading: Icon(Icons.category,
                                  color: HomePage.primaryColor),
                              title: Text(
                                'Category',
                                style: TextStyle(
                                    color: HomePage.textColor.withOpacity(0.7)),
                              ),
                              subtitle: Text(
                                searchResult!['category'] ?? '',
                                style: TextStyle(color: HomePage.textColor),
                              ),
                            ),
                            ListTile(
                              leading: Icon(Icons.badge,
                                  color: HomePage.primaryColor),
                              title: Text(
                                searchResult!['category'] == 'Doctor'
                                    ? 'Auth Number'
                                    : 'GSTIN',
                                style: TextStyle(
                                    color: HomePage.textColor.withOpacity(0.7)),
                              ),
                              subtitle: Text(
                                searchResult!['category'] == 'Doctor'
                                    ? (searchResult!['doctorAuthNumber'] ?? 'N/A')
                                    : (searchResult!['gstinNumber'] ?? 'N/A'),
                                style: TextStyle(color: HomePage.textColor),
                              ),
                            ),
                            const SizedBox(height: 15),
                            Center(
                              child: _buildNeumorphicButton(
                                onPressed: () {
                                  _sendConnectionRequest(context, searchResult!['_id']);
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Send Request',
                                  style: TextStyle(color: HomePage.primaryColor),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                ],
              ),
              actions: [
                _buildNeumorphicDialogButton(
                  text: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
     */
  }

  Future<Map<String, dynamic>?> _findOrganizationByGstin(
      BuildContext context, String gstin) async {
    try {
      final response = await ApiService.get('/users/search/gstin?gstin=$gstin');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Search failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Search Error: $e');
      _showErrorDialog(context, 'Error searching for organisation: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _findDoctorByAuthNumber(
      BuildContext context, String authNumber) async {
    try {
      final response = await ApiService.get('/users/search/auth?authNumber=$authNumber');
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Search failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Search Error: $e');
      _showErrorDialog(context, 'Search error: ${e.toString()}');
      return null;
    }
  }

  Future<void> _sendConnectionRequest(
      BuildContext context, String receiverId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final senderMongoId = prefs.getString('user_id');
      
      if (senderMongoId == null) {
         _showErrorDialog(context, 'User ID not found locally. Please re-login.');
         return;
      }

      final apiResponse = await ApiService.post('/connections/request', {
        'senderId': senderMongoId,
        'receiverId': receiverId,
      });

      if (apiResponse.statusCode == 201) {
        if (!context.mounted) return;
        _showSuccessDialog(context, 'Connection request sent successfully!');
      } else {
        final error = jsonDecode(apiResponse.body);
        _showErrorDialog(context, error['message'] ?? 'Failed to send request');
      }
    } catch (e) {
      _showErrorDialog(context, 'Failed to send connection request: $e');
    }
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showConnectionRequestDetails(
      BuildContext context, String requestId) async {
    DocumentSnapshot requestDoc = await FirebaseFirestore.instance
        .collection('connectionRequests')
        .doc(requestId)
        .get();

    if (!requestDoc.exists) {
      _showErrorDialog(context, 'Connection request not found.');
      return;
    }

    String senderId = requestDoc['senderId'];
    DocumentSnapshot senderDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(senderId)
        .get();

    if (!senderDoc.exists) {
      _showErrorDialog(context, 'Sender user details not found.');
      return;
    }

    String senderName = senderDoc['name'];
    String senderCategory = senderDoc['category'];
    String identifier = senderCategory == 'Doctor'
        ? senderDoc['doctorAuthNumber'] ?? 'N/A'
        : senderDoc['gstinNumber'] ?? 'N/A';

    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => NeumorphicDialog(
        title: 'Request Details',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNeumorphicContainer(
              ListTile(
                leading: Icon(Icons.person, color: HomePage.primaryColor),
                title: Text('Name',
                    style:
                        TextStyle(color: HomePage.textColor.withOpacity(0.7))),
                subtitle: Text(senderName,
                    style: TextStyle(color: HomePage.textColor)),
              ),
            ),
            const SizedBox(height: 15),
            _buildNeumorphicContainer(
              ListTile(
                leading: Icon(Icons.category, color: HomePage.primaryColor),
                title: Text('Category',
                    style:
                        TextStyle(color: HomePage.textColor.withOpacity(0.7))),
                subtitle: Text(senderCategory,
                    style: TextStyle(color: HomePage.textColor)),
              ),
            ),
            const SizedBox(height: 15),
            _buildNeumorphicContainer(
              ListTile(
                leading: Icon(Icons.badge, color: HomePage.primaryColor),
                title: Text(
                  senderCategory == 'Doctor' ? 'Auth Number' : 'GSTIN',
                  style: TextStyle(color: HomePage.textColor.withOpacity(0.7)),
                ),
                subtitle: Text(identifier,
                    style: TextStyle(color: HomePage.textColor)),
              ),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNeumorphicDialogButton(
                  text: 'Accept',
                  onPressed: () {
                    _respondToRequest(context, requestId, 'accepted');
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
                _buildNeumorphicDialogButton(
                  text: 'Reject',
                  onPressed: () {
                    _respondToRequest(context, requestId, 'rejected');
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          _buildNeumorphicDialogButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _requestStoragePermission(BuildContext context) async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      var result = await Permission.storage.request();
      if (result.isGranted) {
        // Permission granted, proceed with action
        _showSuccessDialog(context, 'Storage permission granted.');
      } else if (result.isPermanentlyDenied) {
        // The user has permanently denied the permission.
        // Open app settings to allow the user to enable it manually.
        openAppSettings();
        _showPermissionPermanentlyDeniedDialog(
            context, 'Storage permission permanently denied.');
      } else {
        // Permission denied, show a message.
        _showPermissionDeniedDialog(context, 'Storage permission denied.');
      }
    } else {
      // Permission already granted, proceed with action
      _showSuccessDialog(context, 'Storage permission already granted.');
    }
  }

  void _showPermissionDeniedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionPermanentlyDeniedDialog(
      BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Permanently Denied'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('Settings'),
              onPressed: () {
                openAppSettings();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Neumorphic Design Parameters
  // Getters to access static constants from HomePage
  Color get _backgroundColor => HomePage.backgroundColor;
  Color get _primaryColor => HomePage.primaryColor;
  Color get _textColor => HomePage.textColor;
  BoxShadow get _lightShadow => HomePage.lightShadow;
  BoxShadow get _darkShadow => HomePage.darkShadow;

  Widget _buildNeumorphicContainer(Widget child,
      {EdgeInsetsGeometry? padding}) {
    return Container(
      decoration: BoxDecoration(
        color: HomePage.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildNeumorphicButton(
      {required VoidCallback onPressed, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
      ),
      child: Material(
        color: HomePage.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicDialogButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
      ),
      child: Material(
        color: HomePage.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              text,
              style: TextStyle(
                color: HomePage.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: _textColor),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: _primaryColor),
          filled: true,
          fillColor: _backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Future<void> _showConnectedUserOptions(
    BuildContext context,
    Map<String, dynamic> userData,
    String userId, {
    required String currentUserCategory,
  }) async {
    // Navigate to new ConnectedUserDetailsPage screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConnectedUserDetailsPage(
          userData: userData,
          userId: userId,
          currentUserCategory: currentUserCategory,
        ),
      ),
    );

    // Refresh if needed (e.g. user deleted connection)
    if (result == true && mounted) {
      setState(() {});
    }

    /* OLD LOGIC
    showDialog(
      context: context,
      builder: (context) => NeumorphicDialog(
        title:
            '${userData['category'] == 'Doctor' ? 'Dr. ' : 'Org. '} ${userData['name']}',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person, color: HomePage.primaryColor),
              title: Text('Name',
                  style:
                      TextStyle(color: HomePage.textColor.withOpacity(0.7))),
              subtitle: Text(userData['name'] ?? 'N/A',
                  style: TextStyle(color: HomePage.textColor)),
            ),
            ListTile(
              leading: Icon(Icons.category, color: HomePage.primaryColor),
              title: Text('Category',
                  style:
                      TextStyle(color: HomePage.textColor.withOpacity(0.7))),
              subtitle: Text(userData['category'] ?? 'N/A',
                  style: TextStyle(color: HomePage.textColor)),
            ),
            if (currentUserCategory == 'Organisation' &&
                userData['category'] == 'Doctor')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: _buildNeumorphicButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAppointmentDaysDialog(context, userId);
                  },
                  child: Text(
                    'Set Appointment Days',
                    style: TextStyle(
                      color: HomePage.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text('Visit Statistics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: HomePage.primaryColor,
                    )),
                const SizedBox(height: 12),
                FutureBuilder<Map<String, int>>(
                  future: _getVisitCounts(userId, currentUserCategory),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _buildVisitGrid(snapshot.data ?? {});
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
        actions: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.25,
                child: _buildNeumorphicDialogButton(
                  text: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: _buildNeumorphicDialogButton(
                  text: 'Remove Connection',
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showConfirmationDialog(context, userId);
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
    */
  }

  Future<void> _removeConnection(
      BuildContext context, String targetUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      if (currentUserId == null) return;
      final response = await ApiService.delete('/connections?userId=$currentUserId&targetId=$targetUserId');

      if (response.statusCode == 200) {
        if (context.mounted) {
           _showSuccessDialog(context, 'Connection removed successfully');
        }
        if (mounted) {
           setState(() {}); // Refresh list
        }
      } else {
        if (context.mounted) {
           _showErrorDialog(context, 'Failed to remove connection');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Error removing connection: $e');
      }
    }
  }

  void _showConfirmationDialog(BuildContext context, String userIdToRemove) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content:
              const Text('Are you sure you want to remove this connection?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _removeConnection(context, userIdToRemove);
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String photoUrl = user?.photoURL ?? '';
    String initialLetter =
        user?.email?.isNotEmpty ?? false ? user!.email![0].toUpperCase() : '';

    return FutureBuilder<bool>(
      future: _isProfileComplete(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        bool isProfileSetup = snapshot.data ?? false;

        if (!isProfileSetup) {
           // Return a full Scaffold with Neumorphic design for the "Setup Profile" state
           return Scaffold(
             backgroundColor: _backgroundColor,
             body: Center(
               child: _buildNeumorphicContainer(
                 Padding(
                   padding: const EdgeInsets.all(30.0),
                   child: Column(
                     mainAxisSize: MainAxisSize.min,
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Container(
                         padding: EdgeInsets.all(20),
                         decoration: BoxDecoration(
                           color: _backgroundColor,
                           shape: BoxShape.circle,
                           boxShadow: [_darkShadow, _lightShadow]
                         ),
                         child: Icon(Icons.person_outline_rounded, size: 60, color: _primaryColor)
                       ),
                       const SizedBox(height: 30),
                       Text(
                         'Incomplete Profile',
                         style: TextStyle(
                           color: _textColor,
                           fontSize: 24,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       const SizedBox(height: 10),
                       Text(
                         'Please complete your profile details to access all features.',
                         textAlign: TextAlign.center,
                         style: TextStyle(
                           color: _textColor.withOpacity(0.7),
                           fontSize: 16,
                         ),
                       ),
                       const SizedBox(height: 40),
                       _buildNeumorphicButton(
                         onPressed: () async {
                           await Navigator.push(
                             context,
                             MaterialPageRoute(
                                 builder: (context) => const ProfilePage()),
                           );
                           if (mounted) {
                             setState(() {}); 
                           }
                         },
                         child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                           child: Text(
                             'Complete Verification',
                             style: TextStyle(
                                 color: _primaryColor, 
                                 fontWeight: FontWeight.bold,
                                 fontSize: 16
                             ),
                           ),
                         ),
                       ),
                     ],
                   ),
                 ),
               ),
             ),
           );
        }

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: _backgroundColor,
            elevation: 4,
            shadowColor: _backgroundColor.withOpacity(0.5),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _backgroundColor,
                  backgroundImage: AssetImage('assets/logo.png'),
                ),
                const SizedBox(width: 15),
                Text(
                  'Clini Sync',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            centerTitle: false,
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [_darkShadow, _lightShadow],
                  ),
                  child: Material(
                    color: _backgroundColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _showProfileDialog(context),
                      child: Container(
                        width: 48, // Match notification button size
                        height: 48, // Match notification button size
                        alignment: Alignment.center,
                        child: CircleAvatar(
                          radius: 20, // Increased from 15
                          backgroundColor: _backgroundColor,
                          backgroundImage: photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl.isEmpty
                              ? Text(
                                  initialLetter,
                                  style: TextStyle(
                                    fontSize: 24, // Increased from 16
                                    color: _primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [_darkShadow, _lightShadow],
                  ),
                  child: Material(
                    color: _backgroundColor,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: Icon(Icons.notifications, color: _primaryColor),
                      onPressed: () => _showNotifications(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: isProfileSetup
              ? FutureBuilder<Map<String, dynamic>>(
                  future: AuthController().fetchUserProfile(), // Use the new API
                  builder: (context, snapshot) {
                    // Show loading while fetching
                    if (snapshot.connectionState == ConnectionState.waiting) {
                       return const Center(child: CircularProgressIndicator());
                    }

                    // Check for errors or failed request
                    if (snapshot.hasError || !snapshot.hasData || !(snapshot.data!['success'] ?? false)) {
                       return Center(
                        child: Text(
                          'Error loading profile. Please try again.',
                          style: TextStyle(color: HomePage.textColor),
                        ),
                       );
                    }

                    // Extract actual user data from the API response
                    final userDataWrapper = snapshot.data!;
                    final userData = userDataWrapper['data'] as Map<String, dynamic>;
                    String category = userData['category'] ?? '';
                    String name = userData['name'] ?? 'User';
                    
                    // Also need to handle connections properly.
                    // The old code assumed userData['connections'] was a list of strings (document IDs)
                    // We need to ensure the backend returns this or we need to fetch it separately.
                    // The backend User model has `connections` array of ObjectIds.
                    final List<dynamic> connections = userData['connections'] ?? [];
                    final List<String> connectionIds = connections.map((c) => c.toString()).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildNeumorphicContainer(
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3, // Give more space to the name
                                  child: Text(
                                    category == 'Doctor'
                                        ? 'Dr. $name'
                                        : 'Org. $name',
                                    style: TextStyle(
                                      color: HomePage.textColor,
                                      fontSize: 20,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2, // Less space for the find section
                                  child: Column(
                                    children: [
                                      Text(
                                        category == 'Doctor'
                                            ? 'Find Organisation:'
                                            : 'Find Doctor:',
                                        style: TextStyle(
                                          color: HomePage.textColor
                                              .withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      const SizedBox(height: 8),
                                      _buildNeumorphicButton(
                                        onPressed: () =>
                                            _showFindUserDialog(context),
                                        child: const Text('Find'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Connected ${category == 'Doctor' ? 'Organisations' : 'Doctors'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        HomePage.textColor.withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: connectionIds.isEmpty 
                                    ? Center(
                                          child: _buildNeumorphicContainer(
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(16),
                                              child: Text(
                                                'No connections yet',
                                                style: TextStyle(
                                                  color: HomePage.textColor
                                                      .withOpacity(0.6),
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                    : FutureBuilder<List<Map<String, dynamic>>>(
                                      future: _fetchConnectionsDetails(connectionIds),
                                      builder: (context, connectedSnapshot) {
                                        if (connectedSnapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        if (connectedSnapshot.hasError) {
                                           return Center(child: Text('Error loading connections'));
                                        }
                                        if (!connectedSnapshot.hasData || connectedSnapshot.data!.isEmpty) {
                                          return Center(
                                            child: _buildNeumorphicContainer(
                                              Padding(
                                                padding: const EdgeInsets.all(16),
                                                child: Text(
                                                  'No connections yet',
                                                  style: TextStyle(
                                                    color: HomePage.textColor.withOpacity(0.6),
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }
                                        
                                        return ConstrainedBox(
                                          constraints: BoxConstraints(maxHeight: 200),
                                          child: ListView.builder(
                                            itemCount: connectedSnapshot.data!.length,
                                            itemBuilder: (context, index) {
                                              final connectedUserData = connectedSnapshot.data![index];
                                              final String connectedUserId = connectedUserData['_id'];
                                              
                                              return Padding(
                                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                                child: _buildNeumorphicContainer(
                                                  InkWell(
                                                    borderRadius: BorderRadius.circular(15),
                                                    onTap: () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => DataDetailsPage(
                                                            userName: connectedUserData['name'] ?? 'User',
                                                            userId: connectedUserId,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 48,
                                                            height: 48,
                                                            decoration: BoxDecoration(
                                                              color: HomePage.backgroundColor,
                                                              shape: BoxShape.circle,
                                                              boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
                                                            ),
                                                            child: Icon(
                                                              connectedUserData['category'] == 'Doctor' 
                                                                ? Icons.medical_services_rounded 
                                                                : Icons.business_rounded,
                                                              color: HomePage.primaryColor,
                                                              size: 24,
                                                            ),
                                                          ),
                                                          const SizedBox(width: 16),
                                                          Expanded(
                                                            child: Column(
                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                              children: [
                                                                Text(
                                                                  connectedUserData['name'] ?? 'N/A',
                                                                  style: TextStyle(
                                                                      color: HomePage.textColor,
                                                                      fontWeight: FontWeight.bold,
                                                                      fontSize: 16),
                                                                ),
                                                                const SizedBox(height: 4),
                                                                Text(
                                                                  connectedUserData['category'] == 'Doctor'
                                                                      ? (connectedUserData['specialization']?.isNotEmpty ?? false
                                                                          ? connectedUserData['specialization']
                                                                          : 'General Practitioner')
                                                                      : connectedUserData['category'] ?? 'N/A',
                                                                  style: TextStyle(
                                                                      color: HomePage.textColor.withOpacity(0.6),
                                                                      fontSize: 12,
                                                                      fontWeight: FontWeight.w500),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                          _buildNeumorphicButton(
                                                            onPressed: () => _showConnectedUserOptions(
                                                              context,
                                                              connectedUserData,
                                                              connectedUserId,
                                                              currentUserCategory: category,
                                                            ),
                                                            child: Icon(Icons.more_horiz, color: HomePage.primaryColor),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  })
              : Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildNeumorphicContainer(
                        const Text(
                          'Setup your profile first',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildNeumorphicButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfilePage()),
                        ),
                        child: Text(
                          'Go to Profile',
                          style: TextStyle(
                            color: HomePage.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Future<bool> _isProfileComplete() async {
    // Check via API first as that's where we save data
    try {
      final authController = AuthController();
      final result = await authController.fetchUserProfile();
      
      if (result['success']) {
        final data = result['data'];
        
        // Basic Fields
        if (_isFieldEmpty(data['category'])) return false;
        if (_isFieldEmpty(data['name'])) return false;
        if (_isFieldEmpty(data['aadharNumber'])) return false;

        String category = data['category'];

        // Role specific checks
        if (category == 'Doctor') {
            if (_isFieldEmpty(data['doctorAuthNumber'])) return false;
            if (_isFieldEmpty(data['specialization'])) return false;
        } else if (category == 'Organisation') {
            if (_isFieldEmpty(data['gstinNumber'])) return false;
        }
        return true;
      }
    } catch (e) {
      print('API Profile Check Failed: $e');
    }

    // Fallback to Firestore if API fails (e.g. connectivity)
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return false;

      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
      
      // Basic Fields
      if (_isFieldEmpty(data['category'])) return false;
      if (_isFieldEmpty(data['name'])) return false;
      if (_isFieldEmpty(data['aadharNumber'])) return false;

      String category = data['category'];

      // Role specific checks
      if (category == 'Doctor') {
          if (_isFieldEmpty(data['doctorAuthNumber'])) return false;
          if (_isFieldEmpty(data['specialization'])) return false;
      } else if (category == 'Organisation') {
          if (_isFieldEmpty(data['gstinNumber'])) return false;
      }

      return true;
    } catch (e) {
      print('Firestore Error checking profile: $e');
      return false; 
    }
  }

  Future<void> _scanQRAndConnect(BuildContext context, bool isDoctor) async {
    // Check camera permission status
    var status = await Permission.camera.status;

    // If not granted, request permission
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    // Handle final permission state
    if (!status.isGranted) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (context) => NeumorphicDialog(
          title: 'Permission Required',
          content: Text(
            'Camera access is required for QR scanning',
            style: TextStyle(color: HomePage.textColor),
          ),
          actions: [
            _buildNeumorphicDialogButton(
              text: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
            _buildNeumorphicDialogButton(
              text: 'Settings',
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
            ),
            _buildNeumorphicDialogButton(
              text: 'Try Again',
              onPressed: () async {
                Navigator.pop(context);
                await _scanQRAndConnect(context, isDoctor);
              },
            ),
          ],
        ),
      );
      return;
    }

    // Start QR scanning if permission granted
    String? scannedCode;
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Stack(
            children: [
              MobileScanner(
                onDetect: (BarcodeCapture barcode) {
                  scannedCode = barcode.barcodes.first.rawValue;
                  Navigator.pop(context);
                },
              ),
              // Camera view box overlay
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width * 0.7,
                      height: MediaQuery.of(context).size.width * 0.7,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: HomePage.primaryColor,
                          width: 4,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Corner borders
                          Positioned(
                            top: 0,
                            left: 0,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: HomePage.primaryColor,
                                    width: 4,
                                  ),
                                  top: BorderSide(
                                    color: HomePage.primaryColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: HomePage.primaryColor,
                                    width: 4,
                                  ),
                                  top: BorderSide(
                                    color: HomePage.primaryColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(
                                  left: BorderSide(
                                    color: HomePage.primaryColor,
                                    width: 4,
                                  ),
                                  bottom: BorderSide(
                                    color: HomePage.primaryColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(
                                    color: HomePage.primaryColor,
                                    width: 4,
                                  ),
                                  bottom: BorderSide(
                                    color: HomePage.primaryColor,
                                    width: 4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Align QR Code within the Frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Close button
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Handle scan results
    if (scannedCode == null || scannedCode!.isEmpty) {
      _showErrorDialog(context, 'No QR code detected');
      return;
    }

    try {
      Map<String, dynamic>? targetUser = isDoctor
          ? await _findOrganizationByGstin(context, scannedCode!)
          : await _findDoctorByAuthNumber(context, scannedCode!);

      if (targetUser == null) {
        _showErrorDialog(context, 'No user found with this QR code');
        return;
      }

      _sendConnectionRequest(context, targetUser['_id']);
      _showSuccessDialog(context, 'Connection request sent successfully!');
    } catch (e) {
      _showErrorDialog(context, 'Error processing QR code: $e');
    }
  }

  Future<void> _showAppointmentDaysDialog(
      BuildContext context, String doctorUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final orgUserId = prefs.getString('user_id');
    if (orgUserId == null) return;
    List<String> selectedDays = [];

    // Fetch existing days using User API
    try {
      final response = await ApiService.get('/users/$orgUserId');
      if (response.statusCode == 200) {
        final orgData = jsonDecode(response.body);
        final appointmentDays =
            Map<String, dynamic>.from(orgData['appointmentDays'] ?? {});
        selectedDays =
            List<String>.from(appointmentDays[doctorUserId] ?? []);
      }
    } catch (e) {
      print('Error fetching days: $e');
    }

    final daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return NeumorphicDialog(
            title: 'Set Visiting Days',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select visiting days:',
                    style: TextStyle(color: HomePage.textColor)),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: daysOfWeek.map((day) {
                    final isSelected = selectedDays.contains(day);
                    return _buildDayButton(
                      day: day,
                      isSelected: isSelected,
                      onPressed: () => setState(() {
                        isSelected
                            ? selectedDays.remove(day)
                            : selectedDays.add(day);
                      }),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              _buildNeumorphicDialogButton(
                text: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
              _buildNeumorphicDialogButton(
                text: 'Save',
                onPressed: () async {
                  try {
                    final response = await ApiService.patch(
                        '/users/appointment-days', {
                      'userId': orgUserId,
                      'doctorId': doctorUserId,
                      'days': selectedDays
                    });

                    if (response.statusCode == 200) {
                      Navigator.pop(context);
                      _showSuccessDialog(context, 'Days updated successfully');
                    } else {
                      // Handle error
                      print('Failed: ${response.body}');
                    }
                  } catch (e) {
                    print('Error saving days: $e');
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDayButton(
      {required String day,
      required bool isSelected,
      required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? HomePage.primaryColor : HomePage.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              day,
              style: TextStyle(
                color: isSelected ? Colors.white : HomePage.textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Map<String, int>> _getVisitCounts(
      String targetUserId, String currentUserCategory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      if (currentUserId == null) return {};

      final bool isDoctor = currentUserCategory == 'Doctor';
      
      String query = '/patients/stats?';
      if (isDoctor) {
          query += 'orgId=$targetUserId&doctorId=$currentUserId';
      } else {
          query += 'doctorId=$targetUserId&orgId=$currentUserId';
      }

      final response = await ApiService.get(query);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'weekly': (data['weekly'] as num?)?.toInt() ?? 0,
          'monthly': (data['monthly'] as num?)?.toInt() ?? 0,
          'yearly': (data['yearly'] as num?)?.toInt() ?? 0,
          'total': (data['total'] as num?)?.toInt() ?? 0
        };
      }
      return {'weekly': 0, 'monthly': 0, 'yearly': 0, 'total': 0};
    } catch (e) {
      print('Error getting visit counts: $e');
      return {'weekly': 0, 'monthly': 0, 'yearly': 0, 'total': 0};
    }
  }

  Widget _buildVisitGrid(Map<String, int> counts) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      children: [
        _buildStatCard('Weekly', counts['weekly'] ?? 0),
        _buildStatCard('Monthly', counts['monthly'] ?? 0),
        _buildStatCard('Yearly', counts['yearly'] ?? 0),
        _buildStatCard('Total', counts['total'] ?? 0),
      ],
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
    );
  }

  Widget _buildStatCard(String label, int count) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        decoration: BoxDecoration(
          color: HomePage.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: HomePage.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: HomePage.textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
  bool _isFieldEmpty(String? value) {
    if (value == null) return true;
    if (value.trim().isEmpty) return true;
    if (value.trim().toLowerCase() == 'undefined') return true;
    if (value.trim().toLowerCase() == 'null') return true;
    return false;
  }
}
