import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class FirebaseLaporanService {
  final DatabaseReference _userReference =
      FirebaseDatabase.instance.ref().child('laporan');

  Future<String?> insertData(Map data) async {
    try {
      var reference = _userReference.push();
      await reference.set(data);
      return reference.key;
    } catch (e) {
      print("Insert error: $e");
      return null;
    }
  }

  Stream<Map<String, dynamic>> getDetailLaporan(String lapId) {
    try {
      StreamController<Map<String, dynamic>> controller =
          StreamController<Map<String, dynamic>>();
      _userReference.orderByKey().equalTo(lapId).onValue.listen(
        (DatabaseEvent event) {
          DataSnapshot snapshot = event.snapshot;
          if (snapshot.value == null) {
            controller.add({});
          } else {
            Map<Object?, Object?> data =
                snapshot.value as Map<Object?, Object?>;
            // Explicitly cast usersData to Map<String, dynamic>
            Map<String, dynamic> lapData = Map<String, dynamic>.from(data);

            controller.add(lapData);
          }
        },
        onError: (error) {
          print("Get data error: $error");
          controller.addError(error);
        },
      );
      return controller.stream;
    } catch (e) {
      print("Get data error: $e");
      return Stream.value({});
    }
  }

  Stream<Map<String, dynamic>> getDataLaporan(String userId) {
    try {
      StreamController<Map<String, dynamic>> controller =
          StreamController<Map<String, dynamic>>();
      _userReference.orderByChild('pengawas').equalTo(userId).onValue.listen(
        (DatabaseEvent event) {
          DataSnapshot snapshot = event.snapshot;
          if (snapshot.value == null) {
            controller.add({});
          } else {
            Map<Object?, Object?> data =
                snapshot.value as Map<Object?, Object?>;
            // Explicitly cast usersData to Map<String, dynamic>
            Map<String, dynamic> lapData = Map<String, dynamic>.from(data);

            List<MapEntry<String, dynamic>> sortedList = lapData.entries
                .toList()
              ..sort((a, b) => (b.value['tgl_lapor'] as String)
                  .compareTo(a.value['tgl_lapor'] as String));

            Map<String, dynamic> sortedLapData = Map.fromEntries(sortedList);
            controller.add(sortedLapData);
          }
        },
        onError: (error) {
          print("Get data error: $error");
          controller.addError(error);
        },
      );
      return controller.stream;
    } catch (e) {
      print("Get data error: $e");
      return Stream.value({});
    }
  }

  // Future<Map<String, dynamic>> getDataLaporan(String userId) async {
  //   try {
  //     DatabaseEvent databaseEvent =
  //         await _userReference.orderByChild('pengawas').equalTo(userId).once();
  //     DataSnapshot snapshot = databaseEvent.snapshot;
  //     if (snapshot.value == null) {
  //       return {};
  //     }
  //     Map<Object?, Object?> data = snapshot.value as Map<Object?, Object?>;
  //     // Explicitly cast usersData to Map<String, dynamic>
  //     Map<String, dynamic> lapData = Map<String, dynamic>.from(data);
  //     return lapData;
  //   } catch (e) {
  //     print("Get data error: $e");
  //     return {};
  //   }
  // }
}
