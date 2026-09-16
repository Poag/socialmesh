// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025-2026 gotnull (developer@socialmesh.app)

// A dataset can be shared between two of the user's radios, so a message the
// app sent through one radio is read back while connected to the other. The
// sender is then not the connected radio's node number, yet the message is
// still the user's own: it sits on the right of the thread and its peer is
// the recipient, not the radio that sent it.

import 'package:flutter_test/flutter_test.dart';
import 'package:socialmesh/models/mesh_models.dart';

const _handheld = 0x5d286ee2;
const _rooftop = 0xf5d0918d;
const _peer = 0x2000;

Message _message({
  required int from,
  required int to,
  bool sent = false,
  bool received = false,
}) {
  return Message(
    from: from,
    to: to,
    text: 'hello',
    timestamp: DateTime(2026, 9, 10, 14),
    sent: sent,
    received: received,
  );
}

void main() {
  group('Message.isFromOwnRadio', () {
    test('a message from the connected radio is own', () {
      final m = _message(from: _handheld, to: _peer, sent: true);
      expect(m.isFromOwnRadio(_handheld), isTrue);
      expect(m.dmPeerFor(_handheld), _peer);
    });

    test('a message sent through another of my radios is own', () {
      final m = _message(from: _rooftop, to: _peer, sent: true);
      expect(m.isFromOwnRadio(_handheld), isTrue);
      expect(m.dmPeerFor(_handheld), _peer);
    });

    test('a received message from a peer is not own', () {
      final m = _message(from: _peer, to: _handheld, received: true);
      expect(m.isFromOwnRadio(_handheld), isFalse);
      expect(m.dmPeerFor(_handheld), _peer);
    });

    test('a message another of my radios sent to me is not own', () {
      final m = _message(from: _rooftop, to: _handheld, sent: true);
      expect(m.isFromOwnRadio(_handheld), isFalse);
      expect(m.dmPeerFor(_handheld), _rooftop);
    });

    test('a received peer message is not own even before my node is known', () {
      final m = _message(from: _peer, to: _handheld, received: true);
      expect(m.isFromOwnRadio(null), isFalse);
      expect(m.dmPeerFor(null), _peer);
    });
  });
}
