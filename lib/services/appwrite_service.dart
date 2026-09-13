import 'dart:async';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Appwrite configuration constants for Noto app
class AppwriteConfig {
  // NYC region endpoint for project 6a46128600370db2e820
  static const String endpoint = 'https://nyc.cloud.appwrite.io/v1';
  static const String projectId = '6a46128600370db2e820';
  static const String databaseId = 'main';
  static const String collectionId = 'noto_user_info';
}

/// Service to handle Appwrite user telemetry and silent onboarding logging.
class AppwriteService {
  AppwriteService._internal();

  static final AppwriteService instance = AppwriteService._internal();

  // Local storage keys
  static const String keyDocumentId = 'noto_appwrite_user_doc_id';
  static const String keyUserCounter = 'noto_appwrite_user_counter';
  static const String keyLastActiveUpdateMs = 'noto_appwrite_last_active_ms';

  Client? _client;
  Databases? _databases;

  void _ensureInitialized() {
    if (_client != null && _databases != null) return;
    _client = Client()
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    _databases = Databases(_client!);
  }

  Client get client {
    _ensureInitialized();
    return _client!;
  }

  Databases get databases {
    _ensureInitialized();
    return _databases!;
  }

  /// Retrieves the saved Appwrite document ID from local storage
  Future<String?> getSavedDocumentId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(keyDocumentId) ??
          prefs.getString('kato_appwrite_user_doc_id');
    } catch (e) {
      debugPrint('[Appwrite] Error reading saved document ID: $e');
      return null;
    }
  }

  /// Auto-generates a user identifier in a unique or sequential format.
  /// - [useTimestamp] = true: "user_" + device timestamp (guaranteed unique across all devices)
  /// - [useTimestamp] = false: sequential format like "user1", "user2"
  Future<String> generateUserName({bool useTimestamp = true}) async {
    try {
      if (useTimestamp) {
        return 'user_${DateTime.now().millisecondsSinceEpoch}';
      }
      final prefs = await SharedPreferences.getInstance();
      final int counter = prefs.getInt(keyUserCounter) ?? 1;
      await prefs.setInt(keyUserCounter, counter + 1);
      return 'user$counter';
    } catch (_) {
      return 'user_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Converts an ISO 3166-1 alpha-2 country code (e.g. "PK") to full country name (e.g. "Pakistan").
  static String countryNameFromCode(String code) {
    final upper = code.trim().toUpperCase();
    return _countryCodeToName[upper] ?? upper;
  }

  /// Auto-detects device country code via locale and converts it to full country name.
  /// Example: 'PK' -> 'Pakistan', 'US' -> 'United States'. Fallback to 'Unknown'.
  String detectCountry() {
    String? code;
    try {
      final countryCode = PlatformDispatcher.instance.locale.countryCode;
      if (countryCode != null && countryCode.trim().isNotEmpty) {
        code = countryCode.trim().toUpperCase();
      }
    } catch (_) {}

    if (code == null || code.isEmpty) {
      try {
        if (!kIsWeb) {
          final localeName = Platform.localeName; // e.g. "en_US" or "en-GB"
          final parts = localeName.split(RegExp(r'[_\-]'));
          if (parts.length > 1 && parts[1].isNotEmpty) {
            code = parts[1].trim().toUpperCase();
          }
        }
      } catch (_) {}
    }

    if (code != null && code.isNotEmpty) {
      return countryNameFromCode(code);
    }

    return 'Unknown';
  }

  /// 1. Silent background task executed when user clicks "Get Started".
  /// - Non-blocking: does not disrupt or delay UI transitions.
  /// - Checks local storage for existing document ID.
  /// - If registered: updates `last_active` and refreshes `country` to full name.
  /// - If not registered: creates document with `name`, `country`, `joining_date`, `last_active`
  ///   and saves document ID locally upon success.
  /// - All network calls are wrapped in try-catch to prevent crashes.
  Future<models.Document?> logUserOnboarding({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      _ensureInitialized();

      final prefs = await SharedPreferences.getInstance();
      final String? existingDocId = prefs.getString(keyDocumentId) ??
          prefs.getString('kato_appwrite_user_doc_id');
      final String nowIso = DateTime.now().toUtc().toIso8601String();
      final String country = detectCountry();

      // Check if user is already registered locally
      if (existingDocId != null && existingDocId.isNotEmpty) {
        debugPrint(
          '[Appwrite] User already registered with ID "$existingDocId". Updating last_active and country ($country)...',
        );
        return await updateLastActiveSilently(
          docId: existingDocId,
          country: country,
          force: true,
          timeout: timeout,
        );
      }

      // Not registered -> auto-detect full country name and format name
      final String userName = await generateUserName();

      debugPrint(
        '[Appwrite] Silently registering user "$userName" ($country) into "${AppwriteConfig.collectionId}"...',
      );

      // ignore: deprecated_member_use
      final document = await _databases!.createDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.collectionId,
        documentId: ID.unique(),
        data: {
          'name': userName,
          'country': country,
          'joining_date': nowIso,
          'last_active': nowIso,
        },
      ).timeout(timeout);

      // Store returned document ID upon success
      await prefs.setString(keyDocumentId, document.$id);
      await prefs.setInt(
        keyLastActiveUpdateMs,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint(
        '[Appwrite] User registered successfully! Document ID: ${document.$id}',
      );
      return document;
    } on TimeoutException {
      debugPrint('[Appwrite] Request timed out while registering user.');
      return null;
    } on AppwriteException catch (e) {
      _handleAppwriteException(e, 'logUserOnboarding');
      return null;
    } on SocketException catch (e) {
      debugPrint('[Appwrite] Network unreachable (offline): ${e.message}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[Appwrite] Unexpected error in logUserOnboarding: $e\n$stackTrace');
      return null;
    }
  }

  /// Updates only the `last_active` field (and optionally `country`) for an existing user document.
  Future<models.Document?> updateLastActiveSilently({
    String? docId,
    String? country,
    bool force = false,
    int debounceMinutes = 5,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    try {
      _ensureInitialized();

      final prefs = await SharedPreferences.getInstance();
      final targetDocId = docId ??
          prefs.getString(keyDocumentId) ??
          prefs.getString('kato_appwrite_user_doc_id');

      if (targetDocId == null || targetDocId.isEmpty) {
        debugPrint('[Appwrite] No saved document ID found to update last_active.');
        return null;
      }

      // Debounce updates to avoid excessive API hits on quick app resumes
      if (!force) {
        final int lastUpdate = prefs.getInt(keyLastActiveUpdateMs) ?? 0;
        final int nowMs = DateTime.now().millisecondsSinceEpoch;
        if (nowMs - lastUpdate < debounceMinutes * 60 * 1000) {
          return null;
        }
      }

      final String nowIso = DateTime.now().toUtc().toIso8601String();
      debugPrint('[Appwrite] Updating last_active for user ID: $targetDocId');

      final Map<String, dynamic> updateData = {
        'last_active': nowIso,
      };
      if (country != null && country.isNotEmpty && country != 'Unknown') {
        updateData['country'] = country;
      }

      // ignore: deprecated_member_use
      final document = await _databases!.updateDocument(
        databaseId: AppwriteConfig.databaseId,
        collectionId: AppwriteConfig.collectionId,
        documentId: targetDocId,
        data: updateData,
      ).timeout(timeout);

      await prefs.setInt(
        keyLastActiveUpdateMs,
        DateTime.now().millisecondsSinceEpoch,
      );
      debugPrint('[Appwrite] Successfully updated last_active to $nowIso');
      return document;
    } on TimeoutException {
      debugPrint('[Appwrite] Request timed out while updating last_active.');
      return null;
    } on AppwriteException catch (e) {
      _handleAppwriteException(e, 'updateLastActiveSilently');
      return null;
    } on SocketException catch (e) {
      debugPrint('[Appwrite] Network unreachable: ${e.message}');
      return null;
    } catch (e, stackTrace) {
      debugPrint('[Appwrite] Error updating last_active: $e\n$stackTrace');
      return null;
    }
  }

  void _handleAppwriteException(AppwriteException e, String context) {
    if (e.message != null && e.message!.contains('region')) {
      debugPrint(
        '[Appwrite Region Error ${e.code}] In $context: Project "${AppwriteConfig.projectId}" is restricted to its regional endpoint (e.g., "${AppwriteConfig.endpoint}"). (${e.message})',
      );
    } else if (e.code == 404) {
      debugPrint(
        '[Appwrite 404] Resource not found in $context: Check Database ID "${AppwriteConfig.databaseId}" and Collection ID "${AppwriteConfig.collectionId}". (${e.message})',
      );
    } else if (e.code == 401 || e.code == 403) {
      debugPrint(
        '[Appwrite Permission ${e.code}] In $context: Ensure collection "${AppwriteConfig.collectionId}" has Create/Update permissions enabled for role "Any" or "Users". (${e.message})',
      );
    } else {
      debugPrint(
        '[Appwrite Error ${e.code}] $context failed: ${e.message} (type: ${e.type})',
      );
    }
  }

  // Comprehensive ISO 3166-1 alpha-2 to Full Country Name dictionary
  static const Map<String, String> _countryCodeToName = {
    'AF': 'Afghanistan',
    'AX': 'Åland Islands',
    'AL': 'Albania',
    'DZ': 'Algeria',
    'AS': 'American Samoa',
    'AD': 'Andorra',
    'AO': 'Angola',
    'AI': 'Anguilla',
    'AQ': 'Antarctica',
    'AG': 'Antigua and Barbuda',
    'AR': 'Argentina',
    'AM': 'Armenia',
    'AW': 'Aruba',
    'AU': 'Australia',
    'AT': 'Austria',
    'AZ': 'Azerbaijan',
    'BS': 'Bahamas',
    'BH': 'Bahrain',
    'BD': 'Bangladesh',
    'BB': 'Barbados',
    'BY': 'Belarus',
    'BE': 'Belgium',
    'BZ': 'Belize',
    'BJ': 'Benin',
    'BM': 'Bermuda',
    'BT': 'Bhutan',
    'BO': 'Bolivia',
    'BA': 'Bosnia and Herzegovina',
    'BW': 'Botswana',
    'BV': 'Bouvet Island',
    'BR': 'Brazil',
    'IO': 'British Indian Ocean Territory',
    'BN': 'Brunei',
    'BG': 'Bulgaria',
    'BF': 'Burkina Faso',
    'BI': 'Burundi',
    'CV': 'Cabo Verde',
    'KH': 'Cambodia',
    'CM': 'Cameroon',
    'CA': 'Canada',
    'KY': 'Cayman Islands',
    'CF': 'Central African Republic',
    'TD': 'Chad',
    'CL': 'Chile',
    'CN': 'China',
    'CX': 'Christmas Island',
    'CC': 'Cocos (Keeling) Islands',
    'CO': 'Colombia',
    'KM': 'Comoros',
    'CG': 'Congo',
    'CD': 'Democratic Republic of the Congo',
    'CK': 'Cook Islands',
    'CR': 'Costa Rica',
    'CI': "Côte d'Ivoire",
    'HR': 'Croatia',
    'CU': 'Cuba',
    'CW': 'Curaçao',
    'CY': 'Cyprus',
    'CZ': 'Czech Republic',
    'DK': 'Denmark',
    'DJ': 'Djibouti',
    'DM': 'Dominica',
    'DO': 'Dominican Republic',
    'EC': 'Ecuador',
    'EG': 'Egypt',
    'SV': 'El Salvador',
    'GQ': 'Equatorial Guinea',
    'ER': 'Eritrea',
    'EE': 'Estonia',
    'SZ': 'Eswatini',
    'ET': 'Ethiopia',
    'FK': 'Falkland Islands',
    'FO': 'Faroe Islands',
    'FJ': 'Fiji',
    'FI': 'Finland',
    'FR': 'France',
    'GF': 'French Guiana',
    'PF': 'French Polynesia',
    'GA': 'Gabon',
    'GM': 'Gambia',
    'GE': 'Georgia',
    'DE': 'Germany',
    'GH': 'Ghana',
    'GI': 'Gibraltar',
    'GR': 'Greece',
    'GL': 'Greenland',
    'GD': 'Grenada',
    'GP': 'Guadeloupe',
    'GU': 'Guam',
    'GT': 'Guatemala',
    'GG': 'Guernsey',
    'GN': 'Guinea',
    'GW': 'Guinea-Bissau',
    'GY': 'Guyana',
    'HT': 'Haiti',
    'HN': 'Honduras',
    'HK': 'Hong Kong',
    'HU': 'Hungary',
    'IS': 'Iceland',
    'IN': 'India',
    'ID': 'Indonesia',
    'IR': 'Iran',
    'IQ': 'Iraq',
    'IE': 'Ireland',
    'IM': 'Isle of Man',
    'IL': 'Israel',
    'IT': 'Italy',
    'JM': 'Jamaica',
    'JP': 'Japan',
    'JE': 'Jersey',
    'JO': 'Jordan',
    'KZ': 'Kazakhstan',
    'KE': 'Kenya',
    'KI': 'Kiribati',
    'KP': 'North Korea',
    'KR': 'South Korea',
    'KW': 'Kuwait',
    'KG': 'Kyrgyzstan',
    'LA': 'Laos',
    'LV': 'Latvia',
    'LB': 'Lebanon',
    'LS': 'Lesotho',
    'LR': 'Liberia',
    'LY': 'Libya',
    'LI': 'Liechtenstein',
    'LT': 'Lithuania',
    'LU': 'Luxembourg',
    'MO': 'Macao',
    'MG': 'Madagascar',
    'MW': 'Malawi',
    'MY': 'Malaysia',
    'MV': 'Maldives',
    'ML': 'Mali',
    'MT': 'Malta',
    'MH': 'Marshall Islands',
    'MQ': 'Martinique',
    'MR': 'Mauritania',
    'MU': 'Mauritius',
    'YT': 'Mayotte',
    'MX': 'Mexico',
    'FM': 'Micronesia',
    'MD': 'Moldova',
    'MC': 'Monaco',
    'MN': 'Mongolia',
    'ME': 'Montenegro',
    'MS': 'Montserrat',
    'MA': 'Morocco',
    'MZ': 'Mozambique',
    'MM': 'Myanmar',
    'NA': 'Namibia',
    'NR': 'Nauru',
    'NP': 'Nepal',
    'NL': 'Netherlands',
    'NC': 'New Caledonia',
    'NZ': 'New Zealand',
    'NI': 'Nicaragua',
    'NE': 'Niger',
    'NG': 'Nigeria',
    'NU': 'Niue',
    'NF': 'Norfolk Island',
    'MK': 'North Macedonia',
    'MP': 'Northern Mariana Islands',
    'NO': 'Norway',
    'OM': 'Oman',
    'PK': 'Pakistan',
    'PW': 'Palau',
    'PS': 'Palestine',
    'PA': 'Panama',
    'PG': 'Papua New Guinea',
    'PY': 'Paraguay',
    'PE': 'Peru',
    'PH': 'Philippines',
    'PN': 'Pitcairn',
    'PL': 'Poland',
    'PT': 'Portugal',
    'PR': 'Puerto Rico',
    'QA': 'Qatar',
    'RE': 'Réunion',
    'RO': 'Romania',
    'RU': 'Russia',
    'RW': 'Rwanda',
    'WS': 'Samoa',
    'SM': 'San Marino',
    'ST': 'Sao Tome and Principe',
    'SA': 'Saudi Arabia',
    'SN': 'Senegal',
    'RS': 'Serbia',
    'SC': 'Seychelles',
    'SL': 'Sierra Leone',
    'SG': 'Singapore',
    'SK': 'Slovakia',
    'SI': 'Slovenia',
    'SB': 'Solomon Islands',
    'SO': 'Somalia',
    'ZA': 'South Africa',
    'SS': 'South Sudan',
    'ES': 'Spain',
    'LK': 'Sri Lanka',
    'SD': 'Sudan',
    'SR': 'Suriname',
    'SE': 'Sweden',
    'CH': 'Switzerland',
    'SY': 'Syria',
    'TW': 'Taiwan',
    'TJ': 'Tajikistan',
    'TZ': 'Tanzania',
    'TH': 'Thailand',
    'TL': 'Timor-Leste',
    'TG': 'Togo',
    'TK': 'Tokelau',
    'TO': 'Tonga',
    'TT': 'Trinidad and Tobago',
    'TN': 'Tunisia',
    'TR': 'Turkey',
    'TM': 'Turkmenistan',
    'TC': 'Turks and Caicos Islands',
    'TV': 'Tuvalu',
    'UG': 'Uganda',
    'UA': 'Ukraine',
    'AE': 'United Arab Emirates',
    'GB': 'United Kingdom',
    'US': 'United States',
    'UY': 'Uruguay',
    'UZ': 'Uzbekistan',
    'VU': 'Vanuatu',
    'VA': 'Vatican City',
    'VE': 'Venezuela',
    'VN': 'Vietnam',
    'VG': 'Virgin Islands (British)',
    'VI': 'Virgin Islands (U.S.)',
    'YE': 'Yemen',
    'ZM': 'Zambia',
    'ZW': 'Zimbabwe',
  };
}
