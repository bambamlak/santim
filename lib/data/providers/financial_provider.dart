import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../services/currency_service.dart';
import '../../domain/models/transaction.dart' as t;
import '../../domain/models/pot.dart';
import '../../domain/models/budget.dart';
import 'package:sqflite/sqflite.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

class CurrentProfileIdNotifier extends Notifier<String> {
  @override
  String build() => 'default_profile';
  void update(String newId) => state = newId;
}

final currentProfileIdProvider =
    NotifierProvider<CurrentProfileIdNotifier, String>(
      () => CurrentProfileIdNotifier(),
    );

class FinancialState {
  final double totalBalance;
  final double upcomingExpenses;
  /// Saving Jar (reserve type) allocations — "untouchable" locked funds
  final double savingJarAllocations;
  /// Budget Jar (envelope type) remaining amounts — reserved for specific tasks
  final double budgetJarRemaining;
  final double pendingTransactions;
  final double safeToSpend;
  final double dailyAllowance;
  final List<t.Transaction> recentTransactions;
  final List<t.Transaction> allTransactions;
  final List<Pot> pots;
  final List<Budget> budgets;
  /// End-of-day balance map: key = day-of-month (0 = start), value = balance
  final Map<int, double> dailyBalances;

  FinancialState({
    required this.totalBalance,
    required this.upcomingExpenses,
    required this.savingJarAllocations,
    required this.budgetJarRemaining,
    required this.pendingTransactions,
    required this.safeToSpend,
    required this.dailyAllowance,
    required this.recentTransactions,
    required this.allTransactions,
    required this.pots,
    required this.budgets,
    required this.dailyBalances,
  });

  // Legacy getter so existing code that reads potAllocations still compiles
  double get potAllocations => savingJarAllocations;

  factory FinancialState.empty() => FinancialState(
    totalBalance: 0,
    upcomingExpenses: 0,
    savingJarAllocations: 0,
    budgetJarRemaining: 0,
    pendingTransactions: 0,
    safeToSpend: 0,
    dailyAllowance: 0,
    recentTransactions: [],
    allTransactions: [],
    pots: [],
    budgets: [],
    dailyBalances: {},
  );
}

class FinancialNotifier extends AsyncNotifier<FinancialState> {
  @override
  Future<FinancialState> build() async => _loadFinancialData();

  Future<FinancialState> _loadFinancialData() async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    final profileId = ref.read(currentProfileIdProvider);

    final results = await Future.wait([
      db.query(
        'Transactions',
        where: 'profileId = ?',
        whereArgs: [profileId],
        orderBy: 'date DESC',
      ),
      db.query('Pots', where: 'profileId = ?', whereArgs: [profileId]),
      db.query('Budgets', where: 'profileId = ?', whereArgs: [profileId]),
    ]);

    final transactions = (results[0] as List<Map<String, dynamic>>)
        .map((e) => t.Transaction.fromMap(e))
        .toList();
    final pots = (results[1] as List<Map<String, dynamic>>)
        .map((e) => Pot.fromMap(e))
        .toList();
    final budgets = (results[2] as List<Map<String, dynamic>>)
        .map((e) => Budget.fromMap(e))
        .toList();

    final now = DateTime.now();

    // ── Step A: Core Balance ──────────────────────────────────────────────────
    double totalBalance = 0;
    double upcomingExpenses = 0;
    double pendingTransactions = 0;

    for (var tx in transactions) {
      if (tx.date.isAfter(now)) {
        if (tx.type == 'expense') upcomingExpenses += tx.amount;
        continue;
      }
      if (tx.isPending) {
        if (tx.type == 'expense') pendingTransactions += tx.amount;
      } else {
        if (tx.type == 'income') {
          totalBalance += tx.amount;
        } else {
          totalBalance -= tx.amount;
        }
      }
    }

    // ── Step B: Saving Jars (reserve type) — "untouchable" ───────────────────
    // Pots in the DB are also saving jars. Budgets of type 'reserve' are too.
    double savingJarAllocations = pots.fold(0.0, (s, p) => s + p.currentAmount);
    for (var budget in budgets) {
      if (budget.type == 'reserve') {
        savingJarAllocations += budget.amountLimit;
      }
    }

    // Available after locking saving jars
    final availableFunds = totalBalance - savingJarAllocations;

    // ── Step C: Budget Jars (envelope type) — remaining allocations ───────────
    double budgetJarRemaining = 0;
    for (var budget in budgets) {
      if (budget.type != 'envelope') continue;
      final spentInCategory = transactions
          .where(
            (tx) =>
                tx.categoryId == budget.categoryId &&
                tx.type == 'expense' &&
                tx.date.year == now.year &&
                tx.date.month == now.month &&
                !tx.date.isAfter(now) &&
                !tx.isPending,
          )
          .fold(0.0, (s, tx) => s + tx.amount);
      final remaining = budget.amountLimit - spentInCategory;
      if (remaining > 0) budgetJarRemaining += remaining;
    }

    // ── Safe To Spend ─────────────────────────────────────────────────────────
    // STS = Btotal − (SavingJars + BudgetJarRemaining)
    final safeToSpend = availableFunds - budgetJarRemaining;

