class Budget {
  final String id;
  final String profileId;
  final String categoryId;
  final double amountLimit;
  final String month; // format: 'YYYY-MM'
  final String? icon;
  final String type; // 'reserve' (sinking fund) or 'envelope' (zero-based)

  Budget({
    required this.id,
    required this.profileId,
    required this.categoryId,
    required this.amountLimit,
    required this.month,
    this.icon,
    this.type = 'reserve',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'categoryId': categoryId,
      'amountLimit': amountLimit,
      'month': month,
      'icon': icon,
      'type': type,
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map['id'],
      profileId: map['profileId'],
      categoryId: map['categoryId'],
      amountLimit: map['amountLimit'],
      month: map['month'],
      icon: map['icon'],
      type: map['type'] ?? 'reserve',
    );
  }

  Budget copyWith({
    String? id,
    String? profileId,
    String? categoryId,
    double? amountLimit,
    String? month,
    String? icon,
    String? type,
  }) {
    return Budget(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      categoryId: categoryId ?? this.categoryId,
      amountLimit: amountLimit ?? this.amountLimit,
      month: month ?? this.month,
      icon: icon ?? this.icon,
      type: type ?? this.type,
    );
  }
}
