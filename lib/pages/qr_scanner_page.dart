import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/otp_lookup_service.dart';

class QRScannerHomePage extends StatefulWidget {
  const QRScannerHomePage({super.key});

  @override
  State<QRScannerHomePage> createState() => _QRScannerHomePageState();
}

class _QRScannerHomePageState extends State<QRScannerHomePage> {
  String? scannedValue;
  String? mac;
  List<dynamic>? rssiList;

  Future<void> _lookupOtp(String otp) async {
    setState(() {
      scannedValue = otp;
      mac = null;
      rssiList = null;
    });

    final result = await OtpLookupService.fetchLocationByOtp(otp);
    setState(() {
      mac = result?['mac'];
      rssiList = result?['apRssiPairs'];
    });
  }

  void _startScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRScannerPage(
          onScanned: _lookupOtp,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('📷 QR + OTP 위치 조회')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startScan,
              child: const Text('QR 코드 스캔'),
            ),
            const SizedBox(height: 20),
            if (scannedValue != null) Text('OTP: $scannedValue'),
            if (mac != null) Text('✅ MAC: $mac'),
            if (rssiList != null) ...rssiList!.map((e) => Text('📡 ${e['apMac']}: ${e['rssi']}')).toList(),
            if (mac == null && scannedValue != null) const Text('📬 위치 정보 없음')
          ],
        ),
      ),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  final void Function(String value) onScanned;
  const QRScannerPage({super.key, required this.onScanned});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🔍 스캔 중...')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final code = barcodes.first.rawValue;
            if (code != null) {
              widget.onScanned(code);
              controller.stop();
              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }
}