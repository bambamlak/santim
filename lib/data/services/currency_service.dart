import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class CurrencyService {
  // TODO: Replace with your own FreeCurrencyAPI key for open-source deployment
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _baseUrl = 'https://api.freecurrencyapi.com/v1/latest';

  static final List<String> supportedCurrencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'INR',
    'AED',
    'ETB',
    'SAR',
    'CNY',
  ];

  static Future<void> syncRates({bool force = false}) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final db = await dbHelper.database;

      // Check last sync
      final List<Map<String, dynamic>> lastSync = await db.query(
        'CurrencyRates',
        limit: 1,
      );

      if (lastSync.isNotEmpty && !force) {
        final lastTimestamp = lastSync.first['lastUpdatedTimestamp'] as int;
        final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTimestamp);
        final now = DateTime.now();

        // Sync only once a day
        if (now.difference(lastDate).inHours < 24) {
          debugPrint(
            'Currency rates sync skipped: last sync was ${now.difference(lastDate).inHours}h ago',
          );
          return;
        }
      }

      debugPrint('Syncing currency rates...');
      final url = Uri.parse('$_baseUrl?apikey=$_apiKey');

      final response = await http.get(url);
      debugPrint('Currency API status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> rates = data['data'];

        debugPrint('Received rates: $rates');

        final batch = db.batch();
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        for (var entry in rates.entries) {
          // Ensure rate is stored as a double
          final double rateValue = (entry.value is int)
              ? (entry.value as int).toDouble()
              : (entry.value as num).toDouble();

          batch.insert('CurrencyRates', {
            'baseCurrency': 'USD',
            'targetCurrency': entry.key,
            'rate': rateValue,
            'lastUpdatedTimestamp': timestamp,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit();
        debugPrint(
          'Currency rates synced successfully (${rates.length} rates)',
        );
      } else {
        debugPrint('Failed to sync currency rates: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
      }
    } catch (e, stack) {
      debugPrint('Error syncing currency rates: $e');
      debugPrint('Stack: $stack');
    }
  }

  static Future<double> getRate(String from, String to) async {
    if (from == to) return 1.0;

    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    final results = await db.query(
      'CurrencyRates',
      where: 'baseCurrency = ?',
      whereArgs: ['USD'],
    );

    if (results.isEmpty) {
      debugPrint('No currency rates in database — syncing now...');
      await syncRates(force: true);
      // Re-query after sync
      final retryResults = await db.query(
        'CurrencyRates',
        where: 'baseCurrency = ?',
        whereArgs: ['USD'],
      );
      if (retryResults.isEmpty) {
        debugPrint('Still no rates after sync, returning 1.0');
        return 1.0;
      }
      return _calculateRate(from, to, retryResults);
    }

    return _calculateRate(from, to, results);
  }

  static double _calculateRate(
    String from,
    String to,
    List<Map<String, dynamic>> results,
  ) {
    double? fromRate;
    double? toRate;

    for (var row in results) {
      final target = row['targetCurrency'] as String;
      // Handle both int and double from SQLite
      final rate = (row['rate'] as num).toDouble();

      if (target == from) fromRate = rate;
      if (target == to) toRate = rate;
    }

    // USD is the base, rate is always 1.0
    if (from == 'USD') fromRate = 1.0;
    if (to == 'USD') toRate = 1.0;

    // Fallbacks for currencies if not in API response
    if (from == 'ETB') fromRate ??= 120.0;
    if (to == 'ETB') toRate ??= 120.0;
    if (from == 'AED') fromRate ??= 3.67;
    if (to == 'AED') toRate ??= 3.67;
    if (from == 'SAR') fromRate ??= 3.75;
    if (to == 'SAR') toRate ??= 3.75;

    if (fromRate == null || toRate == null) {
      debugPrint('Missing rate: from=$from ($fromRate), to=$to ($toRate)');
      return 1.0;
    }

    final result = toRate / fromRate;
    debugPrint('Rate $from->$to: $result (fromRate=$fromRate, toRate=$toRate)');
    return result;
  }
}
