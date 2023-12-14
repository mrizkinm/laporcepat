import 'dart:async';

import 'package:flutter/material.dart';
import 'package:laporcepat/data_laporan.dart';
import 'package:laporcepat/laporan_detail_page.dart';
import 'package:laporcepat/firebase_laporan.dart';
import 'package:intl/intl.dart';

class ListLaporanPage extends StatefulWidget {
  const ListLaporanPage({Key? key, required this.userId}) : super(key: key);

  final String userId;

  @override
  _ListLaporanPageState createState() => _ListLaporanPageState();
}

class _ListLaporanPageState extends State<ListLaporanPage> {
  bool _isAscending = true;
  final firebaseLaporanService = FirebaseLaporanService();
  Map<String, dynamic> dataLaporan = {};
  final StreamController<Map<String, dynamic>> _dataController =
      StreamController<Map<String, dynamic>>();

  String formatDateString(String inputDateString) {
    DateTime inputDate = DateTime.parse(inputDateString);
    String formattedDate = DateFormat('dd MMM yyyy HH:mm').format(inputDate);
    return formattedDate;
  }

  Stream<Map<String, dynamic>> _getDataLaporan() {
    firebaseLaporanService.getDataLaporan(widget.userId).listen((data) {
      dataLaporan = data;

      // Sorting logic
      List<MapEntry<String, dynamic>> sortedList = dataLaporan.entries.toList()
        ..sort((a, b) => _isAscending
            ? a.value['tgl_lapor'].compareTo(b.value['tgl_lapor'])
            : b.value['tgl_lapor'].compareTo(a.value['tgl_lapor']));

      Map<String, dynamic> sortedData = Map.fromEntries(sortedList);

      // Update the UI with sorted data
      _dataController.add(sortedData);
    });

    return _dataController.stream;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Laporan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // Toggle the sorting order
                  _isAscending = !_isAscending;
                  _getDataLaporan();
                  setState(() {});
                },
                icon: Icon(
                  _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  color: Colors.black,
                ),
                label: const Text('Tgl Lapor',
                    style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: StreamBuilder<Map<String, dynamic>>(
              stream: _getDataLaporan(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // If the Future is still running, show a loading indicator
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  // If there's an error, display an error message
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.data!.isNotEmpty) {
                  dataLaporan = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: dataLaporan.length,
                    itemBuilder: (context, index) {
                      String key = dataLaporan.keys.elementAt(index);
                      var value = dataLaporan[key];
                      DataLaporan laporan = DataLaporan(
                        deskripsi: value?['deskripsi'] ?? '',
                        lokasi: value?['lokasi'] ?? '',
                        lokasiLat: value?['lokasi_lat'] ?? 0,
                        lokasiLng: value?['lokasi_lng'] ?? 0,
                        pelaku: value?['pelaku'] ?? '',
                        pengawas: value?['pengawas'] ?? '',
                        status: value?['status'] ?? '',
                        tglLapor: value?['tgl_lapor'] ?? '',
                        laporanId: key,
                      );

                      late Color colorStatus;

                      if (laporan.status == 'ringan') {
                        colorStatus = Colors.green;
                      } else if (laporan.status == 'sedang') {
                        colorStatus = const Color.fromARGB(255, 246, 226, 44);
                      } else {
                        colorStatus = Colors.red;
                      }

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
                                      builder: (context) => LaporanDetailPage(
                                          laporanId: laporan.laporanId))).then(
                                  (result) {
                                // This function will be called when the user pops the LaporanPage.
                                _getDataLaporan();
                                setState(() {});
                              });
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                ListTile(
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 20),
                                  leading: Icon(Icons.brightness_1,
                                      color: colorStatus, size: 30),
                                  title: Text(
                                    laporan.status.toUpperCase(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                  subtitle: Text(
                                      '${formatDateString(laporan.tglLapor)}\n${laporan.lokasi}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ),
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
                        Icon(Icons.warning, color: Colors.orange, size: 50),
                        SizedBox(height: 10),
                        Text('Tidak ada data',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 10),
                      ],
                    ),
                  );
                }
              }),
        )
      ],
    );
  }
}
