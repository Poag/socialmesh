// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025-2026 gotnull (developer@socialmesh.app)

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:socialmesh/services/protocol/protocol_service.dart';

// Published FNV-1a 32-bit reference vectors. The canvas frame dedupe ring
// relies on this hash producing the same value on the VM and on the web,
// so this file is run under both (`flutter test --platform chrome`).
void main() {
  Uint8List ascii(String s) => Uint8List.fromList(utf8.encode(s));

  test('empty input returns the offset basis', () {
    expect(ProtocolService.fnv1a32(Uint8List(0)), 0x811c9dc5);
  });

  test('matches the reference vectors', () {
    expect(ProtocolService.fnv1a32(ascii('a')), 0xe40c292c);
    expect(ProtocolService.fnv1a32(ascii('foobar')), 0xbf9cf968);
  });

  test('stays within 32 bits on long high-entropy input', () {
    final bytes = Uint8List.fromList(
      List<int>.generate(4096, (i) => (i * 2654435761) & 0xFF),
    );
    final hash = ProtocolService.fnv1a32(bytes);
    expect(hash, inInclusiveRange(0, 0xFFFFFFFF));
    expect(ProtocolService.fnv1a32(bytes), hash);
  });

  test('distinct payloads produce distinct fingerprints', () {
    expect(
      ProtocolService.fnv1a32(ascii('canvas-frame-1')),
      isNot(ProtocolService.fnv1a32(ascii('canvas-frame-2'))),
    );
  });
}
