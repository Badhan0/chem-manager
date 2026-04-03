import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:chem_manager/login_page.dart'; 
import 'package:chem_manager/home_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chem_manager/services/location_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // Navigation Timer
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Request Location Permission on first open
    LocationService.requestPermission();

    // Navigate logic
    _timer = Timer(const Duration(seconds: 4), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
       Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 1000),
          pageBuilder: (_, __, ___) => const LoginPage(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Light Theme Colors
    const Color primaryColor = Color(0xFF6C63FF);
    const Color accentColor = Color(0xFF2196F3);
    const Color backgroundColor = Color(0xFFF0F0F3);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Background Grid / Tech pattern (Subtle)
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(color: Colors.grey.withOpacity(0.05)),
            ),
          ),

          // 2. Central Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 3D Medical Cross Animation
                const SizedBox(
                  height: 300,
                  width: 300,
                  child: Medical3DObject(),
                ),

                const SizedBox(height: 50),

                // App Title
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [primaryColor, accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: const Text(
                    'CLINI SYNC',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .moveY(begin: 20, end: 0, curve: Curves.easeOutBack),

                const SizedBox(height: 12),

                // Subtitle / Catchphrase
                Text(
                  'Expert Care, Synchronized.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5),

                const SizedBox(height: 60),

                // ECG Heartbeat Loader
                SizedBox(
                  width: 120,
                  height: 40,
                  child: CustomPaint(
                    painter: ECGLoaderPainter(color: accentColor),
                  ),
                ).animate().fadeIn(delay: 1000.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3D Medical Cross Widget & Painter
// ---------------------------------------------------------------------------
class Medical3DObject extends StatefulWidget {
  const Medical3DObject({super.key});

  @override
  State<Medical3DObject> createState() => _Medical3DObjectState();
}

class _Medical3DObjectState extends State<Medical3DObject> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: MedicalCrossPainter(_controller.value),
        );
      },
    );
  }
}

class MedicalCrossPainter extends CustomPainter {
  final double animationValue;
  MedicalCrossPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = vector.Vector3(size.width / 2, size.height / 2, 0);
    final double scale = size.width * 0.25;

    // Define 3D Cross Vertices (12 points for front face, 12 for back)
    // A standard "Plus" shape. center is (0,0).
    // Thickness = 0.4
    // Arm width = 0.4 (approx)
    // Arm length = 1.0
    
    // We construct distinct faces for sorting.
    // Faces: Front Cross, Back Cross, 12 side rectangles.
    
    // Basic Geometry
    const double armL = 1.0; // Total length from center to edge
    const double armW = 0.35; // Half-width of arm
    const double thick = 0.3; // Half-thickness

    // Vertices of the Front Face (Z = +thick)
    // Ordered counter-clockwise
    final List<vector.Vector3> frontVerts = [
      vector.Vector3(armW, armW, thick),   // 0 Inner corner
      vector.Vector3(armL, armW, thick),   // 1 Right Top
      vector.Vector3(armL, -armW, thick),  // 2 Right Bottom
      vector.Vector3(armW, -armW, thick),  // 3 Inner corner
      vector.Vector3(armW, -armL, thick),  // 4 Bottom Right
      vector.Vector3(-armW, -armL, thick), // 5 Bottom Left
      vector.Vector3(-armW, -armW, thick), // 6 Inner corner
      vector.Vector3(-armL, -armW, thick), // 7 Left Bottom
      vector.Vector3(-armL, armW, thick),  // 8 Left Top
      vector.Vector3(-armW, armW, thick),  // 9 Inner corner
      vector.Vector3(-armW, armL, thick),  // 10 Top Left
      vector.Vector3(armW, armL, thick),   // 11 Top Right
    ];

    final List<vector.Vector3> backVerts = frontVerts.map((v) => vector.Vector3(v.x, v.y, -thick)).toList();

    // Rotation Matrices
    final double angleX = animationValue * 2 * math.pi;
    final double angleY = animationValue * math.pi; // Slower rotation on Y to show shape
    final double angleZ = animationValue * 0.5 * math.pi; // Tumble

    // We want a nice pleasing tumble, not chaotic.
    // Just Rotate Y and X slightly.
    final rotation = vector.Matrix4.identity()
      ..rotateY(animationValue * 2 * math.pi)
      ..rotateX(math.sin(animationValue * 2 * math.pi) * 0.5)
      ..rotateZ(math.cos(animationValue * 2 * math.pi) * 0.2);

    // Transform Logic
    vector.Vector3 transform(vector.Vector3 v) {
      final v4 = vector.Vector4(v.x, v.y, v.z, 1.0);
      final rotated = rotation * v4;
      return vector.Vector3(rotated.x, rotated.y, rotated.z);
    }

    final List<Face> faces = [];

    // 1. Front Face
    faces.add(Face(
      verts: frontVerts.map(transform).toList(),
      baseColor: const Color(0xFF6C63FF),
    ));

