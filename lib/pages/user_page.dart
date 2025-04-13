import 'dart:async'; // ✅ Timer 사용 위해 필요
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../data/api_location.dart';
import '../data/ble_location.dart';

class UserPage extends StatefulWidget {
  final String scannedText;

  const UserPage({super.key, required this.scannedText});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  String? otpValue;
  String? macAddress;
  List<ApLocation> apLocations = [];  // ap 들의 data
  BleLocation? bleLocation ; // 등록된 ble 의 data
  Timer? _timer; //
  final timerInterval = 2; // ble data 갱신 주기
  final Color apColor = Colors.redAccent;
  final Color apColorRemote = Colors.grey;
  final Color bleColor = Colors.blueAccent;

  @override
  void initState() {
    super.initState();
    otpValue = widget.scannedText;

    if (kDebugMode) {
      print(">>>> 스캔된 OTP: $otpValue");
    }

    _loadMacFromOtp();
    _loadApLocations();

    // ✅ 5초마다 위치 다시 불러온다
    _timer = Timer.periodic(Duration(seconds: timerInterval), (timer) {
      _loadBleLocations();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // ✅ 타이머 종료
    super.dispose();
  }

  // rssi값에 따라 icon의 opacity를 결정
  double getOpacityFromRssi(int? rssi) {
    if( rssi == null) return 0.5;
    final clamped = rssi.clamp(-100, -50);
    return (clamped + 100) / 100 * 0.5 + 0.5;
  }


  // Firestore 에서 otp를 이용 기계의 mac 값을 구함
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

  // Firestore 에서 AP의 data를 읽어 와서 apLocation 에 저장
  Future<void> _loadApLocations() async {
    try {
      final querySnapshot =
      await FirebaseFirestore.instance.collection('apLocations').get();

      final loadedLocations = querySnapshot.docs.map((doc) {
        return ApLocation.fromMap(doc.data());
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
    if (macAddress == null) {
      if (kDebugMode) {
        print(">>>> macAddress가 아직 준비되지 않았습니다.");
      }
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('scanning_data')
          .where('clientMac', isEqualTo: macAddress)
          .orderBy('timestamp', descending: true) // 최신 문서부터 가져오기
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        final location = BleLocation.fromMap(data);

        if (kDebugMode) {
          print(">>>> BLE 위치 찾음: $location");
        }

        setState(() {
          bleLocation = location;
        });
      } else {
        if (kDebugMode) {
          print(">>>> BLE 위치 정보가 없습니다.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(">>>> Firestore 조회 오류 (bleLocations): $e");
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double apIconsize = 30.0;
    const double bleIconsize = 30.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('👤 사용자 위치 확인 '),
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
                    left: ap.x / 100 * screenWidth - apIconsize / 2,
                    top: ap.y / 100 * screenWidth - apIconsize / 2,
                    child: Opacity(
                      opacity: (bleLocation != null && bleLocation!.nearestApMac == ap.mac)
                          ? getOpacityFromRssi(bleLocation!.rssi)
                          : 0.5, // 일치하지 않는 AP는 회색, 투명도 낮음
                      child: Icon(
                        Icons.router,
                        color: (bleLocation != null && bleLocation!.nearestApMac == ap.mac)
                            ? apColor
                            : apColorRemote,
                        size: apIconsize,
                      ),
                    ),
                  ),
                // 📡 BLE 아이콘 표시
                if (bleLocation != null && bleLocation!.x != null && bleLocation!.y != null)
                  Positioned(
                    left: bleLocation!.x! / 100 * screenWidth - bleIconsize / 2,
                    top: bleLocation!.y! / 100 * screenWidth - bleIconsize / 2,
                    child: Icon(
                      Icons.person_2_rounded,
                      color: bleColor,
                      size: bleIconsize,
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



