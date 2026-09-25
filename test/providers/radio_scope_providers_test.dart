// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025-2026 gotnull (developer@socialmesh.app)
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socialmesh/core/radio_scope.dart';
import 'package:socialmesh/providers/radio_scope_providers.dart';

void main() {
  late Directory root;
  late ProviderContainer container;

  const home = 0xa6960864; // node-a6960864
  const mobile = 0x6944378a; // node-6944378a
  const third = 0x00001111; // node-00001111

  setUp(() async {
    root = await Directory.systemTemp.createTemp('radio_scope_providers_');
    SharedPreferences.setMockInitialValues({});
    RadioScope.instance.debugSetRoot(root);
    await RadioScope.instance.init();
    container = ProviderContainer();
  });

  tearDown(() async {
    container.dispose();
    RadioScope.instance.debugSetRoot(null);
    if (await root.exists()) await root.delete(recursive: true);
  });

  // The list is built from the scope directories on disk, so a scope only
  // appears once something has been written into it.
  Future<void> bindWithData(int nodeNum, {String? deviceId}) async {
    await RadioScope.instance.useNodeNum(nodeNum, deviceId: deviceId);
    final path = await RadioScope.instance.databasePath('messages.db');
    await File(path).writeAsString('$nodeNum');
  }

  Future<List<RadioScopeInfo>> listScopes() async {
    // A rebuild is scheduled, not synchronous, so the future is read after
    // the stream listeners have run.
    await Future<void>.delayed(Duration.zero);
    return container.read(radioScopeListProvider.future);
  }

  test('the list refetches when the scope changes', () async {
    await bindWithData(home);
    final before = await listScopes();
    expect(before.single.key, 'node-a6960864');
    expect(before.single.isCurrent, isTrue);

    await bindWithData(mobile);
    final after = await listScopes();
    expect(after.firstWhere((s) => s.key == 'node-6944378a').isCurrent, isTrue);
    expect(
      after.firstWhere((s) => s.key == 'node-a6960864').isCurrent,
      isFalse,
    );
  });

  test('the list refetches when the connected radio changes without a scope '
      'change', () async {
    await bindWithData(home);
    await bindWithData(mobile, deviceId: 'ble:mobile');
    await bindWithData(third, deviceId: 'ble:third');
    await RadioScope.instance.shareScope(
      key: 'node-6944378a',
      into: 'node-a6960864',
    );
    await RadioScope.instance.shareScope(
      key: 'node-00001111',
      into: 'node-a6960864',
    );
    await RadioScope.instance.useDevice(deviceId: 'ble:mobile');
    await RadioScope.instance.useNodeNum(mobile, deviceId: 'ble:mobile');

    final before = await listScopes();
    expect(container.read(radioScopeProvider), 'node-a6960864');
    expect(container.read(radioScopeIdentityProvider), 'node-6944378a');
    expect(
      before.firstWhere((s) => s.key == 'node-6944378a').isConnected,
      isTrue,
    );

    await RadioScope.instance.useDevice(deviceId: 'ble:third');
    await RadioScope.instance.useNodeNum(third, deviceId: 'ble:third');

    final after = await listScopes();
    expect(container.read(radioScopeProvider), 'node-a6960864');
    expect(container.read(radioScopeIdentityProvider), 'node-00001111');
    expect(
      after.firstWhere((s) => s.key == 'node-00001111').isConnected,
      isTrue,
    );
    expect(
      after.firstWhere((s) => s.key == 'node-6944378a').isConnected,
      isFalse,
    );
    expect(after.firstWhere((s) => s.key == 'node-a6960864').isCurrent, isTrue);
  });
}
