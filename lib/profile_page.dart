import 'package:chem_manager/controllers/auth_controller.dart';
import 'package:chem_manager/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chem_manager/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chem_manager/services/location_service.dart';
import 'package:geolocator/geolocator.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthController _authController = AuthController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doctorAuthNumberController =
      TextEditingController();
  final TextEditingController _aadharNumberController = TextEditingController();
  final TextEditingController _gstinNumberController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _blockController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _specializationController =
      TextEditingController();
  final FocusNode _specializationFocusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();

  final List<String> _medicalSpecializations = [
    'General Physician',
    'Family Medicine',
    'Internal Medicine',
    'Pediatrics',
    'General Surgery',
    'Cardiology',
    'Dermatology',
    'Endocrinology',
    'Gastroenterology',
    'Hematology',
    'Infectious Disease',
    'Nephrology',
    'Neurology',
    'Obstetrics and Gynecology (OB/GYN)',
    'Oncology',
    'Ophthalmology',
    'Orthopedics',
    'Otolaryngology (ENT)',
    'Psychiatry',
    'Pulmonology',
    'Rheumatology',
    'Urology',
    'Anesthesiology',
    'Radiology',
    'Emergency Medicine',
    'Pathology',
    'Physical Medicine and Rehabilitation',
    'Plastic Surgery',
    'Preventive Medicine',
    'Medical Genetics',
    'Neurosurgery',
    'Thoracic Surgery',
    'Vascular Surgery',
    'Critical Care Medicine',
    'Geriatric Medicine',
    'Sports Medicine',
    'Pain Medicine',
    'Allergy and Immunology',
    'Sleep Medicine',
    'Ayurveda',
    'Homeopathy',
    'Dentist',
    'Physiotherapy',
    'Nutritionist/Dietitian',
  ]..sort();

  String? _selectedCategory;
  bool _isButtonActive = false;
  bool _profileCompleted = false;
  String? _uniqueId;
  String? _userId;
  double? _latitude;
  double? _longitude;
  Map<String, dynamic>? _locationDetails;
  bool _isDetectingLocation = false;
  bool _isLocationConfirmed = false;
  bool _isLocationAlreadySet = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final result = await _authController.fetchUserProfile();
    if (result['success']) {
      final userData = result['data'];
      setState(() {
        _nameController.text = userData['name'] ?? '';
        _selectedCategory = userData['category'];
        _doctorAuthNumberController.text = userData['doctorAuthNumber'] ?? '';
        _gstinNumberController.text = userData['gstinNumber'] ?? '';
        _aadharNumberController.text = userData['aadharNumber'] ?? '';
        _specializationController.text = userData['specialization'] ?? '';
        _locationController.text = userData['locationDetails']?['fullAddress'] ?? '';
        _landmarkController.text = userData['locationDetails']?['landmark'] ?? '';
        _streetController.text = userData['locationDetails']?['street'] ?? '';
        _areaController.text = userData['locationDetails']?['area'] ?? '';
        _blockController.text = userData['locationDetails']?['block'] ?? '';
        _districtController.text = userData['locationDetails']?['district'] ?? '';
        _latitude = userData['latitude'];
        _longitude = userData['longitude'];
        _locationDetails = userData['locationDetails'];
        if (_locationController.text.isNotEmpty) {
           _isLocationConfirmed = true;
           _isLocationAlreadySet = true;
        }
        
        _uniqueId = _selectedCategory == 'Doctor'
            ? userData['doctorAuthNumber']
            : userData['gstinNumber'];
            
        if (_doctorAuthNumberController.text == 'undefined') _doctorAuthNumberController.clear();
        if (_gstinNumberController.text == 'undefined') _gstinNumberController.clear();
        if (_specializationController.text == 'undefined') _specializationController.clear();

        // Check if profile is TRULY completed including specialization
        _profileCompleted = _nameController.text.isNotEmpty &&
            _aadharNumberController.text.length == 12 &&
            ((_selectedCategory == 'Doctor' &&
                    _doctorAuthNumberController.text.isNotEmpty &&
                    _specializationController.text.isNotEmpty) ||
                (_selectedCategory == 'Organisation' &&
                    _gstinNumberController.text.isNotEmpty));

        _checkButtonState();
        
        // Add listeners to enable the button as soon as anything changes
        _nameController.addListener(_checkButtonState);
        _aadharNumberController.addListener(_checkButtonState);
        _gstinNumberController.addListener(_checkButtonState);
        _doctorAuthNumberController.addListener(_checkButtonState);
        _specializationController.addListener(_checkButtonState);
        _landmarkController.addListener(_checkButtonState);
        _streetController.addListener(_checkButtonState);
        _areaController.addListener(_checkButtonState);
        _blockController.addListener(_checkButtonState);
        _districtController.addListener(_checkButtonState);

      });
    } else {
       final prefs = await SharedPreferences.getInstance();
       setState(() {
          _nameController.text = prefs.getString('user_name') ?? '';
       });
    }
  }

  void _checkButtonState() {
    bool isValidAadhar = _aadharNumberController.text.length == 12;
    bool isValidProfessionalId = _selectedCategory == 'Doctor'
        ? _doctorAuthNumberController.text.isNotEmpty
        : (_selectedCategory == 'Organisation'
            ? _gstinNumberController.text.isNotEmpty
            : true);
            
    bool isValidSpecialization = _selectedCategory == 'Doctor' 
        ? _specializationController.text.isNotEmpty 
        : true;

    setState(() {
      _isButtonActive = _nameController.text.isNotEmpty &&
          isValidAadhar &&
          _selectedCategory != null &&
          isValidProfessionalId &&
          isValidSpecialization &&
          _isLocationConfirmed;
          
      // Ensure if we are already completed, the button is at least enabled if settings are valid
      if (_profileCompleted && _nameController.text.isNotEmpty) {
        _isButtonActive = true; 
      }
    });
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
            _isLocationConfirmed = false; // Need to confirm new detection
          });
        }
      } else {
        _showErrorDialog(context, 'Could not determine location. Please ensure GPS is active and has a signal.');
      }
    } catch (e) {
      _showErrorDialog(context, 'Error detecting location: $e');
    } finally {
      setState(() => _isDetectingLocation = false);
      _checkButtonState();
    }
  }

  Future<void> _saveUserData() async {
    final professionalId = _selectedCategory == 'Doctor'
        ? _doctorAuthNumberController.text
        : _gstinNumberController.text;

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

    final updates = {
      'name': _nameController.text,
      'category': _selectedCategory,
      'doctorAuthNumber': _selectedCategory == 'Doctor' ? _doctorAuthNumberController.text : null,
      'gstinNumber': _selectedCategory == 'Organisation' ? _gstinNumberController.text : null,
      'aadharNumber': _aadharNumberController.text,
      'specialization': _specializationController.text,
      'latitude': _latitude,
      'longitude': _longitude,
      'locationDetails': finalLocationDetails,
    };

    print('Saving Profile Updates: $updates');
    final result = await _authController.updateUserProfile(updates);
    
    if (result['success']) {
       print('Profile updated successfully in DB');
       setState(() {
         _profileCompleted = true;
         _uniqueId = professionalId;
         _isLocationAlreadySet = true;
       });
       await _showSuccessDialog(context, 'Profile updated successfully!');
       if (mounted) {
         _checkButtonState();
       }
    } else {
       print('Profile update FAILED in DB: ${result['message']}');
       _showErrorDialog(context, result['message'] ?? 'Failed to update profile');
    }
  }

  Future<void> _showSuccessDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Text(
                  'Scan QR to Connect',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Scan this code to add me to your connections',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002) // Perspective
                    ..rotateX(0.1)
                    ..rotateY(0.1),
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _primaryColor.withOpacity(0.8),
                          _primaryColor.withOpacity(0.6),
                          _primaryColor.withOpacity(0.4),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: Offset(5, 5),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: Offset(-5, -5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Stack(
                        children: [
                          QrImageView(
                            data: _uniqueId ?? '',
                            version: QrVersions.auto,
                            size: 220,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.white,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.white,
                            ),
                          ),
                          Positioned.fill(
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.white.withOpacity(0.1),
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              TweenAnimationBuilder(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 2),
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, sin(value * 2 * pi) * 5),
                    child: child,
                  );
                },
                child: Text(
                  'Scan to Connect',
                  style: TextStyle(
                      color: _primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0), // Example padding
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildNeumorphicDialogButton(
                      text: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              )
            ],
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
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: Material(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
            child: Text(
              text,
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Neumorphic design parameters
  static const Color _backgroundColor = Color(0xFFE6EBF5); // Lighter blue-grey
  static const Color _primaryColor = Color(0xFF3B82F6); // Bright Blue
  static const Color _textColor = Color(0xFF475569); // Slate 600
  static const Color _labelColor = Color(0xFF94A3B8); // Gray/Slate color

  BoxShadow get _lightShadow => BoxShadow(
        color: Colors.white,
        offset: const Offset(-5, -5),
        blurRadius: 10,
        spreadRadius: 0,
      );

  BoxShadow get _darkShadow => BoxShadow(
        color: const Color(0xFFC1C9D8),
        offset: const Offset(5, 5),
        blurRadius: 10,
        spreadRadius: 0,
      );

  Widget _buildNeumorphicContainer(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: child,
    );
  }

  Widget _buildNeumorphicTextField(
      TextEditingController controller, String label,
      {bool isNumber = false,
      int? maxLength,
      bool enabled = true,
      String? Function(String?)? validator,
      FocusNode? focusNode}) {
    return _buildNeumorphicContainer(
      IgnorePointer(
        ignoring: !enabled,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          validator: validator,
          style: TextStyle(color: _textColor),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (value) => _checkButtonState(),
        ),
      ),
    );
  }

  Widget _buildNeumorphicAutocomplete(
      TextEditingController controller, String label, FocusNode focusNode,
      {bool enabled = true, String? Function(String?)? validator}) {
    return LayoutBuilder(builder: (context, constraints) {
      return RawAutocomplete<String>(
        textEditingController: controller,
        focusNode: focusNode,
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return _medicalSpecializations.where((String option) {
            return option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase());
          });
        },
        fieldViewBuilder: (BuildContext context,
            TextEditingController textEditingController,
            FocusNode fieldFocusNode,
            VoidCallback onFieldSubmitted) {
          return CompositedTransformTarget(
            link: _layerLink,
            child: _buildNeumorphicTextField(
              textEditingController,
              label,
              enabled: enabled,
              validator: validator,
              focusNode: fieldFocusNode,
            ),
          );
        },
        optionsViewBuilder: (BuildContext context,
            AutocompleteOnSelected<String> onSelected,
            Iterable<String> options) {
          return CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topLeft,
            followerAnchor: Alignment.bottomLeft,
            offset: const Offset(0, -10),
            child: Material(
              elevation: 4.0,
              color: Colors.transparent,
              child: Container(
                width: constraints.maxWidth,
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                   color: _backgroundColor,
                   borderRadius: BorderRadius.circular(15),
                   boxShadow: [_darkShadow, _lightShadow],
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (BuildContext context, int index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () {
                        onSelected(option);
                        _checkButtonState();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Text(option, style: TextStyle(color: _textColor)),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    });
  }

  void _showSpecializationPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredOptions = _medicalSpecializations
                .where((option) =>
                    option.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [_darkShadow, _lightShadow],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Select Specialization',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Search Box
                    _buildNeumorphicContainer(
                      TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: TextStyle(color: _textColor.withOpacity(0.5)),
                          prefixIcon: Icon(Icons.search, color: _textColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        style: TextStyle(color: _textColor),
                        onChanged: (value) {
                          setDialogState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    // List Options
                    Flexible(
                      child: SizedBox(
                        height: 300, 
                        child: ListView.builder(
                          itemCount: filteredOptions.length,
                          itemBuilder: (context, index) {
                            final option = filteredOptions[index];
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _specializationController.text = option;
                                  _checkButtonState();
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _textColor.withOpacity(0.1),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: _textColor,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Colors.red.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSelectionField(
      TextEditingController controller, String label, VoidCallback onTap,
      {bool enabled = true}) {
    return _buildNeumorphicContainer(
      InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     if (controller.text.isNotEmpty)
                      Text(
                        label,
                        style: TextStyle(
                          color: _textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    Text(
                      controller.text.isEmpty ? label : controller.text,
                      style: TextStyle(
                        color: controller.text.isEmpty
                            ? _textColor.withOpacity(0.7)
                            : _textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_drop_down, color: _primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final prefs = snapshot.data!;
        String email = prefs.getString('user_email') ?? '';
        String initialLetter = email.isNotEmpty ? email[0].toUpperCase() : '';
        String photoUrl = FirebaseAuth.instance.currentUser?.photoURL ?? '';

        return Scaffold(
          backgroundColor: _backgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: _backgroundColor,
            elevation: 4,
            shadowColor: _backgroundColor.withOpacity(0.5),
            title: Text(
              'Profile',
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
            centerTitle: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
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
                      onTap: () async {
                        await _authController.logout();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginPage()),
                            (route) => false,
                          );
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.logout,
                          color: _primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [_darkShadow, _lightShadow],
                      color: _backgroundColor,
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.transparent,
                      backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                      child: photoUrl.isEmpty ? Text(
                        initialLetter,
                        style: TextStyle(
                          fontSize: 40,
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildNeumorphicContainer(
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: const [
                        DropdownMenuItem(value: 'Doctor', child: Text('Doctor')),
                        DropdownMenuItem(
                            value: 'Organisation', child: Text('Organisation')),
                      ],
                      onChanged: !_profileCompleted
                          ? (value) {
                              setState(() {
                                _selectedCategory = value;
                                _doctorAuthNumberController.clear();
                                _gstinNumberController.clear();
                                _checkButtonState();
                              });
                            }
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: _textColor),
                      dropdownColor: _backgroundColor,
                      validator: (value) =>
                          value == null ? 'Category required' : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildNeumorphicTextField(_nameController, "Name",
                    enabled: true, // Name always editable for modification
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Name required' : null),
                const SizedBox(height: 20),
                if (_selectedCategory == 'Doctor')
                  _buildNeumorphicTextField(
                      _doctorAuthNumberController, 'Doctor Authorization Number',
                      enabled: !_profileCompleted,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required field' : null),
                if (_selectedCategory == 'Organisation')
                  _buildNeumorphicTextField(_gstinNumberController, 'GSTIN Number',
                      enabled: !_profileCompleted,
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required field' : null),
                const SizedBox(height: 20),
                _buildNeumorphicTextField(
                  _aadharNumberController,
                  'Aadhar Number',
                  isNumber: true,
                  maxLength: 12,
                  enabled: !_profileCompleted,
                  validator: (value) =>
                      value?.length != 12 ? 'Must be 12 digits' : null,
                ),
                if (_selectedCategory == 'Doctor') ...[
                  const SizedBox(height: 20),
                  _buildSelectionField(
                    _specializationController,
                    'Medical Specialization',
                    () => _showSpecializationPicker(context),
                    enabled: !_profileCompleted,
                  ),
                ],
                if (_selectedCategory != null)
                  Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildNeumorphicContainer(
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedCategory == 'Doctor' ? 'CLINIC/CLINICIAN LOCATION' : 'ORGANISATION LOCATION',
                                    style: TextStyle(
                                      color: _labelColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  if (_isDetectingLocation)
                                    const SizedBox(
                                      width: 15,
                                      height: 15,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_locationController.text.isNotEmpty) ...[
                                if (_isLocationAlreadySet) ...[
                                  if (_locationDetails?['landmark']?.toString().isNotEmpty ?? false)
                                    Text(
                                      "Landmark: ${_locationDetails?['landmark']}",
                                      style: TextStyle(color: _textColor.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  Text(
                                    "Street: ${_locationDetails?['street'] ?? 'N/A'}",
                                    style: TextStyle(color: _textColor.withOpacity(0.8), fontSize: 13),
                                  ),
                                  Text(
                                    "Area: ${_locationDetails?['area'] ?? 'N/A'}",
                                    style: TextStyle(color: _textColor.withOpacity(0.8), fontSize: 13),
                                  ),
                                  if (_locationDetails?['block']?.toString().isNotEmpty ?? false)
                                    Text(
                                      "Block: ${_locationDetails?['block']}",
                                      style: TextStyle(color: _textColor.withOpacity(0.8), fontSize: 13),
                                    ),
                                  Text(
                                    "District: ${_locationDetails?['district'] ?? 'N/A'}",
                                    style: TextStyle(color: _textColor.withOpacity(0.8), fontSize: 13),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _locationController.text,
                                    style: TextStyle(
                                      color: _textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ] else ...[
                                  _buildNeumorphicTextField(_landmarkController, 'Landmark (Optional)'),
                                  const SizedBox(height: 12),
                                  _buildNeumorphicTextField(_streetController, 'Street/Road'),
                                  const SizedBox(height: 12),
                                  _buildNeumorphicTextField(_areaController, 'Area/Locality'),
                                  const SizedBox(height: 12),
                                  _buildNeumorphicTextField(_blockController, 'Block (Optional)'),
                                  const SizedBox(height: 12),
                                  _buildNeumorphicTextField(_districtController, 'District'),
                                  const SizedBox(height: 12),
                                  // Hide the full address text while editing sub-fields to keep it clean
                                  Text(
                                    "Coords: ${_latitude?.toStringAsFixed(4)}, ${_longitude?.toStringAsFixed(4)}",
                                    style: TextStyle(color: _primaryColor.withOpacity(0.6), fontSize: 10),
                                  ),
                                ],
                              ] else
                                Text(
                                  'Location not set',
                                  style: TextStyle(
                                    color: _textColor.withOpacity(0.5),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              const SizedBox(height: 15),
                               if (!_isLocationAlreadySet)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildNeumorphicDialogButton(
                                        text: 'Detect Current Location',
                                        onPressed: _detectLocation,
                                      ),
                                    ),
                                     if (_locationController.text.isNotEmpty && !_isLocationConfirmed)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 10),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(15),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.check,
                                                color: Colors.white),
                                            onPressed: () {
                                              setState(() {
                                                _isLocationConfirmed = true;
                                              });
                                              _checkButtonState();
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Location confirmed!')),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 30),
                  _buildNeumorphicContainer(
                    TextButton(
                      onPressed: _isButtonActive ? _saveUserData : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 40),
                        foregroundColor: _primaryColor,
                      ),
                      child: Text(
                        _profileCompleted ? 'Update Profile' : 'Save Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isButtonActive ? _primaryColor : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                if (_profileCompleted) ...[
                  const SizedBox(height: 20),
                  _buildNeumorphicContainer(
                    TextButton(
                      onPressed: _showShareDialog,
                      child: Text(
                        'Share Profile',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20), // Add some spacing between buttons could be nice
                   _buildNeumorphicContainer(
                    TextButton(
                      onPressed: () {
                          Navigator.pop(context, true);
                      },
                      child: Text(
                        'Go to Home',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        );
      },
    );
  }
}

class CornerPainter extends CustomPainter {
  final Color _primaryColor;
  CornerPainter(this._primaryColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, 15)
        ..lineTo(0, 0)
        ..lineTo(15, 0),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 15, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, 15),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width, size.height - 15)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width - 15, size.height),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(15, size.height)
        ..lineTo(0, size.height)
        ..lineTo(0, size.height - 15),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
