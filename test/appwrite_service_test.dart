import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newapp/services/appwrite_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppwriteConfig Tests', () {
    test('Config parameters match requested specification', () {
      expect(AppwriteConfig.endpoint, 'https://nyc.cloud.appwrite.io/v1');
      expect(AppwriteConfig.projectId, '6a46128600370db2e820');
      expect(AppwriteConfig.databaseId, 'main');
      expect(AppwriteConfig.collectionId, 'noto_user_info');
    });
  });

  group('AppwriteService Unit Tests', () {
    test('generateUserName generates timestamp and sequential usernames', () async {
      final service = AppwriteService.instance;

      // Timestamp format
      final tsName = await service.generateUserName(useTimestamp: true);
      expect(tsName.startsWith('user_'), isTrue);

      // Sequential format
      final seqName1 = await service.generateUserName(useTimestamp: false);
      final seqName2 = await service.generateUserName(useTimestamp: false);
      expect(seqName1, 'user1');
      expect(seqName2, 'user2');
    });

    test('countryNameFromCode maps country code to full country name', () {
      expect(AppwriteService.countryNameFromCode('PK'), 'Pakistan');
      expect(AppwriteService.countryNameFromCode('pk'), 'Pakistan');
      expect(AppwriteService.countryNameFromCode('US'), 'United States');
      expect(AppwriteService.countryNameFromCode('GB'), 'United Kingdom');
      expect(AppwriteService.countryNameFromCode('AE'), 'United Arab Emirates');
      expect(AppwriteService.countryNameFromCode('IN'), 'India');
      expect(AppwriteService.countryNameFromCode('CA'), 'Canada');
    });

    test('detectCountry returns a valid string or Unknown', () {
      final country = AppwriteService.instance.detectCountry();
      expect(country.isNotEmpty, isTrue);
    });

    test('logUserOnboarding completes safely without crashing even on network failure', () async {
      final service = AppwriteService.instance;
      final doc = await service.logUserOnboarding(
        timeout: const Duration(milliseconds: 200),
      );
      expect(doc, isNull);
    });

    test('updateLastActiveSilently handles empty document ID without throwing', () async {
      final service = AppwriteService.instance;
      final res = await service.updateLastActiveSilently(
        timeout: const Duration(milliseconds: 200),
      );
      expect(res, isNull);
    });

    test('Local storage check for existing document ID', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppwriteService.keyDocumentId, 'existing_doc_123');

      final savedId = await AppwriteService.instance.getSavedDocumentId();
      expect(savedId, 'existing_doc_123');
    });
  });
}
