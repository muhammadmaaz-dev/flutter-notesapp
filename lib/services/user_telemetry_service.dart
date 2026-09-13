import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:appwrite/appwrite.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Isolated service class handling silent, offline-first user telemetry in Appwrite.
class UserTelemetryService {
  UserTelemetryService._();
  static final UserTelemetryService instance = UserTelemetryService._();

  // ---------------------------------------------------------------------------
  // DEBUG CONFIGURATION
  // ---------------------------------------------------------------------------
  /// Set to true during debugging so every click attempts a real Appwrite request,
  /// bypassing the local "already registered" check. Set to false for production.
  static const bool debugBypassLocalState = false;

  // ---------------------------------------------------------------------------
  // APPWRITE CONFIGURATION
  // ---------------------------------------------------------------------------
  static const String endpoint = 'https://nyc.cloud.appwrite.io/v1';
  static const String projectId = '6a46128600370db2e820';
  static const String databaseId = 'main';
  static const String collectionId = 'noto_user_info';

  // ---------------------------------------------------------------------------
  // LOCAL STORAGE KEYS
  // ---------------------------------------------------------------------------
  static const String keyHasCreatedRemoteProfile = 'has_created_remote_profile';
  static const String keyIsOnboardedSynced = 'is_onboarded_synced';
  static const String keyPendingPayload = 'pending_telemetry_payload';
  static const String keyDocumentId = 'appwrite_telemetry_document_id';
  static const String keyUserCounter = 'user_telemetry_counter';
  static const String keyLastActiveSyncMs = 'telemetry_last_active_sync_ms';

  late Client _client;
  late Databases _databases;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;
  bool _isInitialized = false;

  /// Initializes Appwrite client and listens for network recovery to auto-sync offline data
  Future<void> init() async {
    if (_isInitialized) return;

    _client = Client()
        .setProject(projectId)
        .setEndpoint(endpoint);
    _databases = Databases(_client);

    // Auto-retry offline sync whenever connectivity is restored
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final hasConnection = results.any(
        (r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet,
      );
      if (hasConnection) {
        debugPrint('🌐 [UserTelemetryService] Network connectivity restored. Triggering sync...');
        syncPendingTelemetry();
      }
    });

    _isInitialized = true;
    debugPrint('🚀 [UserTelemetryService] Initialized with endpoint: $endpoint | Project: $projectId');

    // Trigger launch check
    syncPendingTelemetry();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Detects country with robust offline device locale fallback
  String detectCountry() {
    try {
      final countryCode = PlatformDispatcher.instance.locale.countryCode;
      if (countryCode != null && countryCode.trim().isNotEmpty) {
        return countryCode.trim().toUpperCase();
      }
    } catch (_) {}

    try {
      if (!kIsWeb) {
        final localeName = Platform.localeName; // e.g. "en_US"
        final parts = localeName.split(RegExp(r'[_-]'));
        if (parts.length > 1 && parts[1].isNotEmpty) {
          return parts[1].toUpperCase();
        }
      }
    } catch (_) {}

    return 'Unknown';
  }

  /// Generates a sequential and unique identifier pattern: "User 1 (#8492)", "User 2 (#3120)"
  Future<String> generateUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final int counter = prefs.getInt(keyUserCounter) ?? 1;
    await prefs.setInt(keyUserCounter, counter + 1);

