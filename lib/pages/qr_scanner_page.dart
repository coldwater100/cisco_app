import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'user_page.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isScanned = false;
  Timer? timeoutTimer;

  @override
  void initState() {
    super.initState();
    timeoutTimer = Timer(const Duration(seconds: 15), () {
      if (!mounted || isScanned) return;
      Fluttertoast.showToast(msg: '⏰ QR 스캔 실패: 시간이 초과되었습니다');
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    timeoutTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  void _onQRCodeScanned(String qrText) {
    if (isScanned) return;
    isScanned = true;

    timeoutTimer?.cancel();
    controller.stop();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => UserPage(scannedText: qrText),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📷 QR 코드 스캔')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final code = capture.barcodes.firstOrNull?.rawValue;
          if (code != null) {
            _onQRCodeScanned(code);
          }
        },
      ),
    );
  }
}

