import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'main_screen.dart';


class PermissionDeniedScreen extends StatelessWidget {
  const PermissionDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // 제목
              const Text(
                '권한이 없으면 방해를 드릴 수 없어요',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // 설명
              const Text(
                "설정에서 '다른 앱 위에 표시'를 허용해야\n오버레이가 작동해요",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // 다시 설정하러 가기 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    if (Platform.isAndroid) {
                      await Permission.systemAlertWindow.request();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF53FFF6),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '다시 설정하러 가기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 권한 없이 둘러보기 버튼
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                    );
                  },
                  child: const Text(
                    '권한 없이 둘러보기',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}