    final int randomSuffix = 1000 + Random().nextInt(9000);
    return 'User $counter (#$randomSuffix)';
  }

  /// 1. Telemetry capture for "Get Started" tap
  Future<void> trackOnboarding() async {
    try {
      debugPrint('👉 [UserTelemetryService] "Get Started" tapped. Initiating onboarding tracking...');

      final prefs = await SharedPreferences.getInstance();
      final bool alreadyCreated =
          prefs.getBool(keyHasCreatedRemoteProfile) ?? false;

      // Check if already registered (bypassed if debugBypassLocalState == true)
      if (!debugBypassLocalState && alreadyCreated) {
        debugPrint('ℹ️ [UserTelemetryService] Profile already created locally. Updating last active instead.');
        await updateLastActive();
        return;
      }

      if (debugBypassLocalState && alreadyCreated) {
        debugPrint('⚠️ [UserTelemetryService] [DEBUG BYPASS ACTIVE] Ignoring local state to send fresh request to Appwrite...');
      }

      final name = await generateUserName();
      final country = detectCountry();
      final nowIso = DateTime.now().toUtc().toIso8601String();

      final payload = {
        'name': name,
        'country': country,
        'joining_date': nowIso,
        'last_active': nowIso,
      };

      // Cache payload locally first (Offline-First guarantee)
      await prefs.setString(keyPendingPayload, jsonEncode(payload));
      await prefs.setBool(keyIsOnboardedSynced, false);

      // Attempt to sync immediately in background
      await _syncPayload(payload);
    } catch (e, stack) {
      debugPrint('❌ [UserTelemetryService] Error in trackOnboarding: $e');
      debugPrint('❌ StackTrace: $stack');
    }
  }

  /// Background sync method called on app launch and upon network recovery
  Future<void> syncPendingTelemetry() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isSynced = prefs.getBool(keyIsOnboardedSynced) ?? false;
      final bool alreadyCreated =
          prefs.getBool(keyHasCreatedRemoteProfile) ?? false;

      if (debugBypassLocalState || !isSynced || !alreadyCreated) {
        final pendingJson = prefs.getString(keyPendingPayload);
        if (pendingJson != null && pendingJson.isNotEmpty) {
          debugPrint('🔄 [UserTelemetryService] Found cached pending telemetry payload. Attempting sync...');
          final payload = jsonDecode(pendingJson) as Map<String, dynamic>;
          await _syncPayload(payload);
        }
      } else {
        await updateLastActive();
      }
    } catch (e, stack) {
      debugPrint('❌ [UserTelemetryService] Error in syncPendingTelemetry: $e');
      debugPrint('❌ StackTrace: $stack');
    } finally {
      _isSyncing = false;
    }
  }

  /// Internal sync helper that creates document in Appwrite with verbose logging
  Future<bool> _syncPayload(Map<String, dynamic> payload) async {
    final String docUniqueId = ID.unique();

    debugPrint('\n================ [APPWRITE TELEMETRY REQUEST] ================');
    debugPrint('🚀 Starting sync with Appwrite...');
    debugPrint('📌 Endpoint: $endpoint');
    debugPrint('📌 Project ID: $projectId');
    debugPrint('📌 Database ID: $databaseId');
    debugPrint('📌 Collection ID: $collectionId');
    debugPrint('📌 Document ID: $docUniqueId');
    debugPrint('📦 Document Payload: ${jsonEncode(payload)}');
    debugPrint('================================================================\n');

    try {
      if (!_isInitialized) {
        _client = Client().setProject(projectId).setEndpoint(endpoint);
        _databases = Databases(_client);
        _isInitialized = true;
      }

      // ignore: deprecated_member_use
      final document = await _databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: docUniqueId,
        data: payload,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(keyHasCreatedRemoteProfile, true);
      await prefs.setBool(keyIsOnboardedSynced, true);
      await prefs.setString(keyDocumentId, document.$id);
      await prefs.remove(keyPendingPayload);
      await prefs.setInt(
        keyLastActiveSyncMs,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('\n================ [APPWRITE TELEMETRY SUCCESS] ================');
      debugPrint('✅ Document created successfully!');
      debugPrint('✅ Document ID: ${document.$id}');
      debugPrint('✅ Document Data: ${document.data}');
      debugPrint('================================================================\n');
      return true;
    } on AppwriteException catch (e) {
      debugPrint('\n================ [APPWRITE EXCEPTION DIAGNOSTICS] ================');
      debugPrint('❌ Appwrite Exception Code: ${e.code}');
      debugPrint('❌ Appwrite Exception Message: ${e.message}');
      debugPrint('❌ Appwrite Exception Type: ${e.type}');
      debugPrint('❌ Appwrite Exception Response: ${e.response}');
      debugPrint('===================================================================\n');
      return false;
    } on SocketException catch (e) {
      debugPrint('❌ [UserTelemetryService] SocketException (Device is offline): ${e.message}');
      debugPrint('ℹ️ Payload remains cached locally and will auto-sync when online.');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [UserTelemetryService] General Error: $e');
      debugPrint('❌ [UserTelemetryService] StackTrace: $stack');
      return false;
    }
  }

  /// Updates last_active timestamp if profile already exists
  Future<void> updateLastActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docId = prefs.getString(keyDocumentId);
      if (docId == null || docId.isEmpty) return;

      final int lastSync = prefs.getInt(keyLastActiveSyncMs) ?? 0;
      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      const int debounceMs = 5 * 60 * 1000; // 5-minute debounce

      if (!debugBypassLocalState && (nowMs - lastSync < debounceMs)) return;

      if (!_isInitialized) {
        _client = Client().setProject(projectId).setEndpoint(endpoint);
        _databases = Databases(_client);
        _isInitialized = true;
      }

      final nowIso = DateTime.now().toUtc().toIso8601String();
      debugPrint('⏱️ [UserTelemetryService] Updating last_active for document: $docId');

      // ignore: deprecated_member_use
      await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: docId,
        data: {'last_active': nowIso},
      );

      await prefs.setInt(keyLastActiveSyncMs, nowMs);
      debugPrint('✅ [UserTelemetryService] Successfully updated remote last_active');
    } on AppwriteException catch (e) {
      debugPrint('❌ [UserTelemetryService] updateLastActive AppwriteException (${e.code}): ${e.message}');
    } catch (e) {
      debugPrint('❌ [UserTelemetryService] updateLastActive error: $e');
    }
  }
}
