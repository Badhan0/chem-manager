import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chem_manager/services/api_service.dart';
import 'dart:convert';

class PatientDetailsPage extends StatefulWidget {
  final Map<String, dynamic> patient;
  final bool isDarkMode;
  final String currentUserCategory;
  final String currentUserId;

  const PatientDetailsPage({
    super.key,
    required this.patient,
    required this.isDarkMode,
    required this.currentUserCategory,
    required this.currentUserId,
  });

  @override
  _PatientDetailsPageState createState() => _PatientDetailsPageState();
}

class _PatientDetailsPageState extends State<PatientDetailsPage> {
  late Map<String, dynamic> _patient;
  bool _isLoadingHistory = true;
  List<dynamic> _previousHistory = [];

  final _weightController = TextEditingController();
  final _bp1Controller = TextEditingController();
  final _bp2Controller = TextEditingController();

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
    _patient = Map<String, dynamic>.from(widget.patient);
    _weightController.text = _patient['weight'] ?? '';
    
    final bpStr = _patient['bp'] ?? '';
    if (bpStr.contains('/')) {
      final parts = bpStr.split('/');
      _bp1Controller.text = parts[0];
      _bp2Controller.text = parts.length > 1 ? parts[1] : '';
    }
    
    _fetchVisitHistory();
  }

  Future<void> _fetchVisitHistory() async {
    final patientId = _patient['patientId'];
    if (patientId == null) {
      setState(() => _isLoadingHistory = false);
      return;
    }

    try {
      final response = await ApiService.get('/patients?patientId=$patientId');
      if (response.statusCode == 200) {
        final List<dynamic> history = jsonDecode(response.body);
        // Filter out current active appointment to only show historical ones
        final filtered = history.where((r) => r['_id'] != _patient['_id']).toList();
        
        // Sort history: latest first
        filtered.sort((a, b) {
          final aTime = DateTime.parse(a['appointmentDate']);
          final bTime = DateTime.parse(b['appointmentDate']);
          return bTime.compareTo(aTime);
        });

        setState(() {
          _previousHistory = filtered;
          _isLoadingHistory = false;
        });
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      print('Error fetching visit history: $e');
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      final response = await ApiService.patch('/patients/${_patient['_id']}', {'status': status});
      if (response.statusCode == 200) {
        setState(() {
          _patient['status'] = status;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${status.replaceAll('_', ' ').toUpperCase()}'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateField(String fieldName, String value) async {
    try {
      final response = await ApiService.patch('/patients/${_patient['_id']}', {fieldName: value});
      if (response.statusCode == 200) {
        setState(() {
          _patient[fieldName] = value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fieldName.toUpperCase()} updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update failed'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print('Error updating $fieldName: $e');
    }
  }

  bool _isSlotTimeArrived(String? slotTime) {
    if (slotTime == null || slotTime.isEmpty) {
      return true;
    }
    
    try {
      final parts = slotTime.split('-');
      if (parts.isEmpty) return true;
      final startTimeStr = parts[0].trim();
      
      DateTime? parsedTime;
      final formats = [
        DateFormat('hh:mm a'),
        DateFormat('h:mm a'),
        DateFormat('HH:mm'),
        DateFormat('H:mm'),
      ];
      
      for (var format in formats) {
        try {
          parsedTime = format.parse(startTimeStr);
          break;
        } catch (_) {}
      }
      
      if (parsedTime == null) {
        try {
          parsedTime = DateFormat.jm().parse(startTimeStr);
        } catch (_) {}
      }
      
      if (parsedTime == null) return true;
      
      final now = DateTime.now();
      if (now.hour > parsedTime.hour) {
        return true;
      } else if (now.hour == parsedTime.hour) {
        return now.minute >= parsedTime.minute;
      }
      return false;
    } catch (e) {
      print('Error checking if slot time arrived: $e');
      return true;
    }
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: _textColor.withOpacity(0.6),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: _textColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableWeightItem() {
    final isOrg = widget.currentUserCategory == 'Organisation';
    if (!isOrg) {
      return _buildDetailItem('Weight', _patient['weight'] ?? '');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            child: Text(
              'Weight',
              style: TextStyle(
                color: _textColor.withOpacity(0.6),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [_darkShadow, _lightShadow],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: TextField(
                      controller: _weightController,
                      style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildNeumorphicIconButton(
                  icon: Icons.check,
                  onPressed: () => _updateField('weight', _weightController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableBPItem() {
    final isOrg = widget.currentUserCategory == 'Organisation';
    if (!isOrg) {
      return _buildDetailItem('BP', _patient['bp'] ?? '');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 120,
            child: Text(
              'BP',
              style: TextStyle(
                color: _textColor.withOpacity(0.6),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [_darkShadow, _lightShadow],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _bp1Controller,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 13),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: 'Sys',
                            ),
                          ),
                        ),
                        Text('/', style: TextStyle(color: _textColor)),
                        Expanded(
                          child: TextField(
                            controller: _bp2Controller,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: _textColor, fontWeight: FontWeight.bold, fontSize: 13),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              hintText: 'Dias',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildNeumorphicIconButton(
                  icon: Icons.check,
                  onPressed: () => _updateField('bp', '${_bp1Controller.text}/${_bp2Controller.text}'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicIconButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: IconButton(
        icon: Icon(icon, color: _primaryColor, size: 18),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildStatusSection() {
    final status = _patient['status']?.toString().toUpperCase() ?? 'PENDING';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: status == 'VISITED'
            ? Colors.green.withOpacity(0.15)
            : status == 'PENDING'
                ? Colors.orange.withOpacity(0.15)
                : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: status == 'VISITED'
              ? Colors.green
              : status == 'PENDING'
                  ? Colors.orange
                  : Colors.red,
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: status == 'VISITED'
              ? Colors.green
              : status == 'PENDING'
                  ? Colors.orange
                  : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isDoctor = widget.currentUserCategory == 'Doctor';
    final bool isPending = _patient['status'] == 'pending';
    
    if (!isDoctor || !isPending) return const SizedBox.shrink();

    final appointmentDate = DateTime.parse(_patient['appointmentDate']).toLocal();
    final today = DateTime.now();
    final isTodayAppointment = appointmentDate.year == today.year &&
        appointmentDate.month == today.month &&
        appointmentDate.day == today.day;
    final isPastAppointment = appointmentDate.isBefore(DateTime(today.year, today.month, today.day));
    final isTimeArrived = isPastAppointment || (isTodayAppointment && _isSlotTimeArrived(_patient['appointmentTime']));

    if (!isTimeArrived) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 25.0),
      child: Row(
        children: [
          Expanded(
            child: _buildNeumorphicButton(
              color: Colors.red.shade400,
              onPressed: () => _updateStatus('not_visited'),
              child: const Text(
                'Not Visited',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildNeumorphicButton(
              color: Colors.green.shade400,
              onPressed: () => _updateStatus('visited'),
              child: const Text(
                'Mark Visited',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNeumorphicButton({required Color color, required VoidCallback onPressed, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [_darkShadow, _lightShadow],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: child,
      ),
    );
  }

  Widget _buildPreviousHistorySection() {
    if (_isLoadingHistory) {
      return const Padding(
        padding: EdgeInsets.only(top: 30.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_previousHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 35),
        Row(
          children: [
            Icon(Icons.history_rounded, color: _primaryColor),
            const SizedBox(width: 8),
            Text(
              'Previous Medical History',
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
    String appointmentDateStr = '';
    try {
      appointmentDateStr = DateFormat('dd-MMM-yyyy').format(DateTime.parse(_patient['appointmentDate']).toLocal());
    } catch (_) {
      appointmentDateStr = _patient['appointmentDate']?.toString() ?? '';
    }

    final createdAtStr = _patient['createdAt'] != null
        ? DateFormat('dd-MMM-yyyy hh:mm a').format(DateTime.parse(_patient['createdAt']).toLocal())
        : '';

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textColor),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Patient Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: _backgroundColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [_darkShadow, _lightShadow],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _patient['name'] ?? '',
                              style: TextStyle(
                                color: _textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ID: ${_patient['patientId'] ?? ""}',
                              style: TextStyle(
                                color: _textColor.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusSection(),
                    ],
                  ),
                  const Divider(height: 30),
                  _buildDetailItem('Age', _patient['age']?.toString() ?? ''),
                  _buildDetailItem('Gender', _patient['gender'] ?? ''),
                  _buildDetailItem('Phone', _patient['phone'] ?? ''),
                  _buildEditableWeightItem(),
                  _buildEditableBPItem(),
                  _buildDetailItem('Appointment Date', appointmentDateStr),
                  _buildDetailItem('Time Slot', _patient['appointmentTime'] ?? ''),
                  _buildDetailItem('Issue Details', _patient['issueDetails'] ?? ''),
                  if (createdAtStr.isNotEmpty)
                    _buildDetailItem('Registered Date', createdAtStr),
                  _buildActionButtons(),
                ],
              ),
            ),
            _buildPreviousHistorySection(),
          ],
        ),
      ),
    );
  }
}
