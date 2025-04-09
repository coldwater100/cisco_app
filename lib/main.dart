import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR 스캐너 데모',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const QRScannerHomePage(),
    );
  }
}

class QRScannerHomePage extends StatefulWidget {
  const QRScannerHomePage({super.key});

  @override
  State<QRScannerHomePage> createState() => _QRScannerHomePageState();
}

class _QRScannerHomePageState extends State<QRScannerHomePage> {
  String? scannedValue;

  void _startScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QRScannerPage(
          onScanned: (value) {
            setState(() {
              scannedValue = value;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR 코드 스캐너'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startScan,
              child: const Text('📷 QR 코드 찍기'),
            ),
            const SizedBox(height: 20),
            if (scannedValue != null) ...[
              const Text(
                '스캔된 값:',
                style: TextStyle(fontSize: 18),
              ),
              Text(
                scannedValue!,
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
    controller.dispose(); // ✅ 카메라 종료
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR 스캔 중...')),
      body: MobileScanner(
        controller: controller, // ✅ 컨트롤러 연결
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;

          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              widget.onScanned(code);

              /// ✅ 카메라 멈추고 pop
              controller.stop();
              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }
}
