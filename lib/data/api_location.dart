class ApLocation {
  final String mac;
  final double x;
  final double y;

  ApLocation({
    required this.mac,
    required this.x,
    required this.y,
  });

  // Firestore에서 데이터를 받아오기 위한 팩토리 메서드
  factory ApLocation.fromMap(Map<String, dynamic> data) {
    return ApLocation(
      mac: data['mac'] as String,
      x: (data['x'] as num).toDouble(),
      y: (data['y'] as num).toDouble(),
    );
  }
}
