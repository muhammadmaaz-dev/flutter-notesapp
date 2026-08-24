import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LegalView {
  static void showPrivacyPolicy(BuildContext context) {
    _showLegalModal(
      context: context,
      title: "Privacy Policy",
      subtitle: "Last updated: August 24, 2026",
      content: _privacyPolicyText,
    );
  }

  static void showTermsOfService(BuildContext context) {
    _showLegalModal(
      context: context,
      title: "Terms of Service",
      subtitle: "Last updated: August 24, 2026",
      content: _termsOfServiceText,
    );
  }

  static void showAbout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: const Color(0xFF1F1F24),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(color: Colors.white12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17.r),
                child: Image.asset(
                  'assets/1b1ebb0d0b3b5d8b-capybara-7.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.sticky_note_2_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "Noto",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontFamily: 'NunitoBold',
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "Version 1.0.0 (Build 1) • by Xevon Labs",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13.sp,
                fontFamily: 'Nunito',
              ),
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1E),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                children: [
                  _aboutRow("Storage Engine", "Offline SQLite"),
                  Divider(color: Colors.white10, height: 16.h),
                  _aboutRow("Privacy Standard", "100% On-Device"),
                  Divider(color: Colors.white10, height: 16.h),
                  _aboutRow("Developer", "Xevon Labs"),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                width: double.infinity,
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                alignment: Alignment.center,
                child: Text(
                  "Close",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.sp,
                    fontFamily: 'NunitoBold',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  static Widget _aboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white60,
            fontSize: 13.sp,
            fontFamily: 'Nunito',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontFamily: 'NunitoBold',
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static void _showLegalModal({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF111113),
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (sheetContext, scrollController) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontFamily: 'NunitoBold',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 12.sp,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Divider(color: Colors.white10, height: 24.h),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    Text(
                      content,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        fontFamily: 'Nunito',
                        height: 1.55,
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const String _privacyPolicyText = '''
1. Overview & Core Philosophy
At Xevon Labs, we believe your personal notes, thoughts, and ideas should remain private and entirely under your control. Noto is built as an offline-first application. We do not sell, rent, monetize, or scan your personal content.

2. Information We Process
• Your Notes (100% Offline): All note titles, bodies, color themes, creation timestamps, and reminder schedules are stored exclusively on your local device using an isolated SQLite database. Your notes are never uploaded or synced to cloud servers.
• Anonymous Technical Telemetry: To maintain stability and track usage, Noto sends an anonymous installation UUID (v4), OS locale country code, platform type, and heartbeat timestamps to our backend. No names, emails, or personal data are collected.

3. Device Permissions
• Notifications (POST_NOTIFICATIONS): Delivers local reminder alerts scheduled by you.
• Exact Alarms (SCHEDULE_EXACT_ALARM): Rings reminders at the exact scheduled minute even in deep sleep (Doze mode).
• Boot Persistence (RECEIVE_BOOT_COMPLETED): Restores scheduled alarms when your device restarts.
• Vibration (VIBRATE): Provides tactile feedback and alarm vibration.
• Internet Access: Synchronizes anonymous active-user heartbeats.

4. Data Retention & Deletion
Deleting notes within the app or uninstalling the app permanently purges all local data.

5. Contact Us
Email: support@xevonlabs.com
Organization: Xevon Labs
Website: https://xevonlabs.com
''';

  static const String _termsOfServiceText = '''
1. Acceptance of Terms
By downloading, installing, or using Noto, provided by Xevon Labs, you agree to be bound by these Terms of Service.

2. License to Use
Xevon Labs grants you a personal, revocable, non-exclusive, non-transferable license to use Noto for personal productivity purposes.

3. User Content
You retain full ownership of all notes, texts, lists, and reminders created in Noto. All content is stored locally on your device. Xevon Labs is not liable for data loss resulting from device damage or lack of device backups.

4. Intellectual Property
All design elements, logos, animations, and software code are the intellectual property of Xevon Labs.

5. Disclaimer of Warranties
Noto is provided on an "AS IS" and "AS AVAILABLE" basis without warranties of any kind.

6. Limitation of Liability
To the maximum extent permitted by law, Xevon Labs shall not be liable for any indirect, incidental, or consequential damages resulting from app use.

7. Contact
Email: support@xevonlabs.com
Website: https://xevonlabs.com
''';
}
