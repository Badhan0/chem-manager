import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chem_manager/controllers/auth_controller.dart';
import 'package:chem_manager/services/api_service.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FindUserPage extends StatefulWidget {
  const FindUserPage({super.key});

  @override
  _FindUserPageState createState() => _FindUserPageState();
}

class _FindUserPageState extends State<FindUserPage> {
  // Neumorphic Design Parameters (Consistent with App Theme)
  static const Color _backgroundColor = Color(0xFFE6EBF5);
  static const Color _primaryColor = Color(0xFF3B82F6);
  static const Color _textColor = Color(0xFF475569);
  static const Color _labelColor = Color(0xFF94A3B8);

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

  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? _searchResult;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isDoctor = false;
  String _searchLabel = '';

  @override
  void initState() {
    super.initState();
    _initializeUserCategory();
  }

  Future<void> _initializeUserCategory() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (mounted) {
      setState(() {
         String userCategory = userDoc['category'];
         _isDoctor = userCategory == 'Doctor';
         _searchLabel = _isDoctor ? 'Enter Organisation GSTIN' : 'Enter Doctor Auth No';
      });
    }
  }

  Future<Map<String, dynamic>?> _findOrganizationByGstin(String gstin) async {
    try {
      final response = await ApiService.get('/users/search/gstin?gstin=$gstin');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _findDoctorByAuthNumber(String authNumber) async {
    try {
      final response = await ApiService.get('/users/search/auth?authNumber=$authNumber');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _searchResult = null;
      _errorMessage = null;
    });

    FocusScope.of(context).unfocus();

    Map<String, dynamic>? result;
    if (_isDoctor) {
      result = await _findOrganizationByGstin(_searchController.text);
    } else {
      result = await _findDoctorByAuthNumber(_searchController.text);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result != null) {
          _searchResult = result;
        } else {
          _errorMessage = 'No user found with these details.';
        }
      });
    }
  }

  Future<void> _scanQRAndConnect(bool isDoctor) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QRScannerScreen(),
      ),
    );

    if (result != null) {
        setState(() {
            _searchController.text = result;
        });
        _performSearch();
    }
  }

  Future<void> _sendConnectionRequest(String receiverId) async {
    final prefs = await SharedPreferences.getInstance();
    final senderMongoId = prefs.getString('user_id');

    if (senderMongoId == null) {
        _showErrorDialog('User ID not found locally. Please re-login.');
        return;
    }

    try {
        final apiResponse = await ApiService.post('/connections/request', {
            'senderId': senderMongoId,
            'receiverId': receiverId,
        });

        if (apiResponse.statusCode == 200) {
            _showSuccessDialog('Connection request sent successfully!');
            setState(() {
                _searchResult = null;
                _searchController.clear();
            });
        } else {
            final error = jsonDecode(apiResponse.body);
            _showErrorDialog(error['message'] ?? 'Failed to send request');
        }
    } catch (e) {
        _showErrorDialog('Network error: $e');
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

  // Neumorphic Widgets Helpers
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

  Widget _buildNeumorphicTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: _labelColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD1D9E6), Colors.white],
              stops: [0.0, 1.0],
            ),
            boxShadow: [
              BoxShadow(color: Colors.white, offset: Offset(4, 4), blurRadius: 4, spreadRadius: 1),
              BoxShadow(color: Color(0xFFD1D9E6), offset: Offset(-4, -4), blurRadius: 4, spreadRadius: 1),
            ],
          ),
          child: Container(
             decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _backgroundColor, 
             ),
             child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: _labelColor),
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                hintText: label,
                hintStyle: TextStyle(color: _labelColor.withOpacity(0.5)),
                contentPadding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ),
      ],
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
            // Dynamic title based on user type
            _isDoctor ? 'Find Organisation' : 'Find Doctor',
            style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 22,
            ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                _buildNeumorphicTextField(
                    controller: _searchController,
                    label: _searchLabel,
                    icon: Icons.search,
                    onChanged: (val) {},
                ),
                SizedBox(height: 30),
                if (_isLoading) 
                    Center(child: CircularProgressIndicator(color: _primaryColor))
                else ...[
                     _buildNeumorphicButton(
                        onPressed: _performSearch, 
                        child: Center(
                            child: Text('SEARCH', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.5))
                        )
                    ),
                    SizedBox(height: 20),
                    Center(child: Text('OR', style: TextStyle(color: _textColor.withOpacity(0.5), fontWeight: FontWeight.bold))),
                    SizedBox(height: 20),
                    _buildNeumorphicButton(
                        onPressed: () => _scanQRAndConnect(_isDoctor),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                                Icon(Icons.qr_code_scanner_rounded, color: _primaryColor),
                                SizedBox(width: 10),
                                Text('CONNECT VIA QR', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            ],
                        )
                    ),
                ],
                
                if (_errorMessage != null) ...[
                    SizedBox(height: 30),
                    Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)))
                ],

                if (_searchResult != null) ...[
                    SizedBox(height: 40),
                    Text('Search Result', style: TextStyle(color: _textColor.withOpacity(0.5), fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 15),
                    _buildNeumorphicContainer(
                        Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                                children: [
                                     Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _backgroundColor,
                                            boxShadow: [_darkShadow, _lightShadow]
                                        ),
                                        child: Icon(Icons.person, size: 40, color: _primaryColor)
                                    ),
                                    SizedBox(height: 20),
                                    Text(_searchResult!['name'] ?? 'Unknown', style: TextStyle(color: _textColor, fontSize: 22, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 5),
                                    Text(_searchResult!['category'] ?? '', style: TextStyle(color: _labelColor, fontSize: 16)),
                                    SizedBox(height: 25),
                                    
                                    // Details list
                                    Container(
                                        padding: EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(15),
                                            color: _backgroundColor,
                                            border: Border.all(color: Colors.white),
                                            boxShadow: [
                                                BoxShadow(color: Color(0xFFD1D9E6), offset: Offset(2, 2), blurRadius: 2),
                                                BoxShadow(color: Colors.white, offset: Offset(-2, -2), blurRadius: 2),
                                            ]
                                        ),
                                        child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                                Text(
                                                    _searchResult!['category'] == 'Doctor' ? 'Auth ID' : 'GSTIN',
                                                    style: TextStyle(color: _labelColor, fontWeight: FontWeight.bold)
                                                ),
                                                Text(
                                                    _searchResult!['category'] == 'Doctor' 
                                                        ? (_searchResult!['doctorAuthNumber'] ?? 'N/A')
                                                        : (_searchResult!['gstinNumber'] ?? 'N/A'),
                                                     style: TextStyle(color: _textColor, fontWeight: FontWeight.bold)
                                                )
                                            ],
                                        )
                                    ),
                                    SizedBox(height: 30),
                                    _buildNeumorphicButton(
                                        onPressed: () => _sendConnectionRequest(_searchResult!['_id']),
                                        child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                                Icon(Icons.send_rounded, color: _primaryColor),
                                                SizedBox(width: 10),
                                                Text('SEND REQUEST', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold))
                                            ],
                                        )
                                    )
                                ],
                            ),
                        )
                    )
                ]
            ],
        ),
      ),
    );
  }
}

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.1, end: 0.9).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Basic Neumorphic Colors needed here too for the back button
    const Color primaryColor = Color(0xFF3B82F6);

    return Scaffold(
      body: Stack(
        children: [
          // 1. MobileScanner filling the screen
          MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String? code = barcodes.first.rawValue;
                if (code != null) {
                  Navigator.pop(context, code);
                }
              }
            },
          ),

          // 2. Dark Overlay with Cutout
          // We use ColorFiltered to create a hole in the simplified way or just multiple containers
          // Simplest robust way: 4 containers
          Column(
            children: [
               Expanded(child: Container(color: Colors.black.withOpacity(0.6))),
               Row(
                 children: [
                   Expanded(child: Container(color: Colors.black.withOpacity(0.6), height: 260)),
                   Container(
                     width: 260,
                     height: 260,
                     decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1),
                        borderRadius: BorderRadius.circular(20),
                        // Transparent center
                     ),
                   ),
                   Expanded(child: Container(color: Colors.black.withOpacity(0.6), height: 260)),
                 ],
               ),
               Expanded(child: Container(color: Colors.black.withOpacity(0.6))),
            ],
          ),

          // 3. Scanning Animation Line
          Center(
             child: Container(
                width: 260,
                height: 260,
                alignment: Alignment.topCenter,
                child: AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                        return FractionallySizedBox(
                            heightFactor: _animation.value,
                            child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                    height: 2,
                                    width: 240,
                                    decoration: BoxDecoration(
                                        color: primaryColor,
                                        boxShadow: [
                                            BoxShadow(color: primaryColor.withOpacity(0.6), blurRadius: 10, spreadRadius: 2)
                                        ]
                                    ),
                                ),
                            )
                        );
                    }
                ),
             )
          ),

          // 4. Top Bar (Back Button & Title)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
               children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.2))
                        ),
                        child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20)
                    ),
                  ),
                  Expanded(
                      child: Text(
                          'Scan QR Code', 
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: 1)
                      )
                  ),
                  SizedBox(width: 40) // Balance title
               ],
            ),
          ),
          
          // 5. Bottom Instructions
          Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Column(
                  children: [
                      Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20)
                          ),
                          child: Text(
                              'Align code within frame',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
                          )
                      )
                  ],
              )
          )
        ],
      ),
    );
  }
}
