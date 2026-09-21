// SPDX-License-Identifier: GPL-3.0-or-later
// SPDX-FileCopyrightText: 2025-2026 gotnull (developer@socialmesh.app)

import 'package:permission_handler/permission_handler.dart';

import '../../core/logging.dart';

/// Manages microphone permission for voice message recording.
abstract final class VoicePermissionService {
  /// Requests the [Permission.microphone] permission and returns the
  /// resulting status.
  ///
  /// On Android only the result of a request can report a permanent denial;
  /// a status read reports plain denial for every refused permission. Callers
  /// that need to send the user to system Settings branch on this result.
  static Future<PermissionStatus> requestMicrophoneStatus() async {
    try {
      final status = await Permission.microphone.request();
      AppLogging.voice('microphone permission status: $status');
      return status;
    } catch (e) {
      AppLogging.voice('error requesting microphone permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Requests the [Permission.microphone] permission.
  ///
  /// Returns true if the permission is granted or already was granted.
  static Future<bool> requestMicrophonePermission() async {
    final status = await requestMicrophoneStatus();
    return status.isGranted || status.isLimited;
  }

  /// Returns true if the microphone permission is currently granted.
  static Future<bool> hasMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      return status.isGranted || status.isLimited;
    } catch (e) {
      AppLogging.voice('error checking microphone permission: $e');
      return false;
    }
  }

  /// Opens the system app-settings page so the user can grant the microphone
  /// permission that was permanently denied.
  static Future<void> openSettings() => openAppSettings();
}
