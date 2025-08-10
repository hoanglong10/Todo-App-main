class Profile {
  final int? id;
  final String name;
  final String email;
  final String? bio;
  final String? avatarPath; // đường dẫn file ảnh trong máy

  Profile({
    this.id,
    required this.name,
    required this.email,
    this.bio,
    this.avatarPath,
  });

  Profile copyWith({
    int? id,
    String? name,
    String? email,
    String? bio,
    String? avatarPath,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  factory Profile.fromMap(Map<String, dynamic> map) => Profile(
    id: map['id'] as int?,
    name: map['name'] as String,
    email: map['email'] as String,
    bio: map['bio'] as String?,
    avatarPath: map['avatar_path'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'bio': bio,
    'avatar_path': avatarPath,
  };
}
