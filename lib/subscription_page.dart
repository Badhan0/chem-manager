import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chem_manager/services/api_service.dart';
import 'dart:convert';
import 'home_page.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _isLoading = false;
  
  String _status = 'trial'; // 'trial', 'active', 'expired'
  String _plan = 'trial'; // 'trial', 'basic', 'premium'
  int _remainingDays = 0;
  String _expiryDateStr = '';

  @override
  void initState() {
    super.initState();
    _fetchSubscriptionStatus();
  }

  Future<void> _fetchSubscriptionStatus() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final response = await ApiService.get('/users/subscription-status/$userId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _status = data['subscriptionStatus'] ?? 'trial';
          _plan = data['subscriptionPlan'] ?? 'trial';
          _remainingDays = data['remainingDays'] ?? 0;
          
          if (data['subscriptionExpiry'] != null) {
            try {
              final parsed = DateTime.parse(data['subscriptionExpiry']);
              _expiryDateStr = "${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}";
            } catch (_) {}
          } else {
            _expiryDateStr = '';
          }
        });
      }
    } catch (e) {
      print('Error fetching subscription status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _upgradePlan(String targetPlan, double cost) async {
    // Show confirmation dialog simulating payment
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFE6EBF5),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: HomePage.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.payment_rounded, color: HomePage.primaryColor, size: 36),
              ),
              const SizedBox(height: 20),
              const Text(
                'Razorpay Checkout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Confirm payment of ₹$cost/month to subscribe to the ${targetPlan.toUpperCase()} Plan. This will enable immediate access to all associated features.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HomePage.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'PAY NOW',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
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

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) return;

      final response = await ApiService.post('/users/upgrade-subscription', {
        'userId': userId,
        'plan': targetPlan,
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully upgraded to ${targetPlan.toUpperCase()}!'),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchSubscriptionStatus();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to complete subscription upgrade.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6EBF5),
      appBar: AppBar(
        title: const Text(
          'Subscription & Billing',
          style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE6EBF5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF3B82F6)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 30),
                  const Text(
                    'Available Membership Plans',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildPlanCard(
                    planName: 'Basic Plan',
                    planCode: 'basic',
                    price: '₹299/mo',
                    priceVal: 299.0,
                    features: [
                      'Standard Appointment Booking',
                      'Access to Patients Directory',
                      'Payout settlement settings',
                      'Regular Email notifications',
                    ],
                    icon: Icons.medical_services_outlined,
                  ),
                  const SizedBox(height: 20),
                  _buildPlanCard(
                    planName: 'Premium Plan',
                    planCode: 'premium',
                    price: '₹999/mo',
                    priceVal: 999.0,
                    features: [
                      'Everything in Basic Plan',
                      'Direct Razorpay Split-routed payments',
                      'Detailed Analytics & Revenue Reports',
                      'Priority clinic listing on patient search',
                      '24/7 Live support callback hotline',
                    ],
                    icon: Icons.workspace_premium_outlined,
                    isPopular: true,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    Color cardColor;
    IconData icon;
    String titleText = '';
    List<Color> gradientColors;
    String badgeText = '';
    
    // Total duration is 30 days for trial
    double progress = 1.0;
    if (_status == 'trial') {
      progress = _remainingDays / 30.0;
      if (progress > 1.0) progress = 1.0;
      if (progress < 0.0) progress = 0.0;
    }

    if (_status == 'expired') {
      gradientColors = [const Color(0xFFEF4444), const Color(0xFF991B1B)]; // Dark Red gradient
      icon = Icons.error_outline_rounded;
      titleText = 'Access Expired';
      badgeText = 'EXPIRED';
    } else if (_status == 'active') {
      if (_plan == 'premium') {
        gradientColors = [const Color(0xFF6366F1), const Color(0xFFD946EF)]; // Purple-Pink premium gradient
      } else {
        gradientColors = [const Color(0xFF2563EB), const Color(0xFF3B82F6)]; // Electric Blue gradient
      }
      icon = Icons.verified_user_rounded;
      titleText = '${_plan.toUpperCase()} MEMBERSHIP';
      badgeText = 'ACTIVE';
    } else {
      gradientColors = [const Color(0xFF0F172A), const Color(0xFF1E293B)]; // Slate gradient
      icon = Icons.hourglass_top_rounded;
      titleText = 'Free Trial Mode';
      badgeText = 'TRIAL';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative background bubbles
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            titleText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _status == 'expired'
                              ? Colors.black.withOpacity(0.3)
                              : Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_status == 'trial') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trial Progress',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$_remainingDays of 30 days left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ] else if (_status == 'active') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'VALUED MEMBER SINCE',
                              style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateTime.now().year.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'EXPIRY DATE',
                              style: TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _expiryDateStr,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    )
                  ] else ...[
                    Text(
                      'Your access has expired. Please subscribe to one of our premium plans below to continue managing bookings.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _status == 'expired' ? 'No Active Subscription' : 'Auto-renews: Enabled',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'Secure Checkout via Razorpay',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String planName,
    required String planCode,
    required String price,
    required double priceVal,
    required List<String> features,
    required IconData icon,
    bool isPopular = false,
  }) {
    final bool isCurrentPlan = _plan == planCode && _status == 'active';
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE6EBF5),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          // Neumorphic double shadow
          BoxShadow(
            color: const Color(0xFFC1C9D8),
            offset: const Offset(6, 6),
            blurRadius: 12,
          ),
          const BoxShadow(
            color: Colors.white,
            offset: Offset(-6, -6),
            blurRadius: 12,
          ),
        ],
        border: isPopular 
          ? Border.all(color: HomePage.primaryColor.withOpacity(0.7), width: 2) 
          : Border.all(color: Colors.transparent, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            if (isPopular)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: HomePage.primaryColor,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: HomePage.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: HomePage.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            planName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          if (isCurrentPlan)
                            Text(
                              'Your Active Plan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    textBaseline: TextBaseline.alphabetic,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    children: [
                      Text(
                        price.split('/').first,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: HomePage.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/' + price.split('/').last,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 16),
                  Column(
                    children: features
                        .map((f) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDCFCE7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 12),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      f,
                                      style: const TextStyle(
                                        color: Color(0xFF475569), 
                                        fontSize: 13,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isCurrentPlan
                            ? null
                            : [
                                BoxShadow(
                                  color: HomePage.primaryColor.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: ElevatedButton(
                        onPressed: isCurrentPlan ? null : () => _upgradePlan(planCode, priceVal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCurrentPlan 
                            ? const Color(0xFFCBD5E1) 
                            : HomePage.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFCBD5E1),
                          disabledForegroundColor: const Color(0xFF64748B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          isCurrentPlan ? 'CURRENT ACTIVE PLAN' : 'UPGRADE NOW',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
