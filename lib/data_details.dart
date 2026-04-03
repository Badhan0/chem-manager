import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:chem_manager/services/api_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chem_manager/controllers/auth_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DataDetailsPage extends StatefulWidget {
  final String userName;
  final String userId;

  const DataDetailsPage(
      {super.key, required this.userName, required this.userId});

  @override
  _DataDetailsPageState createState() => _DataDetailsPageState();
}

class _DataDetailsPageState extends State<DataDetailsPage> {
  String? _currentUserCategory;
  String? _currentUserId;
  String _selectedStatus = 'pending';
  bool isDarkMode = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Color get _backgroundColor =>
      isDarkMode ? Color(0xFF121212) : Color(0xFFE6EBF5);
  Color get _primaryColor => isDarkMode ? Color(0xFFBB86FC) : Color(0xFF3B82F6);
  Color get _secondaryColor =>
      isDarkMode ? Color(0xFF3700B3) : Color(0xFF2563EB);
  Color get _textColor => isDarkMode ? Colors.white : Color(0xFF475569);

  BoxShadow get _lightShadow => isDarkMode
      ? BoxShadow(
          color: Colors.black.withOpacity(0.5),
          offset: Offset(-4, -4),
          blurRadius: 12,
          spreadRadius: 0,
        )
      : BoxShadow(
          color: Colors.white,
          offset: Offset(-5, -5),
          blurRadius: 10,
          spreadRadius: 0,
        );

  BoxShadow get _darkShadow => isDarkMode
      ? BoxShadow(
          color: Colors.black.withOpacity(0.8),
          offset: Offset(4, 4),
          blurRadius: 12,
          spreadRadius: 0,
        )
      : BoxShadow(
          color: Color(0xFFC1C9D8),
          offset: Offset(5, 5),
          blurRadius: 10,
          spreadRadius: 0,
        );

