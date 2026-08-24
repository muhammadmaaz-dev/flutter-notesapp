import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:newapp/services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SupabaseAnalyticsService {
  SupabaseAnalyticsService._();
  static final SupabaseAnalyticsService instance =
      SupabaseAnalyticsService._();

  static const String _keyInstallationId = 'app_installation_id';
  static const String _keyIsSynced = 'analytics_is_synced';
  static const String _keyUserAlias = 'analytics_user_alias';
  static const String _keyLastActiveSyncMs = 'analytics_last_active_sync_ms';

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  Future<void> init() async {
    // 1. Ensure installation ID exists locally
    await getOrCreateInstallationId();

    // 2. Listen to network connectivity changes for offline sync
    _connectivitySubscription?.cancel();
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
        syncPendingUserAndActiveStatus();
      }
    });

    // 3. Initial sync attempt
    syncPendingUserAndActiveStatus();
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// Retrieves or generates a persistent UUID v4 installation ID
  Future<String> getOrCreateInstallationId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_keyInstallationId);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await prefs.setString(_keyInstallationId, id);
    }
    return id;
  }

  /// Detects the device country code without requesting runtime permissions
  String getDeviceCountry() {
    try {
      final countryCode = PlatformDispatcher.instance.locale.countryCode;
      if (countryCode != null && countryCode.isNotEmpty) {
        return countryCode.toUpperCase();
      }
    } catch (_) {}
    return 'Unknown';
  }

  /// Detects the current operating system
  String getDevicePlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Registers user anonymously in Supabase (Non-blocking)
  Future<void> registerUser() async {
    unawaited(_performRegistration());
  }

  Future<void> _performRegistration() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String installationId = await getOrCreateInstallationId();
      final String country = getDeviceCountry();
      final String platform = getDevicePlatform();

      // Ensure Supabase backend is ready
      await SupabaseService.instance.init();
      final client = SupabaseService.instance.client;

      // Execute Supabase RPC
      final response = await client.rpc(
        'register_or_sync_user',
        params: {
          'p_installation_id': installationId,
          'p_country': country,
          'p_platform': platform,
        },
      );

      if (response != null && response is Map) {
        final alias = response['user_alias'] as String?;
        if (alias != null) {
          await prefs.setString(_keyUserAlias, alias);
        }
      }

      await prefs.setBool(_keyIsSynced, true);
      await prefs.setInt(
        _keyLastActiveSyncMs,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint("Analytics: User registered & synced successfully ($installationId).");
    } catch (e) {
      debugPrint("Analytics: Offline/Error during registration (will retry automatically): $e");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsSynced, false);
    } finally {
      _isSyncing = false;
    }
  }

  /// Synchronizes pending registration or updates last active heartbeat
  Future<void> syncPendingUserAndActiveStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isSynced = prefs.getBool(_keyIsSynced) ?? false;

      if (!isSynced) {
        await _performRegistration();
        return;
      }

      // If already registered, update last active with 10-minute debouncing
      final int lastSyncMs = prefs.getInt(_keyLastActiveSyncMs) ?? 0;
      final int nowMs = DateTime.now().millisecondsSinceEpoch;
      const int debounceIntervalMs = 10 * 60 * 1000; // 10 minutes

      if (nowMs - lastSyncMs > debounceIntervalMs) {
        final String installationId = await getOrCreateInstallationId();
        await SupabaseService.instance.init();
        final client = SupabaseService.instance.client;

        await client.rpc(
          'update_last_active',
          params: {'p_installation_id': installationId},
        );

        await prefs.setInt(_keyLastActiveSyncMs, nowMs);
        debugPrint("Analytics: Heartbeat last_active updated for $installationId.");
      }
    } catch (e) {
      debugPrint("Analytics: Heartbeat sync failed silently: $e");
    }
  }
}
