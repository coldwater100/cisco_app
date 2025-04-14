import 'package:cloud_firestore/cloud_firestore.dart';

class AlarmMessage {
  final String alarm;
  final String mac;
  final DateTime timestamp;

  AlarmMessage({
    required this.alarm,
    required this.mac,
    required this.timestamp,
  });

  // fromMap을 사용하여 Firestore나 다른 데이터 소스에서 받아온 데이터를 AlarmMessage 객체로 변환
  factory AlarmMessage.fromMap(Map<String, dynamic> data) {
    final rawTimestamp = data['timestamp'];

    DateTime parsedTimestamp;
    if (rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    } else if (rawTimestamp is String) {
      parsedTimestamp = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else {
      parsedTimestamp = DateTime.now(); // fallback
    }

    return AlarmMessage(
      alarm: data['alarm'] as String,
      mac: data['mac'] as String,
      timestamp: parsedTimestamp,
    );
  }


  // AlarmMessage 객체를 Map으로 변환하여 저장할 때 사용
  Map<String, dynamic> toMap() {
    return {
      'alarm': alarm,
      'mac': mac,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
