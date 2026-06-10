import 'package:chem_manager/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final AuthController _authController = AuthController();

  int _step = 1; // 1 = email, 2 = OTP, 3 = new password
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _email = '';
  String _resetToken = '';
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Neumorphic design params matching login page
  static const Color _backgroundColor = Color(0xFFE6EBF5);
  static const Color _primaryAccent = Color(0xFF3B82F6);
  static const Color _textColor = Color(0xFF475569);
  static const Color _labelColor = Color(0xFF94A3B8);

  static final BoxShadow _lightShadow = BoxShadow(
    color: Colors.white,
    offset: const Offset(-5, -5),
    blurRadius: 10,
  );
  static final BoxShadow _darkShadow = BoxShadow(
    color: const Color(0xFFC1C9D8),
    offset: const Offset(5, 5),
    blurRadius: 10,
  );

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _emailController.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _otpValue => _otpControllers.map((c) => c.text).join();

  void _animateNextStep() {
    _slideController.reset();
    _slideController.forward();
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Please enter a valid email address.');
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authController.forgotPassword(email);
    setState(() => _isLoading = false);
    if (result['success']) {
      _email = email;
      setState(() => _step = 2);
      _animateNextStep();
    } else {
      _showError(result['message']);
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      _showError('Please enter the complete 6-digit OTP.');
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authController.verifyResetOtp(_email, otp);
    setState(() => _isLoading = false);
    if (result['success']) {
      _resetToken = result['resetToken'];
      setState(() => _step = 3);
      _animateNextStep();
    } else {
      _showError(result['message']);
    }
  }

  Future<void> _handleResetPassword() async {
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;
    if (newPass.isEmpty || newPass.length < 6) {
      _showError('Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirmPass) {
      _showError('Passwords do not match.');
      return;
    }
    setState(() => _isLoading = true);
    final result = await _authController.resetPassword(_email, _resetToken, newPass);
    setState(() => _isLoading = false);
    if (result['success']) {
      _showSuccess();
    } else {
      _showError(result['message']);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Error'),
        content: Text(msg, style: TextStyle(color: _textColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: _primaryAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryAccent,
                boxShadow: [
                  BoxShadow(
                    color: _primaryAccent.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Password Reset!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your password has been updated. You can now log in with your new password.',
              style: TextStyle(color: _textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildMainButton('Back to Login', () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            }),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────── Build ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [_darkShadow, _lightShadow],
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, color: _textColor, size: 18),
          ),
          onPressed: () {
            if (_step > 1) {
              setState(() => _step--);
              _animateNextStep();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          'Reset Password',
          style: TextStyle(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 12, 30, 4),
      child: Row(
        children: List.generate(3, (i) {
          final isActive = _step >= i + 1;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isActive ? _primaryAccent : const Color(0xFFC1C9D8),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case 1:
        return _buildEmailStep();
      case 2:
        return _buildOtpStep();
      case 3:
        return _buildNewPasswordStep();
      default:
        return _buildEmailStep();
    }
  }

  // ─── Step 1 ───

  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _backgroundColor,
            boxShadow: [_darkShadow, _lightShadow],
          ),
          child: Icon(Icons.lock_reset_rounded, color: _primaryAccent, size: 44),
        ),
        const SizedBox(height: 24),
        Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your registered email address to receive a reset OTP.',
          style: TextStyle(fontSize: 14, color: _labelColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        _buildInsetField(
          controller: _emailController,
          label: 'Registered Email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 36),
        _isLoading
            ? CircularProgressIndicator(color: _primaryAccent)
            : _buildMainButton('Send OTP', _handleSendOtp),
      ],
    );
  }

  // ─── Step 2 ───

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _backgroundColor,
            boxShadow: [_darkShadow, _lightShadow],
          ),
          child: Icon(Icons.mark_email_read_outlined, color: _primaryAccent, size: 44),
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: TextStyle(fontSize: 14, color: _labelColor),
            children: [
              const TextSpan(text: 'A 6-digit OTP was sent to\n'),
              TextSpan(
                text: _email,
                style: TextStyle(color: _primaryAccent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => _buildOtpBox(i)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isLoading ? null : () async {
            setState(() => _isLoading = true);
            await _authController.forgotPassword(_email);
            setState(() => _isLoading = false);
            for (final c in _otpControllers) c.clear();
            _otpFocusNodes[0].requestFocus();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('OTP resent to $_email'),
              backgroundColor: _primaryAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ));
          },
          child: Text('Resend OTP', style: TextStyle(color: _primaryAccent, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        _isLoading
            ? CircularProgressIndicator(color: _primaryAccent)
            : _buildMainButton('Verify OTP', _handleVerifyOtp),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 44,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [_darkShadow, _lightShadow],
        ),
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          maxLength: 1,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: TextStyle(color: _textColor, fontSize: 20, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            if (val.isNotEmpty && index < 5) {
              _otpFocusNodes[index + 1].requestFocus();
            } else if (val.isEmpty && index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }

  // ─── Step 3 ───

  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 24),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _backgroundColor,
            boxShadow: [_darkShadow, _lightShadow],
          ),
          child: Icon(Icons.shield_outlined, color: _primaryAccent, size: 44),
        ),
        const SizedBox(height: 24),
        Text(
          'New Password',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: const Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a strong password (min. 6 characters).',
          style: TextStyle(fontSize: 14, color: _labelColor),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 36),
        _buildInsetField(
          controller: _newPasswordController,
          label: 'New Password',
          icon: Icons.lock_outline,
          isPassword: true,
          showPassword: _showNewPassword,
          onToggle: () => setState(() => _showNewPassword = !_showNewPassword),
        ),
        const SizedBox(height: 24),
        _buildInsetField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_person_outlined,
          isPassword: true,
          showPassword: _showConfirmPassword,
          onToggle: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
        ),
        const SizedBox(height: 36),
        _isLoading
            ? CircularProgressIndicator(color: _primaryAccent)
            : _buildMainButton('Reset Password', _handleResetPassword),
        const SizedBox(height: 20),
      ],
    );
  }

  // ────────────────────────── Reusable widgets ──────────────────────────────

  Widget _buildInsetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool showPassword = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(color: _labelColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.white, offset: const Offset(4, 4), blurRadius: 4, spreadRadius: 1),
              BoxShadow(color: const Color(0xFFD1D9E6), offset: const Offset(-4, -4), blurRadius: 4, spreadRadius: 1),
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword && !showPassword,
            keyboardType: keyboardType,
            style: TextStyle(color: _textColor, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: _labelColor),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off, color: _labelColor),
                      onPressed: onToggle,
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: InputBorder.none,
              hintText: isPassword ? '••••••••' : 'example@gmail.com',
              hintStyle: TextStyle(color: _labelColor.withOpacity(0.5)),
              contentPadding: const EdgeInsets.symmetric(vertical: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton(String text, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
        ),
        boxShadow: [
          BoxShadow(
            color: _primaryAccent.withOpacity(0.4),
            offset: const Offset(0, 10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Center(
            child: Text(
              text.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
