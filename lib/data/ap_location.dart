class ApLocation {
  final String mac;
  final double x;
  final double y;
  final String areaId;
  final String areaName;
  final String division;

  ApLocation({
    required this.mac,
    required this.x,
    required this.y,
    required this.areaId,
    required this.areaName,
    required this.division,
  });

  factory ApLocation.fromMap(Map<String, dynamic> data) {
    return ApLocation(
      mac: data['mac'] as String,
      x: (data['x'] as num).toDouble(),
      y: (data['y'] as num).toDouble(),
      areaId: data['areaId'] as String,
      areaName: data['areaName'] as String,
      division: data['division'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mac': mac,
      'x': x,
      'y': y,
      'areaId': areaId,
      'areaName': areaName,
      'division': division,
    };
  }
}

