import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chem_manager/services/api_service.dart';
import 'dart:convert';

class AddPatientPage extends StatefulWidget {
  final String doctorId;
  final String doctorName;
  final String orgId;
  final bool isDarkMode;

  const AddPatientPage({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.orgId,
    required this.isDarkMode,
  });

  @override
  _AddPatientPageState createState() => _AddPatientPageState();
}

class _AddPatientPageState extends State<AddPatientPage> {
  // Mode Selection: 'new' or 'existing'
  String _patientMode = 'new'; 

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  String? _gender;
  final _weightController = TextEditingController();
  final _bp1Controller = TextEditingController();
  final _bp2Controller = TextEditingController();
  final _phoneController = TextEditingController();
  final _dateController = TextEditingController();
  final _issueDetailsController = TextEditingController();

  // Search field for Existing Patient
  final _searchPhoneController = TextEditingController();
  bool _isSearching = false;
  String? _existingPatientId;
  List<dynamic> _previousHistory = [];

  List<Map<String, dynamic>> _allDoctorSlots = [];
  List<int> _availableDays = [];
  List<String> _currentDaySlots = [];
  String? _selectedSlotTime;
  bool _isLoadingDays = true;
  bool _isSaving = false;

  Color get _backgroundColor =>
      widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFE6EBF5);
  Color get _primaryColor =>
      widget.isDarkMode ? const Color(0xFFBB86FC) : const Color(0xFF3B82F6);
  Color get _textColor =>
      widget.isDarkMode ? Colors.white : const Color(0xFF475569);

  BoxShadow get _lightShadow => widget.isDarkMode
      ? BoxShadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(-4, -4),
          blurRadius: 12,
          spreadRadius: 0,
        )
      : const BoxShadow(
          color: Colors.white,
          offset: Offset(-5, -5),
          blurRadius: 10,
          spreadRadius: 0,
        );

  BoxShadow get _darkShadow => widget.isDarkMode
      ? BoxShadow(
          color: Colors.black.withOpacity(0.8),
          offset: const Offset(4, 4),
          blurRadius: 12,
          spreadRadius: 0,
        )
      : const BoxShadow(
          color: const Color(0xFFC1C9D8),
          offset: Offset(5, 5),
          blurRadius: 10,
          spreadRadius: 0,
        );

  @override
  void initState() {
    super.initState();
    _fetchDoctorVisitingDays();
  }

  Future<void> _fetchDoctorVisitingDays() async {
    try {
      final response = await ApiService.get('/users/${widget.orgId}');
      if (response.statusCode == 200) {
        final userProfile = jsonDecode(response.body);
        final appointmentDays = Map<String, dynamic>.from(userProfile['appointmentDays'] ?? {});
        final rawDays = appointmentDays[widget.doctorId];
        
        List<Map<String, dynamic>> slots = [];
        if (rawDays is List) {
          for (var item in rawDays) {
            if (item is Map) {
              slots.add(Map<String, dynamic>.from(item));
            } else if (item is String) {
              slots.add({
                'day': item,
                'startTime': '09:00 AM',
                'endTime': '05:00 PM',
                'maxPatients': 20,
              });
            }
          }
        }
        
        setState(() {
          _allDoctorSlots = slots;
          _availableDays = _getAvailableDaysList(rawDays);
          _isLoadingDays = false;
        });
      } else {
        setState(() => _isLoadingDays = false);
      }
    } catch (e) {
      print('Error fetching doctor visiting days: $e');
      setState(() => _isLoadingDays = false);
    }
  }

  List<int> _getAvailableDaysList(dynamic rawDays) {
    if (rawDays == null) return [];
    List<int> list = [];
    if (rawDays is List) {
      for (var item in rawDays) {
        String? dayStr;
        if (item is Map) {
          dayStr = item['day']?.toString();
        } else if (item is String) {
          dayStr = item;
        }
        if (dayStr != null) {
          int val = _dayStringToInt(dayStr);
          if (!list.contains(val)) {
            list.add(val);
          }
        }
      }
    }
    return list;
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

  void _onDateSelected() {
    if (_dateController.text.isNotEmpty) {
      try {
        final parsedDate = DateFormat('dd-MMM-yyyy').parse(_dateController.text);
        final weekdayMap = {
          1: 'Monday',
          2: 'Tuesday',
          3: 'Wednesday',
          4: 'Thursday',
          5: 'Friday',
          6: 'Saturday',
          7: 'Sunday',
        };
        final weekdayName = weekdayMap[parsedDate.weekday];
        
        final daySlots = _allDoctorSlots.where((s) => s['day'] == weekdayName).toList();
        setState(() {
          _currentDaySlots = daySlots.map((s) => '${s['startTime']} - ${s['endTime']}').toList();
          if (_currentDaySlots.isNotEmpty) {
            _selectedSlotTime = _currentDaySlots.first;
          } else {
            _selectedSlotTime = null;
          }
        });
      } catch (e) {
        print('Error parsing selected date: $e');
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    if (_availableDays.isEmpty) return;
    final DateTime initialDate = _findNextValidDate(_availableDays);

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
        return _availableDays.contains(date.weekday) &&
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
      _dateController.text = DateFormat('dd-MMM-yyyy').format(picked);
      _onDateSelected();
    }
  }

  Future<void> _searchExistingPatient() async {
    final phone = _searchPhoneController.text.trim();
    if (phone.isEmpty) {
      _showErrorDialog('Please enter a phone number to search.');
      return;
    }

    setState(() {
      _isSearching = true;
      _existingPatientId = null;
      _previousHistory = [];
    });

    try {
      final response = await ApiService.get('/patients?phone=$phone');
      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          // Sort to find the latest patient registration
          results.sort((a, b) {
            final aTime = DateTime.parse(a['createdAt']);
            final bTime = DateTime.parse(b['createdAt']);
            return bTime.compareTo(aTime); // Latest first
          });

          final latest = results.first;
          setState(() {
            _nameController.text = latest['name'] ?? '';
            _ageController.text = latest['age']?.toString() ?? '';
            _gender = latest['gender'];
            _phoneController.text = latest['phone'] ?? '';
            _existingPatientId = latest['patientId'];
            _previousHistory = results;
          });
        } else {
          _showErrorDialog('No patient found with phone number $phone.');
        }
      } else {
        _showErrorDialog('Failed to search patient.');
      }
    } catch (e) {
      print('Error searching patient: $e');
      _showErrorDialog('Error searching patient: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _savePatient() async {
    if (_nameController.text.isEmpty ||
        _ageController.text.isEmpty ||
        _dateController.text.isEmpty ||
        _gender == null) {
      _showErrorDialog('Please fill all required fields');
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      DateFormat inputFormat = DateFormat('dd-MMM-yyyy');
      DateTime localDate = inputFormat.parse(_dateController.text);
      DateTime utcDate = DateTime.utc(localDate.year, localDate.month, localDate.day);

      final patientData = {
        'orgId': widget.orgId,
        'doctorId': widget.doctorId,
        'name': _nameController.text,
        'age': int.parse(_ageController.text),
        'gender': _gender,
        'weight': _weightController.text,
        'bp': '${_bp1Controller.text}/${_bp2Controller.text}',
        'phone': _phoneController.text,
        'appointmentDate': utcDate.toIso8601String(),
        'appointmentTime': _selectedSlotTime ?? '',
        'issueDetails': _issueDetailsController.text,
      };

      if (_patientMode == 'existing' && _existingPatientId != null) {
        patientData['patientId'] = _existingPatientId!;
      }

      final response = await ApiService.post('/patients', patientData);
      
      if (response.statusCode == 201) {
        final newPatient = jsonDecode(response.body);
        
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: _backgroundColor,
              title: Text(_patientMode == 'new' ? 'Patient Added' : 'Revisit Created', style: TextStyle(color: _primaryColor)),
              content: Text(
                'Patient appointment scheduled successfully with ID: ${newPatient['patientId']}\nWould you like to share the report?',
                style: TextStyle(color: _textColor),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(this.context, true); // Return back with refresh signal
                  },
                  child: Text('Done', style: TextStyle(color: _textColor)),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text('Share via Whatsapp', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(this.context, {
                      'refresh': true,
                      'share': true,
                      'patientId': newPatient['_id'],
                      'patientName': newPatient['name'],
                      'patientPhone': newPatient['phone'],
                    });
                  },
                ),
              ],
            ),
          );
        }
      } else {
        String errorMsg = 'Failed to schedule appointment';
        try {
          final body = jsonDecode(response.body);
          if (body['message'] != null) {
            errorMsg = body['message'];
          }
        } catch (_) {}
        _showErrorDialog(errorMsg);
      }
    } catch (e) {
      print('Error saving patient: $e');
      _showErrorDialog('Error saving patient: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    final isNew = _patientMode == 'new';
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _patientMode = 'new';
                  _existingPatientId = null;
                  _previousHistory = [];
                  _nameController.clear();
                  _ageController.clear();
                  _gender = null;
                  _phoneController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isNew ? _primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    'New Patient',
                    style: TextStyle(
                      color: isNew ? Colors.white : _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _patientMode = 'existing';
                  _nameController.clear();
                  _ageController.clear();
                  _gender = null;
                  _phoneController.clear();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isNew ? _primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    'Existing Patient',
                    style: TextStyle(
                      color: !isNew ? Colors.white : _textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Row(
        children: [
          Expanded(
            child: _buildNeumorphicTextField(
              _searchPhoneController,
              'Search Patient Phone Number',
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(width: 15),
          _buildNeumorphicButton(
            onPressed: _isSearching ? null : _searchExistingPatient,
            child: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1, bool readOnly = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        readOnly: readOnly,
        style: TextStyle(color: readOnly ? _textColor.withOpacity(0.6) : _textColor),
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

  Widget _buildGenderDropdown({bool readOnly = false}) {
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
        value: _gender,
        items: ['Male', 'Female', 'Other']
            .map((gender) => DropdownMenuItem(
                value: gender,
                child: Text(gender, style: TextStyle(color: _textColor))))
            .toList(),
        onChanged: readOnly ? null : (value) => setState(() => _gender = value),
      ),
    );
  }

  Widget _buildBPFields() {
    return Row(
      children: [
        Expanded(
          child: _buildNeumorphicTextField(_bp1Controller, 'BP Sys',
              keyboardType: TextInputType.number),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildNeumorphicTextField(_bp2Controller, 'BP Dias',
              keyboardType: TextInputType.number),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: InkWell(
        onTap: () => _selectDate(context),
        borderRadius: BorderRadius.circular(15),
        child: IgnorePointer(
          child: TextFormField(
            controller: _dateController,
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

  Widget _buildNeumorphicButton({required VoidCallback? onPressed, required Widget child}) {
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildPreviousHistorySection() {
    if (_previousHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        Row(
          children: [
            Icon(Icons.history_rounded, color: _primaryColor),
            const SizedBox(width: 8),
            Text(
              'Previous History',
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _previousHistory.length,
          itemBuilder: (context, index) {
            final record = _previousHistory[index];
            String appDateStr = '';
            try {
              appDateStr = DateFormat('dd-MMM-yyyy').format(DateTime.parse(record['appointmentDate']).toLocal());
            } catch (_) {
              appDateStr = record['appointmentDate'] ?? '';
            }

            final slot = record['appointmentTime'] ?? '';
            final weight = record['weight'] ?? '';
            final bp = record['bp'] ?? '';
            final issue = record['issueDetails'] ?? '';
            final status = record['status']?.toString().toUpperCase() ?? 'PENDING';

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [_darkShadow, _lightShadow],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$appDateStr ${slot.isNotEmpty ? "($slot)" : ""}',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: status == 'VISITED'
                              ? Colors.green.withOpacity(0.2)
                              : status == 'PENDING'
                                  ? Colors.orange.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'VISITED'
                                ? Colors.green
                                : status == 'PENDING'
                                    ? Colors.orange
                                    : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  if (weight.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('Weight: $weight', style: TextStyle(color: _textColor, fontSize: 13)),
                    ),
                  if (bp.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('BP: $bp', style: TextStyle(color: _textColor, fontSize: 13)),
                    ),
                  if (issue.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text('Issue: $issue', style: TextStyle(color: _textColor, fontSize: 13)),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExisting = _patientMode == 'existing';
    final hasPatientData = !isExisting || _existingPatientId != null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isExisting ? 'Revisit for ${widget.doctorName}' : 'Add Patient for ${widget.doctorName}',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingDays
          ? const Center(child: CircularProgressIndicator())
          : _availableDays.isEmpty
              ? Center(
                  child: Text(
                    'No visiting days configured for this doctor.',
                    style: TextStyle(color: _textColor, fontSize: 16),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildModeSelector(),
                      if (isExisting) _buildSearchSection(),
                      if (hasPatientData) ...[
                        _buildNeumorphicTextField(_nameController, 'Name', readOnly: isExisting),
                        const SizedBox(height: 15),
                        _buildNeumorphicTextField(_ageController, 'Age',
                            keyboardType: TextInputType.number, readOnly: isExisting),
                        const SizedBox(height: 15),
                        _buildGenderDropdown(readOnly: isExisting),
                        const SizedBox(height: 15),
                        _buildNeumorphicTextField(_weightController, 'Weight'),
                        const SizedBox(height: 15),
                        _buildBPFields(),
                        const SizedBox(height: 15),
                        _buildNeumorphicTextField(_phoneController, 'Phone',
                            keyboardType: TextInputType.phone, readOnly: isExisting),
                        const SizedBox(height: 15),
                        _buildDateField(),
                        if (_currentDaySlots.isNotEmpty) ...[
                          const SizedBox(height: 15),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [_darkShadow, _lightShadow],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Available Slots',
                                labelStyle: TextStyle(color: _textColor.withOpacity(0.7)),
                                border: InputBorder.none,
                                filled: true,
                                fillColor: _backgroundColor,
                              ),
                              dropdownColor: _backgroundColor,
                              style: TextStyle(color: _textColor),
                              value: _selectedSlotTime,
                              items: _currentDaySlots
                                  .map((slot) => DropdownMenuItem(
                                      value: slot,
                                      child: Text(slot, style: TextStyle(color: _textColor))))
                                  .toList(),
                              onChanged: (value) => setState(() => _selectedSlotTime = value),
                            ),
                          ),
                        ],
                        const SizedBox(height: 15),
                        _buildNeumorphicTextField(
                          _issueDetailsController,
                          'Issue Details / Description',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 35),
                        Row(
                          children: [
                            Expanded(
                              child: _buildNeumorphicButton(
                                onPressed: _isSaving ? null : () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildNeumorphicButton(
                                onPressed: _isSaving ? null : _savePatient,
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        isExisting ? 'Revisit' : 'Save',
                                        style: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        if (isExisting) _buildPreviousHistorySection(),
                      ],
                    ],
                  ),
                ),
    );
  }
}
