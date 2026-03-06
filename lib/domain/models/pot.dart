class Pot {
  final String id;
  final String profileId;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String icon;
  final String color;

  Pot({
    required this.id,
    required this.profileId,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'icon': icon,
      'color': color,
    };
  }

  factory Pot.fromMap(Map<String, dynamic> map) {
    return Pot(
      id: map['id'],
      profileId: map['profileId'],
      name: map['name'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'],
      icon: map['icon'],
      color: map['color'],
    );
  }
}
