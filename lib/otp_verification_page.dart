import 'package:chem_manager/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:chem_manager/home_page.dart';  // Ensure this import is valid

class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  final AuthController _authController = AuthController();
  bool _isLoading = false;

  // Design Constants matching SignupPage/LoginPage
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
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: _backgroundColor,
            ),
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _textColor, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 5),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: _labelColor),
                fillColor: Colors.transparent,
                filled: true,
                border: InputBorder.none,
                counterText: "",
                hintText: '  • • • • • •  ',
                hintStyle: TextStyle(color: _labelColor.withOpacity(0.5)),
                contentPadding: EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ),
        ),
      ],
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
          child: Center(
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      text.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1.5,
                      ),
                    )),
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
                // Header (Step 3 of 3)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: _backgroundColor,
                            shape: BoxShape.circle,
                            boxShadow: [_darkShadow, _lightShadow]),
                        child:
                            Icon(Icons.arrow_back_ios_new, size: 16, color: _textColor),
                      ),
                    ),
                    Text(
                      "STEP 3 OF 3",
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
                // Progress Bar - Step 3 Active
                Row(
                  children: [
                    Expanded(
                        child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                                color: _primaryAccent.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2)))),
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: _primaryAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: _primaryAccent.withOpacity(0.5),
                                  blurRadius: 4)
                            ])),
                    Expanded(
                        child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                                color: _primaryAccent.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2)))),
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: _primaryAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: _primaryAccent.withOpacity(0.5),
                                  blurRadius: 4)
                            ])),
                    Expanded(
                        child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                                color: _primaryAccent.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(2)))),
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: _primaryAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: _primaryAccent.withOpacity(0.5),
                                  blurRadius: 4)
                            ])),
                  ],
                ),

                SizedBox(height: 40),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    shape: BoxShape.circle,
                    boxShadow: [_darkShadow, _lightShadow],
                  ),
                  child: Icon(Icons.verified_user_outlined,
                      size: 60, color: _primaryAccent),
                ),

                SizedBox(height: 30),

                Center(
                  child: Text(
                    "Verification",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Center(
                  child: Text(
                    "Enter the code sent to",
                    style: TextStyle(
                      fontSize: 16,
                      color: _labelColor,
                    ),
                  ),
                ),
                Center(
                   child: Text(
                    widget.email,
                    style: TextStyle(
                      fontSize: 14,
                       fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                ),

                SizedBox(height: 40),

                _buildInsetField(
                  controller: _otpController,
                  label: "One Time Password",
                  icon: Icons.lock_clock,
                ),

                SizedBox(height: 40),

                _buildMainButton(
                  onPressed: _verifyOtp,
                  text: 'Verify & Login',
                ),

                SizedBox(height: 20),

                TextButton(
                  onPressed: _resendOtp,
                  child: Center(
                    child: Text(
                      'Resend Code',
                      style: TextStyle(
                        color: _primaryAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
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

  Future<void> _verifyOtp() async {
    if (_otpController.text.length != 6) {
      _showErrorDialog(context, 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() => _isLoading = true);

    final result =
        await _authController.verifyOtp(widget.email, _otpController.text);

    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } else {
      _showErrorDialog(context, result['message']);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    final result = await _authController.resendOtp(widget.email);
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );
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
                Text(message,
                    style: TextStyle(color: _textColor),
                    textAlign: TextAlign.center),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [_darkShadow, _lightShadow],
                    color: _backgroundColor,
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK',
                        style: TextStyle(
                            color: _primaryAccent, fontWeight: FontWeight.bold)),
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
