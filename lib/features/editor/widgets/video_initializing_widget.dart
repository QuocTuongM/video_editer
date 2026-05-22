import 'package:flutter/material.dart';

/// Widget hiển thị màn hình khởi động khi editor đang tải.
class VideoInitializingWidget extends StatelessWidget {
  /// Khởi tạo [VideoInitializingWidget].
  const VideoInitializingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.black87],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 30,
            children: [
              Icon(
                Icons.video_camera_back_rounded,
                size: 80,
                color: Colors.white70,
              ),
              Text(
                'Đang khởi động trình chỉnh sửa...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: Colors.white70,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}