import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:laporcepat/data_users.dart';
import 'package:laporcepat/storage_service.dart';
import 'package:laporcepat/firebase_users.dart';
import 'package:laporcepat/laporan_page.dart';
import 'package:laporcepat/login_page.dart';

class PejabatPage extends StatefulWidget {
  const PejabatPage({super.key});

  @override
  _PejabatPageState createState() => _PejabatPageState();
}

class _PejabatPageState extends State<PejabatPage> {
  final firebaseUsersService = FirebaseUsersService();
  DataUsers? loadedLogin;
  Map<String, dynamic> dataUsers = {};
  final colorAccent = const Color(0xff060e61);
  bool _isAscending = true;
  final StreamController<Map<String, dynamic>> _dataController =
      StreamController<Map<String, dynamic>>();

  @override
  void initState() {
    super.initState();
    _loadStoredValue();
  }

  Future<void> _loadStoredValue() async {
    StorageService storageService = StorageService();
    DataUsers? result = await storageService.loadData('dataLogin');
    setState(() {
      loadedLogin = result;
    });
  }

  Stream<Map<String, dynamic>> _getDataUsers() {
    firebaseUsersService.getDataPengawas().listen((data) {
      dataUsers = data;

      // Sorting logic
      List<MapEntry<String, dynamic>> sortedList = dataUsers.entries.toList()
        ..sort((a, b) => _isAscending
            ? a.value['name'].compareTo(b.value['name'])
            : b.value['name'].compareTo(a.value['name']));

      Map<String, dynamic> sortedData = Map.fromEntries(sortedList);

      // Update the UI with sorted data
      _dataController.add(sortedData);
    });

    return _dataController.stream;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorAccent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.white, // Replace with your desired color
            BlendMode.srcIn,
          ),
          child: Image.asset(
            'assets/img/textlogo.png', // Replace with the path to your image
            height: 25, // Adjust the height as needed
          ),
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh), // You can change the icon here
            onPressed: () {
              _getDataUsers();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                      child: Text(
                          'Hai, ${loadedLogin?.name} (${loadedLogin?.role.toUpperCase()})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Pengawas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            // Toggle the sorting order
                            _isAscending = !_isAscending;
                            _getDataUsers();
                            setState(() {});
                          },
                          icon: Icon(
                            _isAscending
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.black,
                          ),
                          label: const Text('Nama',
                              style: TextStyle(color: Colors.black)),
                        )
                      ],
                    ),
                  ),
                  Container(
                      padding: const EdgeInsets.all(10),
                      child: StreamBuilder<Map<String, dynamic>>(
                          stream: _getDataUsers(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              // If the Future is still running, show a loading indicator
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              // If there's an error, display an error message
                              return Text('Error: ${snapshot.error}');
                            } else if (snapshot.data!.isNotEmpty) {
                              dataUsers = snapshot.data!;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: dataUsers.length,
                                itemBuilder: (context, index) {
                                  String key = dataUsers.keys.elementAt(index);
                                  var value = dataUsers[key];
                                  DataUsers pengawas = DataUsers(
                                    name: value?['name'] ?? '',
                                    password: value?['password'] ?? '',
                                    phone: value?['phone'] ?? '',
                                    role: value?['role'] ?? '',
                                    status: value?['status'] ?? 0,
                                    userId: key,
                                  );

                                  // Use key and value to display data in your Container
                                  return SizedBox(
                                    child: Card(
                                      // color: Colors.green,
                                      clipBehavior: Clip.hardEdge,
                                      child: InkWell(
                                        // splashColor: Colors.green.withAlpha(100),
                                        onTap: () {
                                          Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          LaporanPage(
                                                              userId: pengawas
                                                                  .userId,
                                                              name: pengawas
                                                                  .name)))
                                              .then((result) {
                                            // This function will be called when the user pops the LaporanPage.
                                            _getDataUsers();
                                            setState(() {});
                                          });
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: <Widget>[
                                            ListTile(
                                                trailing: const Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 20),
                                                leading: Icon(
                                                    Icons.brightness_1,
                                                    color: pengawas.status == 1
                                                        ? Colors.green
                                                        : Colors.grey,
                                                    size: 30),
                                                title: Text(pengawas.name),
                                                subtitle: Text(pengawas.phone)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.warning,
                                        color: Colors.orange, size: 50),
                                    SizedBox(height: 10),
                                    Text('Tidak ada data',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(height: 10),
                                  ],
                                ),
                              );
                            }
                          })),
                ],
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorAccent,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white, // Set your desired text color
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    await FirebaseMessaging.instance.unsubscribeFromTopic('pejabat');
    await firebaseUsersService.updateLogoutStatus(loadedLogin!.userId);
    StorageService storageService = StorageService();
    await storageService.removeData('dataLogin');
    await Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }
}
