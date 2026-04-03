import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chem_manager/services/api_service.dart';
import 'dart:convert';
import 'home_page.dart';

class PaymentGatewaySetupPage extends StatefulWidget {
  const PaymentGatewaySetupPage({super.key});

  @override
  State<PaymentGatewaySetupPage> createState() => _PaymentGatewaySetupPageState();
}

class _PaymentGatewaySetupPageState extends State<PaymentGatewaySetupPage> {
  final _formKey = GlobalKey<FormState>();
  
  String _selectedMethod = 'Bank Account';
  final List<String> _methods = ['Bank Account', 'UPI', 'Stripe', 'Razorpay'];

  // Bank Controllers
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();

  // UPI Controller
  final TextEditingController _upiIdController = TextEditingController();

  bool _isLoading = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentDetails();
  }

  Future<void> _loadPaymentDetails() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final response = await ApiService.get('/users/payment-details/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null) {
          setState(() {
            _selectedMethod = data['method'] ?? 'Bank Account';
            _bankNameController.text = data['bankName'] ?? '';
            _accountNumberController.text = data['accountNumber'] ?? '';
            _ifscController.text = data['ifscCode'] ?? '';
            _holderNameController.text = data['accountHolderName'] ?? '';
            _upiIdController.text = data['upiId'] ?? '';
            _isSaved = true;
          });
        }
      }
    } catch (e) {
      print('Error loading payment details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePaymentDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final payload = {
        'userId': userId,
        'method': _selectedMethod,
        if (_selectedMethod == 'Bank Account') ...{
          'bankName': _bankNameController.text,
          'accountNumber': _accountNumberController.text,
          'ifscCode': _ifscController.text,
          'accountHolderName': _holderNameController.text,
        },
        if (_selectedMethod == 'UPI') ...{
          'upiId': _upiIdController.text,
        },
        // For Stripe/Razorpay, usually we just set a flag or redirect to onboarding
        if (_selectedMethod == 'Stripe' || _selectedMethod == 'Razorpay') ...{
          'isExternalSetup': true,
        }
      };

      final response = await ApiService.post('/users/payment-details', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment details saved successfully')),
        );
        setState(() => _isSaved = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save payment details')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePage.backgroundColor,
      appBar: AppBar(
        title: Text('Manage Payment Options', 
          style: TextStyle(color: HomePage.primaryColor, fontWeight: FontWeight.bold)),
        backgroundColor: HomePage.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: HomePage.primaryColor),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 30),
                  _buildMethodSelector(),
                  const SizedBox(height: 25),
                  if (_selectedMethod == 'Bank Account') _buildBankFields(),
                  if (_selectedMethod == 'UPI') _buildUpiFields(),
                  if (_selectedMethod == 'Stripe' || _selectedMethod == 'Razorpay') _buildExternalServiceNotice(),
                  const SizedBox(height: 40),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HomePage.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSaved ? Icons.verified_user_rounded : Icons.info_outline_rounded,
              color: _isSaved ? Colors.green : Colors.orange,
              size: 30,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isSaved ? 'Payment Gateway Active' : 'Setup Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: HomePage.textColor,
                  ),
                ),
                Text(
                  _isSaved 
                    ? 'Your account is ready to receive payments.' 
                    : 'Set up your payment details to start selling.',
                  style: TextStyle(
                    fontSize: 14,
                    color: HomePage.textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('Preferred Payout Method', 
            style: TextStyle(color: HomePage.textColor.withOpacity(0.8), fontWeight: FontWeight.bold)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: HomePage.backgroundColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedMethod,
              isExpanded: true,
              dropdownColor: HomePage.backgroundColor,
              items: _methods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method, style: TextStyle(color: HomePage.textColor)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedMethod = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBankFields() {
    return Column(
      children: [
        _buildNeumorphicTextField(_bankNameController, 'Bank Name', Icons.account_balance),
        const SizedBox(height: 20),
        _buildNeumorphicTextField(_accountNumberController, 'Account Number', Icons.numbers, isNumber: true),
        const SizedBox(height: 20),
        _buildNeumorphicTextField(_ifscController, 'IFSC Code', Icons.code),
        const SizedBox(height: 20),
        _buildNeumorphicTextField(_holderNameController, 'Account Holder Name', Icons.person),
      ],
    );
  }

  Widget _buildUpiFields() {
    return _buildNeumorphicTextField(_upiIdController, 'UPI ID (e.g. user@bank)', Icons.alternate_email);
  }

  Widget _buildExternalServiceNotice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HomePage.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
      ),
      child: Column(
        children: [
          Icon(
            _selectedMethod == 'Stripe' ? Icons.payment : Icons.account_balance_wallet,
            color: HomePage.primaryColor,
            size: 50,
          ),
          const SizedBox(height: 15),
          Text(
            'Connect with $_selectedMethod',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: HomePage.textColor),
          ),
          const SizedBox(height: 10),
          Text(
            'You will be redirected to $_selectedMethod\'s secure portal to complete the onboarding process. This allows you to receive payments directly to your wallet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: HomePage.textColor.withOpacity(0.7)),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Mock redirection logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Redirecting to $_selectedMethod...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HomePage.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Connect Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Center(
      child: GestureDetector(
        onTap: _savePaymentDetails,
        child: Container(
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            color: HomePage.backgroundColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
          ),
          child: Center(
            child: Text(
              'Save Payment Settings',
              style: TextStyle(
                color: HomePage.primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNeumorphicTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false}) {
    return Container(
      decoration: BoxDecoration(
        color: HomePage.backgroundColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [HomePage.darkShadow, HomePage.lightShadow],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: HomePage.textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: HomePage.textColor.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: HomePage.primaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }
}
