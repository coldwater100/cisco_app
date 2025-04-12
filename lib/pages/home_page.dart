import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'qr_scanner_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 이미지
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // 상단 텍스트 "BLUE FENCE"
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'BLUE FENCE',
                style: GoogleFonts.playfairDisplay( // 원하는 글꼴로 바꿔도 돼!
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    const Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 가운데 아래쪽 카메라 버튼
          Align(
            alignment: const Alignment(0, 0.4),
            child: Ink(
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QRScannerPage()),
                  );
                },
                icon: const Icon(Icons.camera_alt),
                iconSize: 96, // 더 크게!
                color: Colors.white,
                splashRadius: 48,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
