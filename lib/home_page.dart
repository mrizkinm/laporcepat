import 'package:flutter/material.dart';
import 'package:laporcepat/data_users.dart';
import 'package:laporcepat/storage_service.dart';
import 'package:laporcepat/pejabat_page.dart';
import 'package:laporcepat/pengawas_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DataUsers? loadedLogin;

  @override
  void initState() {
    super.initState();
  }

  Future<DataUsers?> _loadStoredValue() async {
    StorageService storageService = StorageService();
    return storageService.loadData('dataLogin');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DataUsers?>(
      future: _loadStoredValue(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // If the Future is still running, show a loading indicator
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // If there's an error, display an error message
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.data != null) {
          // If the data has been successfully loaded, use it
          loadedLogin = snapshot.data!;
          if (loadedLogin!.role == 'pejabat') {
            FirebaseMessaging.instance.subscribeToTopic('pejabat');
          } else {
            FirebaseMessaging.instance.unsubscribeFromTopic('pejabat');
          }
          return loadedLogin!.role == 'pengawas'
              ? const PengawasPage()
              : const PejabatPage();
        } else {
          // If the data is null, handle it according to your requirements
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.orange, size: 50),
                SizedBox(height: 10),
                Text('Tidak ada data',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
              ],
            ),
          );
        }
      },
    );
  }
}
