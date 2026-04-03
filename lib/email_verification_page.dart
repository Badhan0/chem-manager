import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'dart:async';

class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  _EmailVerificationPageState createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  bool _isVerified = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _checkEmailVerified();

    // Check email verification status every 3 seconds
    _timer = Timer.periodic(
        const Duration(seconds: 3), (_) => _checkEmailVerified());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerified() async {
    try {
      await _user.reload();
      final user = _auth.currentUser;
      if (user != null && user.emailVerified) {
        _timer?.cancel();
        setState(() {
          _isVerified = true;
        });
        // Navigate to home page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Error checking verification status: ${e.toString()}')),
      );
    }
  }

  Future<void> _resendVerificationEmail() async {
    try {
      await _user.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Verification email sent. Please check your inbox.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Failed to send verification email: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('A verification email has been sent to your email.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isVerified ? null : _resendVerificationEmail,
              child: const Text('Resend Verification Email'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkEmailVerified,
              child: const Text('I have verified my email'),
            ),
          ],
        ),
      ),
    );
  }
}
