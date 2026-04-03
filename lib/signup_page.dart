import 'package:chem_manager/controllers/auth_controller.dart';
import 'package:chem_manager/otp_verification_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'package:chem_manager/services/location_service.dart';
import 'package:chem_manager/services/api_service.dart';
import 'package:geolocator/geolocator.dart';

class SignupPage extends StatefulWidget {
  final String? kEmail;
  final String? kName;
  final String? kFirebaseUid;
  final String? kPhotoURL;

  const SignupPage({super.key, this.kEmail, this.kName, this.kFirebaseUid, this.kPhotoURL});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  // New Controllers
  final TextEditingController _doctorAuthNumberController = TextEditingController();
  final TextEditingController _gstinNumberController = TextEditingController();
  final TextEditingController _aadharNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  final AuthController _authController = AuthController();
  String? _selectedCategory; // 'Doctor' or 'Organisation'
  String? _firebaseUid;
  String? _photoURL;
  bool _isPasswordVisible = false;
  double? _latitude;
  double? _longitude;
  Map<String, dynamic>? _locationDetails;
  bool _isDetectingLocation = false;
  bool _isLocationConfirmed = false;

  @override
  void initState() {
    super.initState();
    if (widget.kEmail != null) _emailController.text = widget.kEmail!;
    if (widget.kName != null) _nameController.text = widget.kName!;
    if (widget.kFirebaseUid != null) _firebaseUid = widget.kFirebaseUid;
    if (widget.kPhotoURL != null) _photoURL = widget.kPhotoURL;
  }

  // Design Constants matches LoginPage
  static const Color _backgroundColor = Color(0xFFE6EBF5);
  static const Color _primaryAccent = Color(0xFF3B82F6);
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

