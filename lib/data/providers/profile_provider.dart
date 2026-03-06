import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_profile.dart';
import 'financial_provider.dart';

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    final profileId = ref.watch(currentProfileIdProvider);

    final List<Map<String, dynamic>> maps = await db.query(
      'UserProfile',
      where: 'id = ?',
      whereArgs: [profileId],
    );

    if (maps.isEmpty) {
      return null;
    }
    return UserProfile.fromMap(maps.first);
  }

  Future<void> createUserProfile(String name, String avatarSeed) async {
    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;
    final profileId = ref.read(currentProfileIdProvider);

    final profile = UserProfile(
      id: profileId,
      name: name,
      avatarSeed: avatarSeed,
    );

    await db.insert('UserProfile', profile.toMap());
    ref.invalidateSelf();
  }

  Future<void> updateProfile({String? name, String? avatarSeed}) async {
    final stateData = state.value;
    if (stateData == null) return;

    final updatedProfile = UserProfile(
      id: stateData.id,
      name: name ?? stateData.name,
      avatarSeed: avatarSeed ?? stateData.avatarSeed,
      defaultCurrency: stateData.defaultCurrency,
      languagePreference: stateData.languagePreference,
    );

    final dbHelper = ref.read(databaseHelperProvider);
    final db = await dbHelper.database;

    await db.update(
      'UserProfile',
      updatedProfile.toMap(),
      where: 'id = ?',
      whereArgs: [updatedProfile.id],
    );

    ref.invalidateSelf();
  }

  Future<void> updateAvatar(String seed) async {
    await updateProfile(avatarSeed: seed);
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(() {
      return UserProfileNotifier();
    });
