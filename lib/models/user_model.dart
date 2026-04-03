class User {
  final String? id;
  final String email;
  final String name;
  final String category;
  final String? token;
  final bool isEmailVerified;
  final String? userId;
  final String? doctorAuthNumber;
  final String? gstinNumber;
  final String? aadharNumber;
  final String? specialization;
  final List<String>? connections;
  final String? photoURL;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.category,
    this.token,
    this.isEmailVerified = false,
    this.userId,
    this.doctorAuthNumber,
    this.gstinNumber,
    this.aadharNumber,
    this.specialization,
    this.connections,
    this.photoURL,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      email: json['email'],
      name: json['name'],
      category: json['category'],
      token: json['token'],
      isEmailVerified: json['isEmailVerified'] ?? false,
      userId: json['userId'],
      doctorAuthNumber: json['doctorAuthNumber'],
      gstinNumber: json['gstinNumber'],
      aadharNumber: json['aadharNumber'],
      specialization: json['specialization'],
      connections: json['connections'] != null 
          ? List<String>.from(json['connections'].map((x) => x.toString()))
          : [],
      photoURL: json['photoURL'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'name': name,
      'category': category,
      'token': token,
      'isEmailVerified': isEmailVerified,
      'userId': userId,
      'doctorAuthNumber': doctorAuthNumber,
      'gstinNumber': gstinNumber,
      'aadharNumber': aadharNumber,
      'specialization': specialization,
      'connections': connections,
      'photoURL': photoURL,
    };
  }
}
