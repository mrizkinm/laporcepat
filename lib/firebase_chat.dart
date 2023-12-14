import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class FirebaseChatService {
  final DatabaseReference _userReference =
      FirebaseDatabase.instance.ref().child('chat');

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

  Stream<Map<String, dynamic>> getDataChat(String userId, String lapId) {
    try {
      StreamController<Map<String, dynamic>> controller =
          StreamController<Map<String, dynamic>>();
      _userReference
          // .orderByChild('userId')
          // .equalTo(userId)
          .orderByChild('laporanId')
          .equalTo(lapId)
          .onValue
          .listen(
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
              ..sort((a, b) => (a.value['tgl_chat'] as String)
                  .compareTo(b.value['tgl_chat'] as String));

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
}
