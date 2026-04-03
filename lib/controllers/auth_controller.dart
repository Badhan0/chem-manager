import 'dart:convert';
import 'package:chem_manager/services/api_service.dart';
import 'package:chem_manager/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthController {
  
  // Singleton pattern optional if needed, but for simplicity we will use instance methods
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  String? get currentUserEmail => null; // We can't access non-static sharedprefs synchronously.

  Future<Map<String, dynamic>> login(String email, String password, {String? fcmToken}) async {
    try {
      // Fetch FCM token if not provided
      if (fcmToken == null) {
        try {
          fcmToken = await FirebaseMessaging.instance.getToken();
        } catch (e) {
          print("FCM Token Error: $e");
        }
      }

      final response = await ApiService.post('/users/login', {
        'email': email,
        'password': password,
        'fcmToken': fcmToken,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save Token and User Data
        await _saveUser(data);
        return {'success': true, 'message': 'Login successful', 'data': data};
      } else if (response.statusCode == 403) {
        // Not Verified
        return {'success': false, 'message': 'Email not verified', 'error': 'not_verified', 'email': email};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
    try {
      final response = await ApiService.post('/users/signup', userData);

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'], 'email': data['email']};
      } else {
        final error = jsonDecode(response.body);
        if (response.statusCode == 200 && error['message'].contains("resend")) {
           return {'success': true, 'message': error['message'], 'email': error['email']};
        }
        return {'success': false, 'message': error['message'] ?? 'Signup failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      final response = await ApiService.post('/users/verify-otp', {
        'email': email,
        'otp': otp,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUser(data);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Verification failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> resendOtp(String email) async {
    try {
      final response = await ApiService.post('/users/resend-otp', {
        'email': email,
      });

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'OTP resent successfully'};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Resend failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> googleLogin() async {
    try {
      // Force account picker by signing out first
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'success': false, 'message': 'Cancelled'};

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final tempCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(tempCredential);
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) return {'success': false, 'message': 'Failed to get ID Token'};

      // Get FCM Token
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        print("FCM Token Error: $e");
      }

      // Send to Backend
      final response = await ApiService.post('/users/login', {
        'idToken': idToken,
        'email': userCredential.user?.email,
        'photoURL': userCredential.user?.photoURL,
        'fcmToken': fcmToken,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveUser(data);
        return {'success': true, 'message': 'Google Login successful', 'data': data};
      } else if (response.statusCode == 404) {
         // User not found -> Redirect to Signup completion
         return {
           'success': false, 
           'message': 'Account not found. Please Sign Up.', 
           'error': 'not_found',
           'email': userCredential.user?.email,
           'name': userCredential.user?.displayName,
           'firebaseUid': userCredential.user?.uid,
           'photoURL': userCredential.user?.photoURL,
         };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Google Login failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Google Sign-In Error: $e'};
    }
  }

  Future<void> _saveUser(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data['token'] != null) await prefs.setString('auth_token', data['token']);
    if (data['email'] != null) await prefs.setString('user_email', data['email']);
    if (data['name'] != null) await prefs.setString('user_name', data['name']);
    if (data['category'] != null) await prefs.setString('user_category', data['category']);
    if (data['_id'] != null) await prefs.setString('user_id', data['_id']);
    
    await prefs.setBool('isLoggedIn', true);
  }

  Future<Map<String, dynamic>> fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return {'success': false, 'message': 'User ID not found'};

      final response = await ApiService.get('/users/$userId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // data is the user object directly
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Failed to fetch profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return {'success': false, 'message': 'User ID not found'};

      final response = await ApiService.patch('/users/$userId', updates);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Optionally update local cache if needed
        return {'success': true, 'message': 'Profile updated successfully', 'data': data};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Update failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Backwards compatibility if needed, but likely unused internally now
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setBool('isLoggedIn', true);
  }

  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await _googleSignIn.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
