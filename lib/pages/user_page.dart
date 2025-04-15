import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import '../data/alarm_message.dart';
import '../data/ap_location.dart';
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
  List<ApLocation> apLocations = [];
  BleLocation? bleLocation;
  Timer? _timer;
  final timerInterval = 2;
  final Color apColor = Colors.redAccent;
  final Color apColorRemote = Colors.grey;
  final Color bleColor = Colors.blueAccent;

  List<String> alarmList = [];
  int previousAlarmCount = 0;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotification();
    otpValue = widget.scannedText;

    if (kDebugMode) {
      print(">>>> 스캔된 OTP: $otpValue");
    }

    _loadMacFromOtp();
    _loadApLocations();

    _timer = Timer.periodic(Duration(seconds: timerInterval), (timer) {
      _loadBleLocations();
      _loadAlarmMessages();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double getOpacityFromRssi(int? rssi) {
    if (rssi == null) return 0.5;
    final clamped = rssi.clamp(-100, -50);
    return (clamped + 100) / 100 * 0.5 + 0.5;
  }

  void _initNotification() {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alarm_channel_id', // 알림 채널 ID
      'Alarm Channel', // 알림 채널 이름
      channelDescription: 'Channel for alarm notifications', // 채널 설명
      importance: Importance.high, // 중요도 설정
      priority: Priority.high, // 우선순위 설정
      ticker: 'ticker',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0, // 알림 ID (0은 첫 번째 알림)
      '새 알람', // 알림 제목
      message, // 알림 메시지 (여기서 알람 내용을 사용)
      platformDetails, // 플랫폼 별 알림 설정
      payload: 'alarm_payload', // 알림 클릭 시 추가 정보 전달 (선택 사항)
    );
  }

  Future<void> _loadMacFromOtp() async {
    try {
      final otpQuery = await FirebaseFirestore.instance
          .collection('macOtpPairs')
          .where('otp', isEqualTo: otpValue) // 나중에 otpValue로
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
          .orderBy('timestamp', descending: true)
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

  Future<void> _loadAlarmMessages() async {
    if (macAddress == null) {
      if (kDebugMode) {
        print(">>>> macAddress가 아직 준비되지 않았습니다.");
      }
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('macAlart') // 'alarmMessages' 컬렉션
          .where('mac', isEqualTo: macAddress) // macAddress와 일치하는 것만
          .orderBy('timestamp', descending: true) // timestamp 기준으로 내림차순 정렬
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final loadedAlarms = querySnapshot.docs.map((doc) {
          final data = doc.data();
          final alarmMessage = AlarmMessage.fromMap(data);

          print("<<<<alarmMessage:" + alarmMessage.formattedTime);

          return '${alarmMessage.formattedTime} : ${alarmMessage.alarm}'; // 포맷된 시간 바로 사용
        }).toList();


        if (loadedAlarms.length > previousAlarmCount) {
          final newAlarms = loadedAlarms.sublist(previousAlarmCount);

          for (var msg in newAlarms) {
            _showNotification(msg); // ✅ 새 알람에 대한 알림 표시
          }
        }

        setState(() {
          alarmList = loadedAlarms;
          previousAlarmCount = loadedAlarms.length; // 갯수 저장
        });

        if (kDebugMode) {
          print(">>>> 알람 메시지 로드 완료: $loadedAlarms");
        }
      } else {
        if (kDebugMode) {
          print(">>>> 해당 macAddress에 대한 알람 메시지가 없습니다.");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(">>>> Firestore 조회 오류 (alarmMessages): $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double apIconsize = 40.0;
    const double bleIconsize = 30.0;

    final currentAp = bleLocation != null
        ? apLocations.firstWhere(
          (ap) => ap.mac.toLowerCase() == bleLocation!.nearestApMac?.toLowerCase(),
      orElse: () => ApLocation(
        mac: '',
        x: 0,
        y: 0,
        areaId: '',
        areaName: '',
        division: '',
      ),
    )
        : null;

    final currentAreaId = (currentAp != null && currentAp.mac.isNotEmpty) ? currentAp.areaId : '';
    final currentAreaName = (currentAp != null && currentAp.mac.isNotEmpty) ? currentAp.areaName : '';
    final currentDivision = (currentAp != null && currentAp.mac.isNotEmpty) ? currentAp.division : '';

    final imagePath = currentAreaId.isNotEmpty
        ? 'assets/images/$currentAreaId.png'
        : 'assets/images/default.png';

    final filteredAps = currentAreaId.isNotEmpty
        ? apLocations.where((ap) => ap.areaId == currentAreaId).toList()
        : [];

    return Scaffold(
      appBar: AppBar(
        title: Text(currentAreaId.isNotEmpty
            ? '$currentAreaName ($currentDivision)'
            : '👤 사용자 위치 확인'),
      ),
      body: Column(
        children: [
          SizedBox(
            width: screenWidth,
            height: screenWidth,
            child: Stack(
              children: [
                Image.asset(
                  imagePath,
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
                for (var ap in filteredAps)
                  Positioned(
                    left: ap.x / 100 * screenWidth - apIconsize / 2,
                    top: ap.y / 100 * screenWidth - apIconsize / 2,
                    child: Opacity(
                      opacity: (bleLocation != null && bleLocation!.nearestApMac == ap.mac)
                          ? getOpacityFromRssi(bleLocation!.rssi)
                          : 0.8,
                      child: Icon(
                        Icons.router,
                        color: (bleLocation != null && bleLocation!.nearestApMac == ap.mac)
                            ? apColor
                            : apColorRemote,
                        size: apIconsize,
                      ),
                    ),
                  ),
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
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.yellow.shade200,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "📢 알람",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: alarmList.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              )
                            ],
                          ),
                          child: Text(
                            alarmList[index],
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



