// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025-2026 gotnull (developer@socialmesh.app)

import 'package:flutter_test/flutter_test.dart';
import 'package:socialmesh/services/transport/ble_transport.dart';

// The drain loop is the one read policy shared by the notification,
// refresh and poll paths. It is exercised here through closures because
// BleTransport binds to flutter_blue_plus and cannot be driven against a
// real characteristic in a unit test.
void main() {
  group('BleTransport.drainUntilEmpty', () {
    test(
      'reads until the first empty payload and delivers each frame',
      () async {
        final queue = <List<int>>[
          [1],
          [2, 2],
          [3, 3, 3],
          [],
        ];
        var reads = 0;
        final delivered = <List<int>>[];

        final frames = await BleTransport.drainUntilEmpty(() async {
          reads++;
          return queue.removeAt(0);
        }, delivered.add);

        expect(frames, 3);
        expect(reads, 4);
        expect(delivered, [
          [1],
          [2, 2],
          [3, 3, 3],
        ]);
      },
    );

    test('an empty first read delivers nothing after one read', () async {
      var reads = 0;
      final delivered = <List<int>>[];

      final frames = await BleTransport.drainUntilEmpty(() async {
        reads++;
        return const <int>[];
      }, delivered.add);

      expect(frames, 0);
      expect(reads, 1);
      expect(delivered, isEmpty);
    });

    test(
      'a read failure propagates after earlier frames were delivered',
      () async {
        final queue = <List<int>>[
          [7],
        ];
        final delivered = <List<int>>[];

        await expectLater(
          BleTransport.drainUntilEmpty(() async {
            if (queue.isEmpty) throw StateError('link dropped');
            return queue.removeAt(0);
          }, delivered.add),
          throwsStateError,
        );

        expect(delivered, [
          [7],
        ]);
      },
    );

    test('a burst of one frame per read is drained without pausing', () async {
      // The config phase hands over one frame per read with no fromNum
      // notification; the drain must keep reading rather than return
      // after the first frame.
      var remaining = 47;
      var reads = 0;

      final frames = await BleTransport.drainUntilEmpty(() async {
        reads++;
        if (remaining == 0) return const <int>[];
        remaining--;
        return [reads];
      }, (_) {});

      expect(frames, 47);
      expect(reads, 48);
    });
  });
}