    // 2. Back Face (Reverse order for normal calculation or just color darker)
    faces.add(Face(
      verts: backVerts.reversed.map(transform).toList(),
      baseColor: const Color(0xFF4A44AA),
    ));

    // 3. Side Faces (12 Rectangles)
    // Connect Front[i] to Front[next], Back[next], Back[i]
    for (int i = 0; i < 12; i++) {
        int next = (i + 1) % 12;
        faces.add(Face(
            verts: [
                transform(frontVerts[i]),
                transform(frontVerts[next]),
                transform(backVerts[next]),
                transform(backVerts[i]),
            ],
            baseColor: const Color(0xFF5951D6), // Side color
        ));
    }

    // Z-Sort (Painter's Algorithm)
    // Calculate average Z for each face
    for (var f in faces) {
        double zSum = 0;
        for (var v in f.verts) zSum += v.z;
        f.avgZ = zSum / f.verts.length;
    }
    // Sort: Smallest Z (back) to Largest Z (front)
    faces.sort((a, b) => a.avgZ.compareTo(b.avgZ));

    // Draw
    for (var face in faces) {
        final path = Path();
        // Project to 2D
        // Simple Orthographic: x * scale + center, y * scale + center
        // Basic Perspective: x / (z + camera)
        
        // We add a 'bobbing' effect to the whole object
        double bob = math.sin(animationValue * 4 * math.pi) * 20;
        Offset offset = Offset(center.x, center.y + bob);

        Offset project(vector.Vector3 v) {
            return Offset(
                offset.dx + v.x * scale,
                offset.dy + v.y * scale
            );
        }

        path.moveTo(project(face.verts[0]).dx, project(face.verts[0]).dy);
        for (int i = 1; i < face.verts.length; i++) {
            path.lineTo(project(face.verts[i]).dx, project(face.verts[i]).dy);
        }
        path.close();

        // Lighting/Shading
        // Calculate Normal vector of the face to change brightness
        // Normal = Cross Product of (v1-v0) and (v2-v0)
        final v0 = face.verts[0];
        final v1 = face.verts[1];
        final v2 = face.verts[2];
        final edge1 = v1 - v0;
        final edge2 = v2 - v0;
        final normal = edge1.cross(edge2).normalized();
        
        // Light direction (Top Left Front)
        final lightDir = vector.Vector3(0.5, -0.5, 1.0).normalized();
        
        // Dot product -> Intensity (-1 to 1)
        double intensity = normal.dot(lightDir);
        // Clamp 0.3 to 1.0
        double brightness = 0.5 + (intensity * 0.5); 
        brightness = brightness.clamp(0.4, 1.0);

        final Paint paint = Paint()
            ..color = _adjustColor(face.baseColor, brightness)
            ..style = PaintingStyle.fill;
            
        // Stroke to define edges
        final Paint stroke = Paint()
            ..color = Colors.white.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;

        canvas.drawPath(path, paint);
        canvas.drawPath(path, stroke);
    }
    
    // Draw Shadow on 'floor'
    final shadowScale = 1.0 - (math.sin(animationValue * 4 * math.pi) * 0.1); // Smaller when high
    canvas.drawOval(
        Rect.fromCenter(center: Offset(center.x, center.y + 150), width: 100 * shadowScale, height: 20 * shadowScale), 
        Paint()..color = Colors.black.withOpacity(0.1)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
    );
  }

  Color _adjustColor(Color color, double factor) {
      // Simple darkening/lightening
      int r = (color.red * factor).toInt().clamp(0, 255);
      int g = (color.green * factor).toInt().clamp(0, 255);
      int b = (color.blue * factor).toInt().clamp(0, 255);
      return Color.fromARGB(color.alpha, r, g, b);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Face {
    List<vector.Vector3> verts;
    Color baseColor;
    double avgZ = 0;
    Face({required this.verts, required this.baseColor});
}


class GridPainter extends CustomPainter {
  final Color color;
  GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    
    const double spacing = 40;
    
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ECGLoaderPainter extends CustomPainter {
  final Color color;
  ECGLoaderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Determine progress based on time, but CustomPainter statless here implies static?
    // User wants animation. We can use built in shimmer or just a static nice path.
    // Let's draw a nice static ECG path and the parent Animate() shimmers it.
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    double w = size.width;
    double h = size.height;
    double mid = h / 2;

    path.moveTo(0, mid);
    path.lineTo(w * 0.2, mid);
    path.lineTo(w * 0.3, mid - 10);
    path.lineTo(w * 0.35, mid + 10);
    path.lineTo(w * 0.45, mid - 25); // Peak
    path.lineTo(w * 0.55, mid + 20); // Trough
    path.lineTo(w * 0.65, mid);
    path.lineTo(w * 0.75, mid + 8);
    path.lineTo(w * 0.8, mid);
    path.lineTo(w, mid);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
