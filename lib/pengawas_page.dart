import 'package:firebase_messaging/firebase_messaging.dart';
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
  final colorAccent = const Color(0xff060e61);
  String? token = '';

  @override
  void initState() {
    super.initState();
    getToken();
  }

  getToken() async {
    token = await FirebaseMessaging.instance.getToken();
    // Call setState to trigger a rebuild with the updated token value
    setState(() {});
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
        body: _buildMainContent());
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
                  child: const Text('Hai Pengguna',
                      style: TextStyle(
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
              ListLaporanPage(userId: token!)
            ]),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(10),
          child: ElevatedButton(
            onPressed: () {
              _login();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorAccent,
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text(
              'Login Pejabat',
              style: TextStyle(
                color: Colors.white, // Set your desired text color
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _login() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }
}
