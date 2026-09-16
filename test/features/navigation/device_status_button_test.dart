// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025-2026 gotnull (developer@socialmesh.app)

// `DeviceStatusButton` colour follows the usable-session state, not the raw
// link state. While the Meshtastic handshake is still running the device
// sheet reads Configuring in amber, and the app bar icon that opens it must
// agree, otherwise the icon promises a connection that refuses sends.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:socialmesh/core/theme.dart';
import 'package:socialmesh/core/transport.dart';
import 'package:socialmesh/features/navigation/main_shell.dart';
import 'package:socialmesh/l10n/app_localizations.dart';
import 'package:socialmesh/providers/app_providers.dart';

Widget _wrap({
  required DeviceConnectionState link,
  required MeshtasticBannerState banner,
}) {
  return ProviderScope(
    overrides: [
      connectionStateProvider.overrideWith((ref) => Stream.value(link)),
      meshtasticBannerStateProvider.overrideWithValue(banner),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(appBar: AppBar(actions: const [DeviceStatusButton()])),
    ),
  );
}

Color? _routerIconColor(WidgetTester tester) =>
    tester.widget<Icon>(find.byIcon(Icons.router)).color;

void main() {
  testWidgets(
    'reads amber while the link is up but the session is configuring',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          link: DeviceConnectionState.connected,
          banner: MeshtasticBannerState.configuring,
        ),
      );
      await tester.pumpAndSettle();

      expect(_routerIconColor(tester), AppTheme.warningYellow);
    },
  );

  testWidgets('reads amber while a dropped session is recovering', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        link: DeviceConnectionState.connected,
        banner: MeshtasticBannerState.recovering,
      ),
    );
    await tester.pumpAndSettle();

    expect(_routerIconColor(tester), AppTheme.warningYellow);
  });

  testWidgets('reads the accent colour once the session is usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        link: DeviceConnectionState.connected,
        banner: MeshtasticBannerState.passthrough,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(DeviceStatusButton));
    expect(_routerIconColor(tester), context.accentColor);
  });

  testWidgets('a configuring banner without a link does not read as amber', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        link: DeviceConnectionState.disconnected,
        banner: MeshtasticBannerState.configuring,
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(DeviceStatusButton));
    expect(_routerIconColor(tester), context.textTertiary);
  });
}