  Color get _dateHeaderColor =>
      isDarkMode ? Color(0xFF2D2D2D) : Color(0xFFFFF9C4);
  Color get _offDayColor => isDarkMode ? Color(0xFF373737) : Color(0xFFFFF3E0);
  Color get _dateHeaderTextColor =>
      isDarkMode ? Colors.white : Colors.amber[800]!;
  Color get _offDayTextColor =>
      isDarkMode ? Colors.white70 : Colors.orange[800]!;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getString('user_id');
      _currentUserCategory = prefs.getString('user_category');
    });
    
    // Also fetch connected user details if needed for appointment days or just rely on API?
    // We need appointment days of the Doctor.
    // If I am Org, connected user is Doctor -> fetch his days.
    // If I am Doctor, connected user is Org -> my days are with me.
    // Actually, appointment days are stored in Doctor's profile usually?
    // Wait, the schema says `appointmentDays` is in User model. Usually Org sets days for Doctor.
    // Let's look at `User.js`.
    // It has `appointmentDays`.
    // In current logic: Org sets days for Doctor.
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      isDarkMode
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: _backgroundColor,
              systemNavigationBarColor: _backgroundColor,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: _backgroundColor,
              systemNavigationBarColor: _backgroundColor,
            ),
    );

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.userName,
            style: TextStyle(
                color: _primaryColor,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.1),
                    offset: Offset(2, 2),
                    blurRadius: 4,
                  ),
                ])),
        centerTitle: true,
        backgroundColor: _backgroundColor,
        elevation: 4,
        shadowColor: _backgroundColor.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        iconTheme: IconThemeData(color: _primaryColor),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: _backgroundColor,
          statusBarIconBrightness:
              isDarkMode ? Brightness.light : Brightness.dark,
        ),
      ),
      body: Container(
        color: _backgroundColor,
        child: _currentUserCategory == 'Doctor'
            ? _buildDoctorView()
            : _buildOrganizationView(),
      ),
    );
  }

  Widget _buildOrganizationView() {
    if (_currentUserId == null) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        _buildStatusButtons(),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
             // Fetch patients where orgId = ME, doctorId = Connected User
            future: _fetchPatients(orgId: _currentUserId!, doctorId: widget.userId, status: _selectedStatus),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                 return const Center(child: Text('Error loading patients'));
              }

              final patients = snapshot.data ?? [];
              
              // We need available days. Since I am Org, days for this doctor are in MY profile.
              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchUserProfile(_currentUserId!),
                builder: (context, orgSnapshot) {
                  if (orgSnapshot.connectionState == ConnectionState.waiting) {
                     return const Center(child: CircularProgressIndicator());
                  }

                  final orgData = orgSnapshot.data ?? {};
                  final appointmentDaysMap = Map<String, dynamic>.from(orgData['appointmentDays'] ?? {});
                  // Days for this specific doctor (widget.userId)
                  final availableDays = (appointmentDaysMap[widget.userId] as List<dynamic>? ?? [])
                          .map((day) => _dayStringToInt(day.toString()))
                          .toList();

                  return _buildPatientList(patients, availableDays);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: _buildNeumorphicButton(
            onPressed: () => _showPatientForm(context),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, color: _primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text('Add Patient',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorView() {
    if (_currentUserId == null) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        _buildStatusButtons(),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            // Fetch patients where doctorId = ME, orgId = Connected User
            future: _fetchPatients(doctorId: _currentUserId!, orgId: widget.userId, status: _selectedStatus),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
               if (snapshot.hasError) {
                 return const Center(child: Text('Error loading patients'));
              }

              final patients = snapshot.data ?? [];
              
              // Available days: I am Doctor. Org sets days. Org is connected user (widget.userId).
              return FutureBuilder<Map<String, dynamic>>(
                future: _fetchUserProfile(widget.userId),
                builder: (context, orgSnapshot) {
                   if (orgSnapshot.connectionState == ConnectionState.waiting) {
                     return const Center(child: CircularProgressIndicator());
                  }
                  
                  final orgData = orgSnapshot.data ?? {};
                  final appointmentDaysMap = Map<String, dynamic>.from(orgData['appointmentDays'] ?? {});
                  // Days for ME (_currentUserId) set by Org (widget.userId)
                  final availableDays = (appointmentDaysMap[_currentUserId] as List<dynamic>? ?? [])
                      .map((day) => _dayStringToInt(day.toString()))
                      .toList();

                  return _buildPatientList(patients, availableDays);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<List<dynamic>> _fetchPatients({String? orgId, String? doctorId, String? status}) async {
      String query = '/patients?';
      if (orgId != null) query += 'orgId=$orgId&';
      if (doctorId != null) query += 'doctorId=$doctorId&';
      if (status != null) query += 'status=$status&';
      
      try {
        final response = await ApiService.get(query);
        if (response.statusCode == 200) {
           return jsonDecode(response.body);
        }
      } catch (e) {
        print('Error fetching patients: $e');
      }
      return [];
  }

  Future<Map<String, dynamic>> _fetchUserProfile(String userId) async {
      try {
        final response = await ApiService.get('/users/$userId');
        if (response.statusCode == 200) {
           return jsonDecode(response.body);
        }
      } catch (e) {
          print('Error fetching user profile: $e');
      }
      return {};
  }

  Widget _buildStatusButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: PhysicalModel(
        color: Colors.transparent,
        elevation: 4,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statusButton('Pending', 'pending'),
                _statusButton('Visited', 'visited'),
                _statusButton('Not Visited', 'not_visited'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusButton(String label, String status) {
    final isSelected = _selectedStatus == status;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: _backgroundColor,
        boxShadow: isSelected ? [_darkShadow, _lightShadow] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedStatus = status;
            });
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? _primaryColor : Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientList(List<dynamic> patients, List<int> availableDays) {
    if (patients.isEmpty) {
      return Center(
        child: Text(
          'No ${_selectedStatus.replaceAll('_', ' ')} patients',
          style: TextStyle(
            color: _textColor.withOpacity(0.6),
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: patients.length,
      itemBuilder: (context, index) {
        final patient = patients[index] as Map<String, dynamic>;
        // Assuming API returns 'createdAt' or 'updatedAt' for timestamp field logic, or just 'appointmentDate'. 
        // Backend Patient model has 'timestamps: true', so 'createdAt' exists.
        final DateTime registeredDate = DateTime.parse(patient['createdAt']);

        return _buildPatientContainer(
          patient,
          _currentUserCategory == 'Organisation',
          index + 1,
          registeredDate,
        );
      },
    );
  }

  Widget _buildPatientContainer(
    Map<String, dynamic> patient,
    bool isOrgView,
    int serialNumber,
    DateTime registeredDate,
  ) {
    final dateFormat = DateFormat('dd-MMM-yyyy hh:mm a');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [_darkShadow, _lightShadow],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: _backgroundColor,
          ),
          child: InkWell(
            onTap: () => _showPatientDetails(context, patient),
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$serialNumber.',
                    style: TextStyle(color: _textColor, fontSize: 16),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        patient['name'],
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textColor),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateFormat.format(registeredDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: _textColor.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusText(patient),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(Map<String, dynamic> patient) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          _darkShadow,
          _lightShadow,
        ],
      ),
      child: Text(
        patient['status'].toString().toUpperCase(),
        style: TextStyle(
          color: patient['status'] == 'visited'
              ? Colors.green
              : patient['status'] == 'pending'
                  ? Colors.orange
                  : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showPatientDetails(BuildContext context, Map<String, dynamic> patient) {
    final bool isDoctor = _currentUserCategory == 'Doctor';
    final bool isPending = patient['status'] == 'pending';
    // Backend returns ISO string for appointmentDate
    final appointmentDate = DateTime.parse(patient['appointmentDate']);
    final today = DateTime.now();
    final isTodayAppointment = appointmentDate.year == today.year &&
        appointmentDate.month == today.month &&
        appointmentDate.day == today.day;
    
    // Use createdAt for registered date display
    final registeredDate = DateTime.parse(patient['createdAt']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(
          child: Text(patient['name'],
              style: TextStyle(color: Colors.purple[400], fontSize: 24)),
        ),
        content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailItem('Age', patient['age'].toString()),
                _buildDetailItem('Gender', patient['gender']),
                if (_currentUserCategory == 'Organisation')
                  _buildEditableDetailItem(
                    context,
                    'Weight',
                    patient['weight'] ?? '',
                    patient['_id'],
                    'weight',
                  ),
                if (_currentUserCategory == 'Organisation')
                  _buildEditableBPFields(
                    context,
                    patient['bp'] ?? '',
                    patient['_id'],
                  ),
                _buildDetailItem('Phone', patient['phone']),
                _buildDetailItem(
                    'Registered',
                    DateFormat('dd-MMM-yyyy hh:mm a')
                        .format(registeredDate)),
                _buildDetailItem(
                    'Status', patient['status'].toString().toUpperCase()),
                if (isDoctor && isPending && isTodayAppointment)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                              'Not Visited', Icons.close, Colors.red, () {
                            _updatePatientStatus(patient['_id'], 'not_visited');
                            Navigator.pop(context);
                          }),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildActionButton(
                              'Mark Visited', Icons.check, Colors.green, () {
                            _updatePatientStatus(patient['_id'], 'visited');
                            Navigator.pop(context);
                          }),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: _buildActionButton(
                    'Share Report via WhatsApp',
                    Icons.share,
                    Colors.green,
                    () {
                      // Navigator.pop(context); // Keep dialog open
                      _downloadAndShareReport(patient['_id'], patient['name'], patient['phone']);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _updatePatientStatus(String patientId, String status) async {
      try {
        final response = await ApiService.patch('/patients/$patientId', {'status': status});
        if (response.statusCode == 200) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status updated')));
           setState(() {}); // Refresh list
        } else {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status')));
        }
      } catch(e) {
         print('Error updating status: $e');
      }
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(15),
        ),
        child: TextButton.icon(
          icon: Icon(icon, color: color, size: 18),
          label: Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return value.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(label,
                      style: TextStyle(
                          color:
                              isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [_darkShadow, _lightShadow],
                    ),
                    child: Text(
                      label == 'BP' && value.contains('/')
                          ? 'BP ${value.replaceAll('/', '/')}'
                          : value,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        : SizedBox.shrink();
  }

  Widget _buildEditableDetailItem(BuildContext context, String label,
      String value, String patientId, String field) {
    TextEditingController controller = TextEditingController(text: value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(label,
                style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [_darkShadow, _lightShadow],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration.collapsed(
                        hintText: 'Enter $label',
                      ),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.save, color: _primaryColor, size: 20),
                    onPressed: () async {
                      if (controller.text != value) {
                        try {
                           final response = await ApiService.patch('/patients/$patientId', {field: controller.text});

                            if (response.statusCode == 200) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$label updated successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                setState((){});
                            } else {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed')));
                            }
                        } catch (e) {
                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableBPFields(
    BuildContext context,
    String currentBP,
    String patientId,
  ) {
    String bpSys = '';
    String bpDias = '';

    if (currentBP.contains('/')) {
      final parts = currentBP.split('/');
      bpSys = parts[0];
      bpDias = parts.length > 1 ? parts[1] : '';
    }

    TextEditingController sysController = TextEditingController(text: bpSys);
    TextEditingController diasController = TextEditingController(text: bpDias);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('BP',
                style: TextStyle(
                    color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                    fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [_darkShadow, _lightShadow],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: sysController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Sys',
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: diasController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Dias',
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildActionButton(
                      'Save',
                      Icons.save,
                      _primaryColor,
                      () async {
                        String newBP =
                            '${sysController.text}/${diasController.text}';
                        if (newBP != currentBP) {
                            try {
                               final response = await ApiService.patch('/patients/$patientId', {'bp': newBP});
                               
                               if (response.statusCode == 200) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('BP updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  setState((){});
                               } else {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed')));
                               }
                            } catch (e) {
                               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPatientForm(BuildContext context) async {
    final nameController = TextEditingController();
    final ageController = TextEditingController();
    String? gender;
    final weightController = TextEditingController();
    final bp1Controller = TextEditingController();
    final bp2Controller = TextEditingController();
    final phoneController = TextEditingController();
    final dateController = TextEditingController();
    List<int> availableDays = [];

    // Get available days via API
    try {
      final userProfile = await _fetchUserProfile(_currentUserId!); // Fetch MY profile (Org)
      final appointmentDays = Map<String, dynamic>.from(userProfile['appointmentDays'] ?? {});
      availableDays = (appointmentDays[widget.userId] as List<dynamic>? ?? [])
          .map((day) => _dayStringToInt(day.toString()))
          .toList();
    } catch (e) {
      print('Error fetching days: $e');
    }

    if (availableDays.isEmpty) {
      if(mounted) _showErrorDialog(context, 'No visiting days set for this doctor');
      return;
    }
    
    if(!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [_darkShadow, _lightShadow],
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Add Patient',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildNeumorphicTextField(nameController, 'Name'),
                    const SizedBox(height: 15),
                    _buildNeumorphicTextField(ageController, 'Age',
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 15),
                    _buildGenderDropdown(gender, (value) => gender = value!),
                    const SizedBox(height: 15),
                    _buildNeumorphicTextField(weightController, 'Weight'),
                    const SizedBox(height: 15),
                    _buildBPFields(bp1Controller, bp2Controller),
                    const SizedBox(height: 15),
                    _buildNeumorphicTextField(phoneController, 'Phone',
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 15),
                    _buildDateField(dateController, availableDays),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton('Cancel', Icons.close,
                              Colors.red, () => Navigator.pop(context)),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildActionButton(
                              'Save', Icons.check, Colors.green, () async {
                            if (nameController.text.isEmpty ||
                                ageController.text.isEmpty ||
                                dateController.text.isEmpty ||
                                gender == null) {
                              _showErrorDialog(
                                  context, 'Please fill all required fields');
                              return;
                            }
                            
                            // Parse Date: "dd/MM/yyyy" -> DateTime
                            // Or however _buildDateField formats it.
                            // Assuming _buildDateField uses DateFormat('dd/MM/yyyy') or similar.
                            // Let's assume standard ISO format for API or explicit Date object.
                            // Backend expects Date object (which Express parses from ISO string).
                            
                            try {
                                // Parse date from controller (dd-MMM-yyyy) to ISO
                                DateFormat inputFormat = DateFormat('dd-MMM-yyyy');
                                DateTime date = inputFormat.parse(dateController.text);
                                
                                final patientData = {
                                  'orgId': _currentUserId,
                                  'doctorId': widget.userId,
                                  'name': nameController.text,
                                  'age': int.parse(ageController.text),
                                  'gender': gender,
                                  'weight': weightController.text,
                                  'bp': '${bp1Controller.text}/${bp2Controller.text}',
                                  'phone': phoneController.text,
                                  'appointmentDate': date.toIso8601String(),
                                };

                                final response = await ApiService.post('/patients', patientData);
                                
                                if (response.statusCode == 201) {
                                   Navigator.pop(context); // Close form
                                   
                                   final newPatient = jsonDecode(response.body);
                                   
                                   // Show success & share dialog
                                   showDialog(
                                       context: context,
                                       builder: (context) => AlertDialog(
                                           backgroundColor: _backgroundColor,
                                           title: Text('Patient Added', style: TextStyle(color: _primaryColor)),
                                           content: Text('Patient created successfully with ID: ${newPatient['patientId']}\nWould you like to share the report?', style: TextStyle(color: _textColor)),
                                           actions: [
                                               TextButton(
                                                   onPressed: () => Navigator.pop(context),
                                                   child: Text('Done', style: TextStyle(color: _textColor))
                                               ),
                                               ElevatedButton.icon(
                                                   icon: Icon(Icons.share, color: Colors.white),
                                                   label: Text('Share via Whatsapp', style: TextStyle(color: Colors.white)),
                                                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                   onPressed: () {
                                                       Navigator.pop(context);
                                                       _downloadAndShareReport(newPatient['_id'], newPatient['name'], newPatient['phone']);
                                                   },
                                               )
                                           ],
                                       )
                                   );

                                   if (mounted) setState(() {}); // Refresh list
                                } else {
                                   _showErrorDialog(context, 'Failed to add patient');
                                }
                            } catch (e) {
                                print(e);
                                _showErrorDialog(context, 'Error adding patient: $e');
                            }
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }





  Widget _buildNeumorphicButton(
      {required VoidCallback? onPressed, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _backgroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSubHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          boxShadow: [_darkShadow, _lightShadow],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: _backgroundColor,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicTextField(
      TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: _textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
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

  Widget _buildGenderDropdown(
      String? genderValue, ValueChanged<String?> onChanged) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Gender',
          labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
          border: InputBorder.none,
          filled: true,
          fillColor: _backgroundColor,
        ),
        dropdownColor: _backgroundColor,
        style: TextStyle(color: _textColor),
        value: genderValue,
        items: ['Male', 'Female']
            .map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender, style: TextStyle(color: _textColor))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBPFields(TextEditingController bp1Controller,
      TextEditingController bp2Controller) {
    return Row(
      children: [
        Expanded(
          child: _buildNeumorphicTextField(bp1Controller, 'BP Sys',
              keyboardType: TextInputType.number),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildNeumorphicTextField(bp2Controller, 'BP Dias',
              keyboardType: TextInputType.number),
        ),
      ],
    );
  }

  int _dayStringToInt(String day) {
    const days = {
      'Monday': 1,
      'Tuesday': 2,
      'Wednesday': 3,
      'Thursday': 4,
      'Friday': 5,
      'Saturday': 6,
      'Sunday': 7,
    };
    return days[day] ?? 1;
  }

  DateTime _findNextValidDate(List<int> availableDays) {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    DateTime date = todayDateOnly;

    for (int i = 0; i < 14; i++) {
      final dateDateOnly = DateTime(date.year, date.month, date.day);
      if (availableDays.contains(date.weekday) &&
          !dateDateOnly.isBefore(todayDateOnly)) {
        return date;
      }
      date = date.add(const Duration(days: 1));
    }
    return date;
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
      TextEditingController controller, List<int> availableDays) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: InkWell(
        onTap: () => _selectDate(context, controller, availableDays),
        borderRadius: BorderRadius.circular(15),
        child: IgnorePointer(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: 'Appointment Date',
              labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
              filled: true,
              fillColor: _backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              suffixIcon: Icon(Icons.calendar_today, color: _primaryColor),
            ),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Required field' : null,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context,
      TextEditingController controller, List<int> availableDays) async {
    final DateTime initialDate = _findNextValidDate(availableDays);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: initialDate,
      lastDate: DateTime.now().add(const Duration(days: 60)),
      selectableDayPredicate: (DateTime date) {
        final dateOnly = DateTime(date.year, date.month, date.day);
        final todayOnly = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );
        return availableDays.contains(date.weekday) &&
            !dateOnly.isBefore(todayOnly);
      },
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = DateFormat('dd-MMM-yyyy').format(picked);
    }
  }

// Removed _buildDateSection



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
  Future<void> _downloadAndShareReport(String patientId, String name, String phone) async {
      try {
        final response = await ApiService.get('/patients/$patientId/pdf');
        
        if (response.statusCode == 200) {
          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/report-$patientId.pdf');
          await file.writeAsBytes(response.bodyBytes);
          
          if (!mounted) return;

          if (Platform.isAndroid) {
             try {
                 const platform = MethodChannel('com.example.chem_manager/whatsapp');
                 // Format phone: remove +, spaces, dashes
                 String formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
                 
                 // Handle leading 0
                 if (formattedPhone.startsWith('0')) {
                    formattedPhone = formattedPhone.substring(1);
                 }
                 // Auto-add India code (91) if length is 10 (likely local number)
                 if (formattedPhone.length == 10) {
                    formattedPhone = '91$formattedPhone';
                 }
                 
                 await platform.invokeMethod('shareFile', {
                     'phone': formattedPhone,
                     'path': file.path
                 });
                 print('Shared via Direct Intent to $formattedPhone');
                 return; 
             } catch (e) {
                 print('Direct Intent failed, falling back: $e');
             }
          }
          
          // Share via Share Sheet, usually supports WhatsApp
          final result = await Share.shareXFiles(
              [XFile(file.path)],
              text: 'Medical Report for $name ($phone)',
              subject: 'Medical Report: ${file.path.split("/").last}'
          );
          
          if (result.status == ShareResultStatus.success) {
              print('Shared successfully');
          }
        } else {
          if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate report')));
        }
      } catch (e) {
        print('Error sharing report: $e');
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
}
