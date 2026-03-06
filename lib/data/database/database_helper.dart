import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('meten_budget.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE Transactions ADD COLUMN icon TEXT');
      await db.execute('ALTER TABLE Budgets ADD COLUMN icon TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE UserProfile ADD COLUMN avatarSeed TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE Transactions ADD COLUMN description TEXT');
      await db.execute(
        'ALTER TABLE Transactions ADD COLUMN entryType TEXT DEFAULT "default"',
      );

      // Create Categories table for custom categories
      await db.execute('''
        CREATE TABLE Categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          type TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE Transactions ADD COLUMN recurrenceInterval INTEGER',
      );
      await db.execute(
        'ALTER TABLE Transactions ADD COLUMN recurrenceUnit TEXT',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE Budgets ADD COLUMN type TEXT DEFAULT "reserve"',
      );
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const numType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // User Profile
    await db.execute('''
CREATE TABLE UserProfile (
  id $idType,
  name $textType,
  avatarSeed TEXT,
  defaultCurrency $textType,
  languagePreference $textType
)
''');

    // Transactions
    await db.execute('''
CREATE TABLE Transactions (
  id $idType,
  profileId $textType,
  amount $numType,
  type $textType,
  categoryId $textType,
  description TEXT,
  date $textType,
  isPending $intType,
  entryType $textType,
  recurrenceInterval INTEGER,
  recurrenceUnit TEXT,
  icon TEXT,
  FOREIGN KEY (profileId) REFERENCES UserProfile (id) ON DELETE CASCADE
)
''');

    // Categories Table
    await db.execute('''
CREATE TABLE Categories (
  id $idType,
  name $textType,
  icon $textType,
  color $textType,
  type $textType
)
''');

    // Pots (Envelopes/Savings)
    await db.execute('''
CREATE TABLE Pots (
  id $idType,
  profileId $textType,
  name $textType,
  targetAmount $numType,
  currentAmount $numType,
  icon $textType,
  color $textType,
  FOREIGN KEY (profileId) REFERENCES UserProfile (id) ON DELETE CASCADE
)
''');

    // Budgets
    await db.execute('''
CREATE TABLE Budgets (
  id $idType,
  profileId $textType,
  categoryId $textType,
  amountLimit $numType,
  month $textType,
  icon TEXT,
  type TEXT DEFAULT "reserve",
  FOREIGN KEY (profileId) REFERENCES UserProfile (id) ON DELETE CASCADE
)
''');

    // Currency Rates
    await db.execute('''
CREATE TABLE CurrencyRates (
  baseCurrency TEXT NOT NULL,
  targetCurrency TEXT NOT NULL,
  rate $numType,
  lastUpdatedTimestamp $intType,
  PRIMARY KEY (baseCurrency, targetCurrency)
)
''');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
