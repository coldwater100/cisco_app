import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AlarmMessage {
  final String mac;
  final String alarm;
  // final DateTime timestamp;
  final String formattedTime;

  AlarmMessage({
    required this.mac,
    required this.alarm,
    // required this.timestamp,
    required this.formattedTime,
  });

  factory AlarmMessage.fromMap(Map<String, dynamic> data) {
    final rawTimestamp = data['timestamp'];
    DateTime parsedTimestamp;
    print("<<<<rawTimeStamp in fromMap" + rawTimestamp.toString());
    if (rawTimestamp != null && rawTimestamp is Timestamp) {
      parsedTimestamp = rawTimestamp.toDate();
    } else {
      // 적절한 예외 처리 또는 로그 출력
      print("rawTimestamp가 null이거나 Timestamp 타입이 아닙니다.");
    }

    // if (rawTimestamp is Timestamp) {
    //   parsedTimestamp = rawTimestamp.toDate();
    // } else {
    //   parsedTimestamp = rawTimestamp.toString() as DateTime;
    // }
    // print("<<<<parsedTimeStamp" + parsedTimestamp.toString());

    return AlarmMessage(
      mac: data['mac'] ?? '',
      alarm: data['alarm'] ?? '',
      // timestamp: parsedTimestamp.toLocal(),
      // formattedTime: DateFormat.Hms().format(parsedTimestamp.toLocal()),
      formattedTime: rawTimestamp.toString());
  }
}


