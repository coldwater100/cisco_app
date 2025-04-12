class BleLocation {
  final double lat;
  final double lng;
  final double x;
  final double y;
  final String nearestApMac;
  final String mac;
  final int nearestApRssi;

  BleLocation({
    required this.lat,
    required this.lng,
    required this.x,
    required this.y,
    required this.nearestApMac,
    required this.mac,
    required this.nearestApRssi,
  });

  // Firestore에서 데이터를 받아오기 위한 팩토리 메서드
  factory BleLocation.fromMap(Map<String, dynamic> data) {
    return BleLocation(
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      x: (data['x'] as num).toDouble(),
      y: (data['y'] as num).toDouble(),
      nearestApMac: data['nearestApMac'] as String,
      mac: data['mac'] as String,
      nearestApRssi: data['nearestApRssi'] as int,
    );
  }
}
