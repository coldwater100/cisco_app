import 'package:cloud_firestore/cloud_firestore.dart';

class OtpLookupService {
  static Future<Map<String, dynamic>?> fetchLocationByOtp(String otp) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('macOtpPairs')
          .where('otp', isEqualTo: otp)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final data = snapshot.docs.first.data();
      final mac = data['mac'];

      if (mac == null) return null;

      final docId = 'unknown_$mac';
      final locationSnapshot = await FirebaseFirestore.instance.collection('locations').doc(docId).get();

      if (!locationSnapshot.exists) return {'mac': mac, 'apRssiPairs': []};

      final locData = locationSnapshot.data();
      final rssiList = (locData?['rssiRecords'] as List?)?.map((e) => {
        'apMac': e['apMac'],
        'rssi': e['rssi'],
      }).toList();

      return {
        'mac': mac,
        'apRssiPairs': rssiList ?? [],
      };
    } catch (e) {
      print('❌ 오류 발생: $e');
      return null;
    }
  }
}
