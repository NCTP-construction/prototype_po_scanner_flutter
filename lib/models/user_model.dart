class User {
  final String userId;
  final String username;
  final String fullName;

  User({required this.userId, required this.username, required this.fullName});

  // Convert to Map for database or JSON storage
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'full_name': fullName,
  };

  // Create User from Map (useful when retrieving from local storage)
  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json['user_id'],
    username: json['username'],
    fullName: json['full_name'],
  );
}
