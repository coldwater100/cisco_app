import 'package:cloud_firestore/cloud_firestore.dart';

class BleLocation {
  final double? lat;
  final double? lng;
  final double? x;
  final double? y;
  final String? nearestApMac;
  final String? clientMac;
  final int? rssi;
  final DateTime? timestamp;
  final DateTime? startTime;
  final DateTime? endTime;

  BleLocation({
    this.lat,
    this.lng,
    this.x,
    this.y,
    this.nearestApMac,
    this.clientMac,
    this.rssi,
    this.timestamp,
    this.startTime,
    this.endTime,
  });

  static DateTime? _parseTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  factory BleLocation.fromMap(Map<String, dynamic> data) {
    final location = data['location'] as Map<String, dynamic>?;

    return BleLocation(
      lat: location?['latitude']?.toDouble(),
      lng: location?['longitude']?.toDouble(),
      x: location?['x']?.toDouble(),
      y: location?['y']?.toDouble(),
      nearestApMac: data['nearestApMac'] as String?,
      clientMac: data['clientMac'] as String?,
      rssi: data['rssi'] as int?,
      timestamp: _parseTimestamp(data['timestamp']),
      startTime: _parseTimestamp(data['startTime']),
      endTime: _parseTimestamp(data['endTime']),
    );
  }

  @override
  String toString() {
    return 'BLE(lat: $lat, lng: $lng, x: $x, y: $y, nearestAp: $nearestApMac, mac: $clientMac, rssi: $rssi)';
  }
}

