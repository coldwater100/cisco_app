import 'dart:async'; // ✅ Timer 사용 위해 필요
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserPage extends StatefulWidget {
  final String scannedText;

  const UserPage({super.key, required this.scannedText});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String? otpValue;
  String? macAddress;
  List<Map<String, dynamic>> apLocations = [];
  List<Map<String, dynamic>> bleLocations = [];
  Timer? _timer; // ✅ 타이머 변수

  @override
  void initState() {
    super.initState();
    otpValue = widget.scannedText;

    if (kDebugMode) {
      print(">>>> 스캔된 OTP: $otpValue");
    }

    _loadMacFromOtp();
    _loadApLocations();

    // ✅ 5초마다 위치 다시 불러오기
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadBleLocations();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ 타이머 종료
    super.dispose();
  }

  Future<void> _loadMacFromOtp() async {
    try {
      final otpQuery = await FirebaseFirestore.instance
          .collection('macOtpPairs')
          .where('otp', isEqualTo: '603675') // 나중에 otpValue로 교체
          .get();

      if (otpQuery.docs.isNotEmpty) {
        final data = otpQuery.docs.first.data();
        macAddress = data['mac'];

        if (kDebugMode) {
          print(">>>> macAddress: $macAddress");
        }
      } else {
        if (kDebugMode) {
          print(">>>> 해당 OTP에 대한 macAddress를 찾을 수 없습니다");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(">>>> Firestore 조회 오류 (macOtpPairs): $e");
      }
    }
  }

  Future<void> _loadApLocations() async {
    try {
      final querySnapshot =
      await FirebaseFirestore.instance.collection('apLocations').get();

      final loadedLocations = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'mac': data['mac'],
          'x': (data['x'] as num).toDouble(),
          'y': (data['y'] as num).toDouble(),
        };
      }).toList();

      if (kDebugMode) {
        print(">>>> AP 위치 불러오기 완료: $loadedLocations");
      }

      setState(() {
        apLocations = loadedLocations;
      });
    } catch (e) {
      if (kDebugMode) {
        print(">>>> Firestore 조회 오류 (apLocations): $e");
      }
    }
  }

  Future<void> _loadBleLocations() async {
    try {
      final querySnapshot =
      await FirebaseFirestore.instance.collection('bleLocations').get();

      final loadedLocations = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'lat': (data['lat'] as num).toDouble(),
          'lng': (data['lng'] as num).toDouble(),
          'x': (data['x'] as num).toDouble(),
          'y': (data['y'] as num).toDouble(),
          'nearestApMac': data['nearestApMac'] as String,
          'mac' : data['mac'] as String,
          'nearestApRssi': data['nearestApRssi'] as int,
        };
      }).toList();

      if (kDebugMode) {
        print(">>>> Ble 데이터 불러오기 완료: $loadedLocations");
      }

      setState(() {
        bleLocations = loadedLocations;
      });
    } catch (e) {
      if (kDebugMode) {
        print(">>>> Firestore 조회 오류 (bleLocations): $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double iconSize = 30.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 사용자 페이지'),
      ),
      body: Column(
        children: [
          // 🖼️ 배경 이미지 + AP 위치
          SizedBox(
            width: screenWidth,
            height: screenWidth,
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/floor1.png',
                  fit: BoxFit.cover,
                  width: screenWidth,
                  height: screenWidth,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        '🏞️ 이미지 로드 실패',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  },
                ),
                // 🛰️ AP 아이콘 표시
                for (var ap in apLocations)
                  Positioned(
                    left: (ap['x'] as double) / 100 * screenWidth -
                        iconSize / 2,
                    top: (ap['y'] as double) / 100 * screenWidth -
                        iconSize / 2,
                    child: const Icon(
                      Icons.router,
                      color: Colors.blueAccent,
                      size: iconSize,
                    ),
                  ),
                // 📡 BLE 아이콘 표시
                for (var ble in bleLocations)
                  Positioned(
                    left: (ble['x'] as double) / 100 * screenWidth - iconSize / 2,
                    top: (ble['y'] as double) / 100 * screenWidth - iconSize / 2,
                    child: const Icon(
                      Icons.bluetooth,
                      color: Colors.greenAccent,
                      size: iconSize,
                    ),
                  ),
              ],
            ),
          ),

          // 🔶 아래 legend 공간
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.yellow.shade200,
              child: const Center(
                child: Text(
                  '📘 범례 영역 (추후 사용)',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