    // ── Daily Allowance ───────────────────────────────────────────────────────
    final dend = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = (dend - now.day) + 1; // include today
    final dailyAllowance = safeToSpend > 0
        ? safeToSpend / daysRemaining
        : 0.0;

    // ── End-of-Day Balances for the Graph ────────────────────────────────────
    // Collect daily changes (income positive, expense negative) for current month
    final Map<int, double> dailyChanges = {};
    for (var tx in transactions) {
      if (tx.date.year == now.year &&
          tx.date.month == now.month &&
          !tx.isPending &&
          !tx.date.isAfter(now)) {
        final day = tx.date.day;
        dailyChanges[day] = (dailyChanges[day] ?? 0) +
            (tx.type == 'income' ? tx.amount : -tx.amount);
      }
    }

    // Build backwards from today → day 1 → day 0 (start of month)
    final Map<int, double> dailyBalances = {};
    double runningBalance = totalBalance;
    for (int d = now.day; d >= 1; d--) {
      dailyBalances[d] = runningBalance;
      runningBalance -= (dailyChanges[d] ?? 0);
    }
    dailyBalances[0] = runningBalance; // balance at start of month

    return FinancialState(
      totalBalance: totalBalance,
      upcomingExpenses: upcomingExpenses,
      savingJarAllocations: savingJarAllocations,
      budgetJarRemaining: budgetJarRemaining,
      pendingTransactions: pendingTransactions,
      safeToSpend: safeToSpend,
      dailyAllowance: dailyAllowance,
      recentTransactions: transactions.take(20).toList(),
      allTransactions: transactions,
      pots: pots,
      budgets: budgets,
      dailyBalances: dailyBalances,
    );
  }

  Future<void> createOrUpdateBudget(
    String categoryId,
    double amountLimit, {
    String? id,
    String? icon,
    String type = 'reserve',
  }) async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    final profileId = ref.read(currentProfileIdProvider);
    final month = DateFormat('yyyy-MM').format(DateTime.now());

    final budget = Budget(
      id: id ?? const Uuid().v4(),
      profileId: profileId,
      categoryId: categoryId,
      amountLimit: amountLimit,
      month: month,
      icon: icon,
      type: type,
    );
    await db.insert(
      'Budgets',
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    ref.invalidateSelf();
  }

  Future<void> deleteBudget(String id) async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    await db.delete('Budgets', where: 'id = ?', whereArgs: [id]);
    ref.invalidateSelf();
  }

  Future<void> addTransaction({
    required double amount,
    required String type,
    String? description,
    required String categoryId,
    required String entryType,
    int? recurrenceInterval,
    String? recurrenceUnit,
    DateTime? date,
    bool isPending = false,
    String? icon,
  }) async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    final profileId = ref.read(currentProfileIdProvider);

    final tx = t.Transaction(
      id: const Uuid().v4(),
      profileId: profileId,
      amount: amount,
      type: type,
      categoryId: categoryId,
      description: description,
      date: date ?? DateTime.now(),
      isPending: isPending,
      entryType: entryType,
      recurrenceInterval: recurrenceInterval,
      recurrenceUnit: recurrenceUnit,
      icon: icon,
    );
    await db.insert('Transactions', tx.toMap());
    ref.invalidateSelf();
  }

  Future<void> updateTransaction(
    String id, {
    required double amount,
    required String type,
    String? description,
    required String categoryId,
    required String entryType,
    int? recurrenceInterval,
    String? recurrenceUnit,
    DateTime? date,
    bool isPending = false,
    String? icon,
  }) async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    final profileId = ref.read(currentProfileIdProvider);

    final tx = t.Transaction(
      id: id,
      profileId: profileId,
      amount: amount,
      type: type,
      categoryId: categoryId,
      description: description,
      date: date ?? DateTime.now(),
      isPending: isPending,
      entryType: entryType,
      recurrenceInterval: recurrenceInterval,
      recurrenceUnit: recurrenceUnit,
      icon: icon,
    );
    await db.update(
      'Transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [id],
    );
    ref.invalidateSelf();
  }

  Future<void> deleteTransaction(String id) async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    await db.delete('Transactions', where: 'id = ?', whereArgs: [id]);
    ref.invalidateSelf();
  }

  Future<void> reinsertTransaction(t.Transaction tx) async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    await db.insert('Transactions', tx.toMap());
    ref.invalidateSelf();
  }

  Future<void> reinsertBudget(Budget budget) async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    await db.insert('Budgets', budget.toMap());
    ref.invalidateSelf();
  }

  Future<void> convertAllValues(String from, String to) async {
    if (from == to) return;
    final rate = await CurrencyService.getRate(from, to);
    if (rate == 1.0) return;
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    await db.execute('UPDATE Transactions SET amount = amount * ?', [rate]);
    await db.execute('UPDATE Budgets SET amountLimit = amountLimit * ?', [rate]);
    await db.execute('UPDATE Pots SET targetAmount = targetAmount * ?, currentAmount = currentAmount * ?', [rate, rate]);
    ref.invalidateSelf();
  }
}

final financialProvider =
    AsyncNotifierProvider<FinancialNotifier, FinancialState>(
      () => FinancialNotifier(),
    );
