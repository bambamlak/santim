class Transaction {
  final String id;
  final String profileId;
  final double amount;
  final String type; // 'income' or 'expense'
  final String categoryId;
  final String? description; // Optional
  final DateTime date;
  final bool isPending;
  final String entryType; // 'default', 'upcoming', 'recurring'
  final int? recurrenceInterval; // Optional (1, 2, 3...)
  final String? recurrenceUnit; // Optional ('day', 'week', 'month')
  final String? icon;

  Transaction({
    required this.id,
    required this.profileId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.description,
    required this.date,
    required this.isPending,
    required this.entryType,
    this.recurrenceInterval,
    this.recurrenceUnit,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'profileId': profileId,
      'amount': amount,
      'type': type,
      'categoryId': categoryId,
      'description': description,
      'date': date.toIso8601String(),
      'isPending': isPending ? 1 : 0,
      'entryType': entryType,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceUnit': recurrenceUnit,
      'icon': icon,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      profileId: map['profileId'],
      amount: map['amount'],
      type: map['type'],
      categoryId: map['categoryId'],
      description: map['description'],
      date: DateTime.parse(map['date']),
      isPending: map['isPending'] == 1,
      entryType: map['entryType'] ?? 'default',
      recurrenceInterval: map['recurrenceInterval'],
      recurrenceUnit: map['recurrenceUnit'],
      icon: map['icon'],
    );
  }
}
