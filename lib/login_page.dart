import 'package:chem_manager/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'profile_page.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static final AuthController _authController = AuthController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  // Neumorphic design parameters matching screenshot
  static const Color _backgroundColor = Color(0xFFE6EBF5); // Lighter blue-grey
  static const Color _primaryAccent = Color(0xFF3B82F6); // Bright Blue
  static const Color _textColor = Color(0xFF475569); // Slate 600
  static const Color _labelColor = Color(0xFF94A3B8); // Slate 400

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

  static final BoxShadow _insetLightShadow = BoxShadow(
    color: Colors.white,
    offset: const Offset(3, 3), 
    blurRadius: 5,
    spreadRadius: -2,
  );
  
  Widget _buildInsetField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
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
                hintText: isPassword ? '••••••••' : 'example@gmail.com',
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
        borderRadius: BorderRadius.circular(30),
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
            Color(0xFF60A5FA), // Lighter Blue
            Color(0xFF2563EB), // Darker Blue
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Center(
            child: Text(
              text.toUpperCase(),
              style: TextStyle(
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

  Widget _buildGoogleButton(BuildContext context) {
    return Column(
      children: [
        Text(
          'QUICK SIGN IN',
          style: TextStyle(
            color: _labelColor,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 15),
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [_darkShadow, _lightShadow],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _signInWithGoogle(context),
              child: Padding(
                 padding: EdgeInsets.all(18),
                 child: Image.asset('assets/images/google.ico'), 
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
      body: SafeArea(
        child: SingleChildScrollView( 
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                
                 // 3D Style Logo Container
                Container(
                  height: 100,
                  width: 100,
                  margin: EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white,
                        offset: Offset(-5, -5),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Color(0xFFC1C9D8),
                        offset: Offset(5, 5),
                        blurRadius: 15,
                        spreadRadius: 1,
                      ),
                    ],
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.8),
                        _backgroundColor,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Image.asset('assets/images/logo.png', fit: BoxFit.contain), 
                  ),
                ),

                // Heading
                Text(
                  'Clini Sync',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B), // Dark Grid Color
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Connecting The Medical World',
                  style: TextStyle(
                    fontSize: 16,
                    color: _labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        
                SizedBox(height: 50),
        
                // Inputs
                _buildInsetField(
                  controller: _emailController,
                  label: 'Email ID',
                  icon: Icons.email,
                ),
                SizedBox(height: 25),
                _buildInsetField(
                  controller: _passwordController,
                  label: 'Secure Phrase',
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
        
                SizedBox(height: 40),
        
                // "Biometric" Replacement -> Google Sign In
                _buildGoogleButton(context),
        
                SizedBox(height: 40),
        
                // Main Button
                _buildMainButton(
                  text: 'Authorize',
                  onPressed: () async {
                    final result = await _authController.login(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                    );
                    
                    if (result['success']) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const HomePage()),
                      );
                    } else {
                      _showErrorDialog(context, result['message']);
                    }
                  },
                ),
        
                SizedBox(height: 30),
        
                // Forgot Password
                TextButton(
                  onPressed: () => _showResetPasswordDialog(context),
                  child: Text(
                    'RESET CREDENTIALS',
                    style: TextStyle(
                      color: _labelColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
        
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'New Clinic? ',
                      style: TextStyle(color: _labelColor),
                    ),
                    InkWell(
                      onTap: () => Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const SignupPage()),
                          (route) => false,
                        ),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          color: _primaryAccent,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 50),
        
                // Footer
                 Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white,
                        offset: Offset(-2, -2),
                        blurRadius: 5,
                      ),
                      BoxShadow(
                        color: Color(0xFFC1C9D8), // Darker shadow
                        offset: Offset(2, 2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hub, color: _primaryAccent, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'CLINI SYNC PROFESSIONAL NETWORK',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
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

  Future<void> _signInWithGoogle(BuildContext context) async {
    final result = await _authController.googleLogin();

    if (result['success']) {
       // Navigate to the home page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (result['error'] == 'not_found') {
       // Redirect to Signup with pre-filled data
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignupPage(
            kEmail: result['email'],
            kName: result['name'],
            kFirebaseUid: result['firebaseUid'],
            kPhotoURL: result['photoURL'],
          ),
        ),
      );
    } else {
      _showErrorDialog(context, result['message']);
    }
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

  void _showResetPasswordDialog(BuildContext context) {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
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
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInsetField(
                    controller: emailController,
                    label: 'Registered Email',
                    icon: Icons.email,
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Using TextButton instead of _buildNeumorphicButton to fit new style
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: _primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                                email: emailController.text.trim());
                            Navigator.pop(context);
                            _showSuccessDialog(context,
                                'Password reset email sent. Check your inbox.');
                          } on FirebaseAuthException catch (e) {
                            Navigator.pop(context);
                            _showErrorDialog(context,
                                'Failed to send reset email: ${e.message}');
                          }
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            color: _primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Center(
                  child: Text(
                    'About Clini Sync',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _primaryAccent,
                    ),
                  ),
                ),
                // ... (Rest of About Dialog implementation adapted to use correct colors if needed)
                const SizedBox(height: 20),
                 Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: _primaryAccent,
                        fontWeight: FontWeight.bold,
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

  Future<void> _launchUrl(String url) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }
}
