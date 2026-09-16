// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025-2026 gotnull (developer@socialmesh.app)

// The text of a MESH_BEACON_APP announcement lands in the channel inbox
// through the text-message path, tagged as a beacon so the notification
// toggle for beacons can tell it from a typed message. A plain text message
// keeps its usual source.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:socialmesh/core/transport.dart';
import 'package:socialmesh/generated/meshtastic/mesh.pb.dart' as pb;
import 'package:socialmesh/generated/meshtastic/mesh_beacon.pb.dart'
    as mesh_beacon_pb;
import 'package:socialmesh/generated/meshtastic/portnums.pbenum.dart' as pn;
import 'package:socialmesh/models/mesh_models.dart';
import 'package:socialmesh/services/mesh_packet_dedupe_store.dart';
import 'package:socialmesh/services/protocol/protocol_service.dart';

class _FakeTransport extends DeviceTransport {
  final StreamController<List<int>> _dataController =
      StreamController<List<int>>.broadcast();

  @override
  TransportType get type => TransportType.ble;
  @override
  bool get requiresFraming => false;
  @override
  bool get requiresWakeSequence => false;
  @override
  TransportReconnectMode get reconnectMode => TransportReconnectMode.scanBased;
  @override
  DeviceConnectionState get state => DeviceConnectionState.disconnected;
  @override
  Stream<DeviceConnectionState> get stateStream =>
      const Stream<DeviceConnectionState>.empty();
  @override
  Stream<List<int>> get dataStream => _dataController.stream;
  @override
  Stream<DeviceInfo> scan({Duration? timeout, bool scanAll = false}) =>
      const Stream<DeviceInfo>.empty();
  @override
  Future<void> connect(DeviceInfo device) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Future<void> enableNotifications() async {}
  @override
  Future<void> pollOnce() async {}
  @override
  Future<void> send(List<int> data) async {}
  @override
  Future<int?> readRssi() async => null;
  @override
  Future<void> dispose() async {
    await _dataController.close();
  }
}

List<int> _frame({
  required int packetId,
  required pn.PortNum portnum,
  required List<int> payload,
}) {
  final data = pb.Data()
    ..portnum = portnum
    ..payload = payload;
  final packet = pb.MeshPacket()
    ..from = 0x55
    ..to = 0xFFFFFFFF
    ..channel = 0
    ..id = packetId
    ..decoded = data;
  return (pb.FromRadio()..packet = packet).writeToBuffer();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test(
    'a beacon announcement is tagged meshBeacon, a text message is not',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('beacon_source');
      final dedupeStore = MeshPacketDedupeStore(
        dbPathOverride: p.join(tempDir.path, 'dedupe.db'),
      );
      await dedupeStore.init();
      final protocol = ProtocolService(
        _FakeTransport(),
        dedupeStore: dedupeStore,
      );
      final messages = <Message>[];
      final sub = protocol.messageStream.listen(messages.add);
      try {
        final beacon = mesh_beacon_pb.MeshBeacon()
          ..message = 'Welcome to the hill mesh';
        await protocol.handleIncomingPacket(
          _frame(
            packetId: 1,
            portnum: pn.PortNum.MESH_BEACON_APP,
            payload: beacon.writeToBuffer(),
          ),
        );
        await protocol.handleIncomingPacket(
          _frame(
            packetId: 2,
            portnum: pn.PortNum.TEXT_MESSAGE_APP,
            payload: utf8.encode('typed by a person'),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(messages.length, 2);
        expect(messages[0].text, 'Welcome to the hill mesh');
        expect(messages[0].source, MessageSource.meshBeacon);
        expect(messages[1].text, 'typed by a person');
        expect(messages[1].source, MessageSource.unknown);
      } finally {
        await sub.cancel();
        protocol.stop();
        await dedupeStore.dispose();
        await tempDir.delete(recursive: true);
      }
    },
  );
}
