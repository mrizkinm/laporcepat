import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

class FirebaseUsersService {
  final DatabaseReference _userReference =
      FirebaseDatabase.instance.ref().child('users');

  Stream<Map<String, dynamic>> getDataPengawas() {
    try {
      StreamController<Map<String, dynamic>> controller =
          StreamController<Map<String, dynamic>>();

      _userReference.orderByChild('role').equalTo('pengawas').onValue.listen(
        (DatabaseEvent event) {
          DataSnapshot snapshot = event.snapshot;

          if (snapshot.value == null) {
            controller.add({});
          } else {
            Map<Object?, Object?> users =
                snapshot.value as Map<Object?, Object?>;
            Map<String, dynamic> usersData = Map<String, dynamic>.from(users);
            // Sorting the data by name
            List<MapEntry<String, dynamic>> sortedList = usersData.entries
                .toList()
              ..sort((a, b) => (a.value['name'] as String)
                  .compareTo(b.value['name'] as String));

            Map<String, dynamic> sortedUsersData = Map.fromEntries(sortedList);
            controller.add(sortedUsersData);
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

  // Future<Map<String, dynamic>> getDataPengawas() async {
  //   try {
  //     DatabaseEvent databaseEvent =
  //         await _userReference.orderByChild('role').equalTo('pengawas').once();
  //     DataSnapshot snapshot = databaseEvent.snapshot;
  //     if (snapshot.value == null) {
  //       return {};
  //     }
  //     Map<Object?, Object?> users = snapshot.value as Map<Object?, Object?>;
  //     // Explicitly cast usersData to Map<String, dynamic>
  //     Map<String, dynamic> usersData = Map<String, dynamic>.from(users);
  //     return usersData;
  //   } catch (e) {
  //     print("Get data error: $e");
  //     return {};
  //   }
  // }

  Future<Map<String, dynamic>> loginWithPhoneAndPassword(
      String phone, String password) async {
    try {
      // Find user by phone number
      DatabaseEvent databaseEvent =
          await _userReference.orderByChild('phone').equalTo(phone).once();
      DataSnapshot snapshot = databaseEvent.snapshot;
      if (snapshot.value == null) {
        print("User not found with phone number: $phone");
        return {};
      }

      // Check password
      Map<Object?, Object?> users = snapshot.value as Map<Object?, Object?>;
      String userId = users.keys.first.toString();
      Map<Object?, Object?> userData = users[userId] as Map<Object?, Object?>;
      // Explicitly cast userData to Map<String, dynamic>
      Map<String, dynamic> typedUserData = Map<String, dynamic>.from(userData);

      String hashedPassword = typedUserData['password'];
      Map<String, dynamic> data = {'data': typedUserData, 'userId': userId};

      // Validate password (Note: Always use a secure password hashing library in a real app)
      if (password != hashedPassword) {
        return {};
      } else {
        return data;
      }
    } catch (e) {
      print("Login error: $e");
      return {};
    }
  }

  Future<bool> updateLoginStatus(String userId) async {
    try {
      // Locate the user in the database
      DatabaseEvent databaseEvent = await _userReference.child(userId).once();
      DataSnapshot snapshot = databaseEvent.snapshot;
      if (snapshot.value == null) {
        print("User not found with ID: $userId");
        return false;
      }

      // Update the status to 1
      await _userReference.child(userId).update({"status": 1});

      print("Login status updated for user $userId");
      return true;
    } catch (e) {
      print("Error updating login status: $e");
      return false;
    }
  }

  Future<bool> updateLogoutStatus(String userId) async {
    try {
      // Locate the user in the database
      DatabaseEvent databaseEvent = await _userReference.child(userId).once();
      DataSnapshot snapshot = databaseEvent.snapshot;
      if (snapshot.value == null) {
        print("User not found with ID: $userId");
        return false;
      }

      // Update the status to 1
      await _userReference.child(userId).update({"status": 0});

      print("Login status updated for user $userId");
      return true;
    } catch (e) {
      print("Error updating login status: $e");
      return false;
    }
  }
}
