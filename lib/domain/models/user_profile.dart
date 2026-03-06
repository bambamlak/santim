class UserProfile {
  final String id;
  final String name;
  final String avatarSeed;
  final String defaultCurrency;
  final String languagePreference;

  UserProfile({
    required this.id,
    required this.name,
    required this.avatarSeed,
    this.defaultCurrency = 'ETB',
    this.languagePreference = 'en',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'avatarSeed': avatarSeed,
      'defaultCurrency': defaultCurrency,
      'languagePreference': languagePreference,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      avatarSeed: map['avatarSeed'] ?? 'default',
      defaultCurrency: map['defaultCurrency'],
      languagePreference: map['languagePreference'],
    );
  }
}
