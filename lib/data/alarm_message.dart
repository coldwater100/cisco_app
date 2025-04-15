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
    String rawTimestampString = rawTimestamp.toString();
    rawTimestampString = rawTimestampString.replaceAll(' UTC+9', '');
    rawTimestampString = rawTimestampString.replaceFirst(RegExp(r'\d{4}년 '), '');


    return AlarmMessage(
      mac: data['mac'] ?? '',
      alarm: data['alarm'] ?? '',
      formattedTime: rawTimestampString);
  }
}


