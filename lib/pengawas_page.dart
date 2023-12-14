import 'package:flutter/material.dart';
import 'package:laporcepat/add_laporan_page.dart';
import 'package:laporcepat/data_users.dart';
import 'package:laporcepat/list_laporan_page.dart';
import 'package:laporcepat/storage_service.dart';
import 'package:laporcepat/firebase_users.dart';
import 'package:laporcepat/login_page.dart';

class PengawasPage extends StatefulWidget {
  const PengawasPage({super.key});

  @override
  _PengawasPageState createState() => _PengawasPageState();
}

class _PengawasPageState extends State<PengawasPage> {
  final firebaseUsersService = FirebaseUsersService();
  DataUsers? loadedLogin;
  final colorAccent = const Color(0xff060e61);

  @override
  void initState() {
    super.initState();
  }

  Future<DataUsers?> _loadStoredValue() async {
    StorageService storageService = StorageService();
    return storageService.loadData('dataLogin');
  }

  // Stream<Map<String, dynamic>> _getDataLaporan() {
  //   if (userId != null) {
  //     return firebaseLaporanService.getDataLaporan();
  //   } else {
  //     return const Stream.empty();
  //   }
  // }

  Widget buildCard(String title, Color color) {
    return Expanded(
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        AddLaporanPage(status: title.toLowerCase())));
          },
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(Icons.brightness_1, color: color, size: 45),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: colorAccent,
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
            centerTitle: true),
        body: FutureBuilder<DataUsers?>(
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
              loadedLogin = snapshot.data;
              return _buildMainContent();
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
        ));
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(children: [
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
                child: const Text(
                    'Pilih Laporan Status yang akan di laporkan kepada Pejabat melalui tombol dibawah ini',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    )),
              ),
              Container(
                height: 150,
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    buildCard('Ringan', Colors.green),
                    buildCard('Sedang', Colors.yellow),
                    buildCard('Darurat', Colors.red),
                  ],
                ),
              ),
              ListLaporanPage(userId: loadedLogin!.userId)
            ]),
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
    );
  }

  void _logout() async {
    await firebaseUsersService.updateLogoutStatus(loadedLogin!.userId);
    StorageService storageService = StorageService();
    await storageService.removeData('dataLogin');
    await Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => LoginPage()));
  }
}
