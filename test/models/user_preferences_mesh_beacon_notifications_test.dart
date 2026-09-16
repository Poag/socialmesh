// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025-2026 gotnull (developer@socialmesh.app)

// Pins the `meshBeaconNotificationsEnabled` field on UserPreferences, the
// user-level toggle that silences Mesh Beacon announcements without muting
// the channel they arrive on. The notification gates read it through
// SettingsService; cloud sync carries it through UserProfile.preferences and
// the merge in profile_providers.dart layers remote changes with copyWith.

import 'package:flutter_test/flutter_test.dart';
import 'package:socialmesh/models/user_profile.dart';

void main() {
  group('UserPreferences.meshBeaconNotificationsEnabled', () {
    test('JSON round-trips the field when set', () {
      const prefs = UserPreferences(meshBeaconNotificationsEnabled: false);
      final json = prefs.toJson();
      expect(json['meshBeaconNotificationsEnabled'], isFalse);

      final back = UserPreferences.fromJson(json);
      expect(back.meshBeaconNotificationsEnabled, isFalse);
    });

    test('JSON omits the field when null', () {
      const prefs = UserPreferences();
      expect(
        prefs.toJson().containsKey('meshBeaconNotificationsEnabled'),
        isFalse,
        reason:
            'null preferences are not written, so older clients only see '
            'fields the newer client explicitly set',
      );
    });

    test('copyWith preserves the field when not overridden', () {
      const prefs = UserPreferences(meshBeaconNotificationsEnabled: false);
      final updated = prefs.copyWith(notificationsEnabled: false);
      expect(updated.meshBeaconNotificationsEnabled, isFalse);
      expect(updated.notificationsEnabled, isFalse);
    });

    test('copyWith allows an explicit override', () {
      const prefs = UserPreferences(meshBeaconNotificationsEnabled: true);
      final updated = prefs.copyWith(meshBeaconNotificationsEnabled: false);
      expect(updated.meshBeaconNotificationsEnabled, isFalse);
    });

    test('fromJson without the key leaves the field null', () {
      final back = UserPreferences.fromJson(const {});
      expect(back.meshBeaconNotificationsEnabled, isNull);
    });
  });
}
