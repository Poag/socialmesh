// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025-2026 gotnull (developer@socialmesh.app)

// The Mesh Beacon notification toggle persists through SettingsService and
// defaults to on, matching the channel and direct message toggles it sits
// beside.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmesh/services/storage/storage_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults to enabled', () async {
    final s = SettingsService();
    await s.init();
    expect(s.meshBeaconNotificationsEnabled, isTrue);
  });

  test('a disabled toggle round-trips across instances', () async {
    final a = SettingsService();
    await a.init();
    await a.setMeshBeaconNotificationsEnabled(false);

    final b = SettingsService();
    await b.init();
    expect(b.meshBeaconNotificationsEnabled, isFalse);
  });
}
