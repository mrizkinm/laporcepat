import 'package:flutter/material.dart';
import 'package:laporcepat/list_laporan_page.dart';

class LaporanPage extends StatefulWidget {
  const LaporanPage({Key? key, required this.userId, required this.name})
      : super(key: key);

  final String userId;
  final String name;

  @override
  _LaporanPageState createState() => _LaporanPageState();
}

class _LaporanPageState extends State<LaporanPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Laporan ${widget.name}'),
          // actions: <Widget>[
          //   IconButton(
          //     icon: const Icon(Icons.refresh), // You can change the icon here
          //     onPressed: () {
          //       _getDataLaporan();
          //       setState(() {});
          //     },
          //   ),
          // ],
        ),
        body: ListLaporanPage(userId: widget.userId));
  }
}