  Widget _buildInsetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool isNumber = false,
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
              colors: [
                Color(0xFFD1D9E6), 
                Colors.white,      
              ],
              stops: [0.0, 1.0],
            ),
             boxShadow: [
              BoxShadow(
                color: Colors.white,
                offset: Offset(4, 4), 
                blurRadius: 4,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Color(0xFFD1D9E6),
                offset: Offset(-4, -4), 
                blurRadius: 4,
                spreadRadius: 1,
              ),
             ] 
          ),
           child: Container(
             decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: _backgroundColor, 
             ),
             child: TextField(
              controller: controller,
              obscureText: isPassword ? !_isPasswordVisible : false,
              keyboardType: isNumber ? TextInputType.number : TextInputType.text,
              style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: _labelColor),
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: _labelColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                hintText: isPassword ? '••••••••' : label,
                hintStyle: TextStyle(color: _labelColor.withOpacity(0.5)),
                contentPadding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String subtitle,
    required String value,
    required String imagePath,
  }) {
    bool isSelected = _selectedCategory == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: isSelected ? Border.all(color: _primaryAccent, width: 2) : null,
          boxShadow: [_darkShadow, _lightShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[300],
                // image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover) 
              ),
              child: Icon(value == 'Doctor' ? Icons.medical_services : Icons.business, size: 40, color: _textColor),
            ),
            SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: _labelColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _primaryAccent : _labelColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _primaryAccent,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton({
    required VoidCallback onPressed,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _primaryAccent,
        boxShadow: [
          BoxShadow(
            color: _primaryAccent.withOpacity(0.4),
            offset: const Offset(0, 10),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF60A5FA),
            Color(0xFF2563EB),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        if (_selectedCategory != null) {
                          setState(() {
                            _selectedCategory = null;
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                           color: _backgroundColor,
                           shape: BoxShape.circle,
                           boxShadow: [_darkShadow, _lightShadow]
                        ),
                        child: Icon(Icons.arrow_back_ios_new, size: 16, color: _textColor),
                      ),
                    ),
                    Text(
                      _selectedCategory == null ? "STEP 1 OF 3" : "STEP 2 OF 3",
                      style: TextStyle(
                        color: _primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    SizedBox(width: 40), 
                  ],
                ),
                
                SizedBox(height: 30),
                // Progress Bar
                Row(
                  children: [
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _primaryAccent.withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: _primaryAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: _primaryAccent.withOpacity(0.5), blurRadius: 4)])),
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _selectedCategory != null ? _primaryAccent.withOpacity(0.3) : _primaryAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(2)))),
                    Container(width: 12, height: 12, decoration: BoxDecoration(color: _selectedCategory != null ? _primaryAccent : Colors.grey[300], shape: BoxShape.circle, boxShadow: _selectedCategory != null ? [BoxShadow(color: _primaryAccent.withOpacity(0.5), blurRadius: 4)] : null)),
                    Expanded(child: Container(height: 4, decoration: BoxDecoration(color: _primaryAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(2)))),
                     Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
                  ],
                ),

                SizedBox(height: 40),

                // Title
                Text(
                  _selectedCategory == null ? "Join as a" : "Enter Details",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  _selectedCategory == null ? "Professional" : "for ${_selectedCategory}",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _primaryAccent,
                  ),
                ),
                
                SizedBox(height: 10),
                Text(
                  _selectedCategory == null ? "Choose your account type to begin your medical journey." : "Please fill in the information below.",
                  style: TextStyle(
                    fontSize: 16,
                    color: _labelColor,
                    height: 1.5,
                  ),
                ),

                SizedBox(height: 30),

                // Category Selection
                if (_selectedCategory == null) ...[
                  _buildCategoryCard(
                    title: "Doctor",
                    subtitle: "For independent practitioners & specialists.",
                    value: "Doctor",
                    imagePath: "assets/images/doctor_avatar.png",
                  ),
                  _buildCategoryCard(
                    title: "Clinic", // Mapped to Organisation internally
                    subtitle: "For multi-doctor facilities & administrators.",
                    value: "Organisation",
                    imagePath: "assets/images/clinic_avatar.png",
                  ),
                ],

                SizedBox(height: 30),

                // Dynamic Form Fields
                if (_selectedCategory != null) ...[
                  _buildInsetField(
                    controller: _nameController,
                    label: _selectedCategory == 'Doctor' ? 'Full Name' : 'Organization Name',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 20),
                  _buildInsetField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email,
                  ),
                  SizedBox(height: 20),
                  _buildInsetField(
                    controller: _passwordController,
                    label: 'Create Password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  SizedBox(height: 20),
                  _buildInsetField(
                    controller: _aadharNumberController,
                    label: 'Aadhar Number',
                    icon: Icons.credit_card,
                    isNumber: true,
                  ),

                   if (_selectedCategory == 'Doctor')
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildInsetField(
                        controller: _doctorAuthNumberController,
                        label: 'Doctor Auth Number',
                        icon: Icons.verified_user,
                      ),
                    ),
                  if (_selectedCategory == 'Organisation')
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildInsetField(
                         controller: _gstinNumberController,
                        label: 'GSTIN Number',
                          icon: Icons.business,
                        ),
                      ),
                    if (_selectedCategory == 'Organisation')
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 12.0, bottom: 8.0),
                              child: Text(
                                "CLINIC LOCATION",
                                style: TextStyle(
                                  color: _labelColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Container(
                               padding: EdgeInsets.all(16),
                               decoration: BoxDecoration(
                                 color: _backgroundColor,
                                 borderRadius: BorderRadius.circular(20),
                                 boxShadow: [_darkShadow, _lightShadow],
                               ),
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   if (_locationController.text.isNotEmpty) ...[
                                     _buildInsetField(controller: _landmarkController, label: 'Landmark', icon: Icons.landscape_outlined),
                                     SizedBox(height: 12),
                                     _buildInsetField(controller: _streetController, label: 'Street', icon: Icons.door_front_door_outlined),
                                     SizedBox(height: 12),
                                     _buildInsetField(controller: _areaController, label: 'Area', icon: Icons.map_outlined),
                                     SizedBox(height: 12),
                                     _buildInsetField(controller: _blockController, label: 'Block', icon: Icons.grid_view_outlined),
                                     SizedBox(height: 12),
                                     _buildInsetField(controller: _districtController, label: 'District', icon: Icons.location_city_outlined),
                                     SizedBox(height: 12),
                                     Text(
                                       "Coords: ${_latitude?.toStringAsFixed(4)}, ${_longitude?.toStringAsFixed(4)}",
                                       style: TextStyle(color: _primaryAccent.withOpacity(0.6), fontSize: 10),
                                     ),
                                   ] else
                                     Text(
                                       "No location detected",
                                       style: TextStyle(color: _textColor.withOpacity(0.5), fontWeight: FontWeight.w500),
                                     ),
                                   SizedBox(height: 15),
                                   Row(
                                     children: [
                                       Expanded(
                                         child: ElevatedButton(
                                           onPressed: _isDetectingLocation ? null : _detectLocation,
                                           style: ElevatedButton.styleFrom(
                                             backgroundColor: _primaryAccent,
                                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                           ),
                                           child: _isDetectingLocation 
                                            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                            : Text("Detect Clinic Location", style: TextStyle(color: Colors.white)),
                                         ),
                                       ),
                                       if (_locationController.text.isNotEmpty && !_isLocationConfirmed)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 10),
                                            child: IconButton(
                                              icon: Icon(Icons.check_circle, color: Colors.green, size: 30),
                                              onPressed: () {
                                                setState(() => _isLocationConfirmed = true);
                                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location Confirmed!')));
                                              },
                                            ),
                                          ),
                                     ],
                                   )
                                 ],
                               ),
                            ),
                          ],
                        ),
                      ),
                  
                   SizedBox(height: 40),
                
                  // Sign Up Button
                  _buildMainButton(
                    onPressed: () => _signUp(context),
                    text: 'Next Step', 
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Google Sign Up
                  Center(
                    child: TextButton(
                      onPressed: () => _signInWithGoogle(context),
                      child: Row(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                            Image.asset('assets/images/google.ico', height: 20),
                            SizedBox(width: 10),
                            Text("Sign up with Google", style: TextStyle(color: _primaryAccent, fontWeight: FontWeight.bold)),
                         ],
                      )
                    ),
                  ),
                ],

                SizedBox(height: 30),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already registered? ", style: TextStyle(color: _labelColor)),
                      InkWell(
                        onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                        child: Text("Log in", style: TextStyle(color: _primaryAccent, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Logic Helpers
  Future<void> _signInWithGoogle(BuildContext context) async {
    final result = await _authController.googleLogin();

    if (result['success']) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (result['error'] == 'not_found') {
      setState(() {
        if (result['email'] != null) _emailController.text = result['email'];
        if (result['name'] != null) _nameController.text = result['name'];
        _firebaseUid = result['firebaseUid'];
        _photoURL = result['photoURL'];
      });
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete your profile details to sign up.')),
        );
    } else {
      _showErrorDialog(context, result['message']);
    }
  }

  Future<void> _detectLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      Position? position = await LocationService.getCurrentLocation();
      if (position != null) {
        _latitude = position.latitude;
        _longitude = position.longitude;

        final response = await ApiService.getJson('/location/reverse-geocode?latitude=$_latitude&longitude=$_longitude');

        if (response != null) {
          setState(() {
            _locationController.text = response['fullAddress'] ?? '';
            _landmarkController.text = response['landmark'] ?? '';
            _streetController.text = response['street'] ?? '';
            _areaController.text = response['area'] ?? '';
            _blockController.text = response['block'] ?? '';
            _districtController.text = response['district'] ?? '';
            _locationDetails = response;
            _isLocationConfirmed = false;
          });
        }
      }
    } catch (e) {
      _showErrorDialog(context, 'Error detecting location: $e');
    } finally {
      setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _signUp(BuildContext context) async {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category above')),
        );
        return;
      }

      if (_selectedCategory == 'Doctor' &&
          _doctorAuthNumberController.text.isEmpty) {
        _showErrorDialog(context, 'Please enter Doctor Authorization Number');
        return;
      }

      if (_selectedCategory == 'Organisation' &&
          _gstinNumberController.text.isEmpty) {
        _showErrorDialog(context, 'Please enter GSTIN Number');
        return;
      }

      if (_selectedCategory == 'Organisation' && !_isLocationConfirmed) {
        _showErrorDialog(context, 'Please detect and confirm your location');
        return;
      }

      if (_aadharNumberController.text.length != 12) {
        _showErrorDialog(
            context, 'Please enter a valid 12-digit Aadhar Number');
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final Map<String, dynamic> userData = {
        'email': _emailController.text.trim(),
        'password': _passwordController.text.trim(),
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'aadharNumber': _aadharNumberController.text.trim(),
        'fcmToken': '', 
        'firebaseUid': _firebaseUid ?? '', 
        'photoURL': _photoURL ?? '',
      };

      if (_selectedCategory == 'Doctor') {
        userData['doctorAuthNumber'] = _doctorAuthNumberController.text.trim();
      } else if (_selectedCategory == 'Organisation') {
        final Map<String, dynamic> finalLocationDetails = {
          'fullAddress': _locationController.text,
          'landmark': _landmarkController.text,
          'street': _streetController.text,
          'area': _areaController.text,
          'block': _blockController.text,
          'district': _districtController.text,
          'city': _locationDetails?['city'] ?? '',
          'state': _locationDetails?['state'] ?? '',
          'country': _locationDetails?['country'] ?? '',
          'postcode': _locationDetails?['postcode'] ?? '',
        };

        userData['gstinNumber'] = _gstinNumberController.text.trim();
        userData['latitude'] = _latitude;
        userData['longitude'] = _longitude;
        userData['locationDetails'] = finalLocationDetails;
      }

      final result = await _authController.signup(userData);
      
      if (context.mounted) Navigator.pop(context);

      if (result['success']) {
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => OtpVerificationPage(email: result['email'])),
          );
        }
      } else {
        if (context.mounted) _showErrorDialog(context, result['message']);
      }
  }
  
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [_darkShadow, _lightShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(message, style: TextStyle(color: _textColor), textAlign: TextAlign.center),
                const SizedBox(height: 25),
                Container(
                   decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [_darkShadow, _lightShadow],
                      color: _backgroundColor,
                   ),
                   child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK', style: TextStyle(color: _primaryAccent, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
