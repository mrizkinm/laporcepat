import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:laporcepat/data_laporan.dart';
import 'package:laporcepat/data_users.dart';
import 'package:laporcepat/data_chat.dart';
import 'package:laporcepat/firebase_chat.dart';
import 'package:laporcepat/storage_service.dart';
import 'package:laporcepat/firebase_laporan.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:laporcepat/widget/zoombuttons.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class LaporanDetailPage extends StatefulWidget {
  const LaporanDetailPage(
      {Key? key,
      required this.laporanId,
      required this.userId,
      required this.nama,
      required this.role})
      : super(key: key);

  final String laporanId;
  final String userId;
  final String nama;
  final String role;

  @override
  _LaporanDetailPageState createState() => _LaporanDetailPageState();
}

class _LaporanDetailPageState extends State<LaporanDetailPage> {
  final firebaseLaporanService = FirebaseLaporanService();
  final firebaseChatService = FirebaseChatService();
  bool isLoading = true;
  bool counterRotate = false;
  List<Marker> customMarkers = <Marker>[];
  late Color colorStatus;
  final String imageUrl = 'https://laporcepat.id/index.php/image/';
  final String mapsUrl = 'https://www.google.com/maps/place/';
  final colorAccent = const Color(0xff060e61);
  Map<String, dynamic> dataLaporan = {};
  Map<String, dynamic> dataChat = {};
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String serverKey =
      'AAAAiHJkPQE:APA91bG7uwp5P_XwFEbEwur-efuejWLadqdWTUnIOa0mVDAPCSkZ822AooyjtzL5F43va9FB0NwEzfMwo5SjpufCukp8_OnpL8hvi8mzCn2oMSyOskNNrx70ITGYexue1zA5MZtFSMzz';
  final String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';
  final String topic = 'pejabat';

  Marker buildPin(LatLng point) => Marker(
        point: point,
        child: Icon(
          Icons.location_pin,
          size: 50,
          color: Colors.red,
          shadows: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5), // Shadow color
              spreadRadius: 2, // Spread radius
              blurRadius: 5, // Blur radius
              offset: const Offset(0, 3), // Offset in the x and y directions
            ),
          ],
        ),
        width: 50,
        height: 50,
      );

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.subscribeToTopic(widget.laporanId);
  }

  Future<DataUsers?> _loadStoredValue() async {
    StorageService storageService = StorageService();
    return storageService.loadData('dataLogin');
  }

  Stream<Map<String, dynamic>> _getDetailLaporan() {
    print('gg');
    return firebaseLaporanService.getDetailLaporan(widget.laporanId);
  }

  Stream<Map<String, dynamic>> _getDataChat() {
    print('wp');
    return firebaseChatService.getDataChat(widget.userId, widget.laporanId);
  }

  Future<void> _gotoMaps(lat, lng) async {
    final Uri url = Uri.parse('$mapsUrl$lat,$lng');

    if (!await launchUrl(url)) {
      debugPrint('Could not launch $url');
    }
  }

  String formatDateString(String inputDateString) {
    DateTime inputDate = DateTime.parse(inputDateString);
    String formattedDate = DateFormat('dd MMM yyyy HH:mm').format(inputDate);
    return formattedDate;
  }

  void sendMessage() async {
    if (messageController.text.isNotEmpty) {
      DateTime now = DateTime.now();
      String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      var dataInsert = {
        'tgl_chat': formattedDate,
        'text': messageController.text,
        'userId': widget.userId,
        'name': widget.nama,
        'laporanId': widget.laporanId,
        'role': widget.role
      };
      String title = 'Pesan dari ${widget.nama} (${widget.role.toUpperCase()})';
      String body = messageController.text;
      String key = dataLaporan.keys.elementAt(0);
      var value = dataLaporan[key];
      var insertResponse = await firebaseChatService.insertData(dataInsert);
      if (insertResponse != null) {
        _scrollToBottom();
        await sendNotification(title, body, value['status']);
      } else {
        showToast('Pesan gagal dikirim');
      }
      // FocusScope.of(context).unfocus();
    } else {
      showToast('Pesan harus diisi');
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(milliseconds: 10),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToUp() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 10),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> sendNotification(
      String title, String body, String currentStatus) async {
    final Map<String, dynamic> message = {
      'to': '/topics/${widget.laporanId}',
      'priority': 'high',
      'notification': {'title': title, 'body': body},
      'data': {
        'title': title,
        'body': body,
        'status': currentStatus,
        'laporanId': widget.laporanId,
        'type': 2,
        'userId': widget.userId
      }
    };

    final http.Response response = await http.post(
      Uri.parse(fcmEndpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(message),
    );

    if (response.statusCode == 200) {
      debugPrint('Response body: ${jsonEncode(message)}');
      return true;
    } else {
      debugPrint('Error Response body: ${response.body}');
      return false;
    }
  }

  Widget buildChatBubble(
      {required String sender,
      required String text,
      required String time,
      required String role}) {
    final isMe = sender == widget.nama;

    return Column(
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          // constraints: BoxConstraints(
          //   maxWidth: MediaQuery.of(context).size.width * 0.7,
          // ),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: isMe ? colorAccent : Colors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? 16.0 : 2.0),
              topRight: Radius.circular(isMe ? 2.0 : 16.0),
              bottomLeft: const Radius.circular(16.0),
              bottomRight: const Radius.circular(16.0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role == 'pengawas' ? sender : '$sender (${role.toUpperCase()})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.0,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                formatDateString(time),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10.0),
      ],
    );
  }

  void showToast(validationMessage) {
    Fluttertoast.showToast(
        msg: validationMessage,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 3,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: StreamBuilder<Map<String, dynamic>>(
              stream: _getDetailLaporan(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // If the Future is still running, show a loading indicator
                  return const Text('Detail Laporan');
                } else if (snapshot.hasError) {
                  // If there's an error, display an error message
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.data!.isNotEmpty) {
                  var dataLaporan = snapshot.data!;
                  String key = dataLaporan.keys.elementAt(0);
                  var value = dataLaporan[key];
                  if (value['status'] == 'ringan') {
                    colorStatus = Colors.green;
                  } else if (value['status'] == 'sedang') {
                    colorStatus = const Color.fromARGB(255, 246, 226, 44);
                  } else {
                    colorStatus = Colors.red;
                  }
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detail Laporan',
                              style: TextStyle(fontSize: 16),
                            ),
                            Text(
                              formatDateString(value['tgl_lapor']),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5.0),
                              decoration: BoxDecoration(
                                color: colorStatus, // Set the background color
                                borderRadius: BorderRadius.circular(
                                    5.0), // Set the border radius
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5.0),
                                child: Text(
                                  value['status'].toString().toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white, // Set the text color
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Text('Detail Laporan');
                }
              }),
        ),
        body: _buildMainContent());
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            reverse: true,
            controller: _scrollController,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: StreamBuilder<Map<String, dynamic>>(
                      stream: _getDetailLaporan(),
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
                          dataLaporan = snapshot.data!;
                          String key = dataLaporan.keys.elementAt(0);
                          var value = dataLaporan[key];
                          DataLaporan laporan = DataLaporan(
                            deskripsi: value['deskripsi'] ?? '',
                            lokasi: value['lokasi'] ?? '',
                            lokasiLat: value['lokasi_lat'] ?? 0,
                            lokasiLng: value['lokasi_lng'] ?? 0,
                            pelaku: value['pelaku'] ?? '',
                            pengawas: value['pengawas'] ?? '',
                            status: value['status'] ?? '',
                            tglLapor: value['tgl_lapor'] ?? '',
                            role: value['role'] ?? '',
                            nama: value['nama'] ?? '',
                            laporanId: key,
                          );
                          customMarkers = [
                            buildPin(
                                LatLng(laporan.lokasiLat, laporan.lokasiLng))
                          ];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pelaku',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                laporan.pelaku,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                              ),
                              const Divider(),
                              const SizedBox(height: 5),
                              const Text(
                                'Deskripsi',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                laporan.deskripsi,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                              ),
                              const Divider(),
                              const Text(
                                'Foto',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                alignment: Alignment.center,
                                child: Image.network(
                                  imageUrl + laporan.laporanId,
                                  width: 300,
                                ),
                              ),
                              const Divider(),
                              const Text(
                                'Lokasi',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                laporan.lokasi,
                                style: TextStyle(
                                    fontSize: 14, color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 300,
                                child: FlutterMap(
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                        laporan.lokasiLat, laporan.lokasiLng),
                                    initialZoom: 10,
                                    interactionOptions:
                                        const InteractionOptions(
                                      flags: ~InteractiveFlag.doubleTapZoom,
                                    ),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                      userAgentPackageName:
                                          'com.example.laporcepat',
                                      // Use the recommended flutter_map_cancellable_tile_provider package to
                                      // support the cancellation of loading tiles.
                                      tileProvider:
                                          CancellableNetworkTileProvider(),
                                    ),
                                    MarkerLayer(
                                        markers: customMarkers,
                                        rotate: counterRotate),
                                    const FlutterMapZoomButtons(
                                        // minZoom: 4,
                                        // maxZoom: 19,
                                        mini: true,
                                        padding: 5,
                                        alignment: Alignment.bottomLeft,
                                        zoomOutIcon: Icons.remove,
                                        zoomInIcon: Icons.add,
                                        zoomOutColor: Colors.white,
                                        zoomInColor: Colors.white,
                                        zoomOutColorIcon: Colors.black,
                                        zoomInColorIcon: Colors.black),
                                    RichAttributionWidget(
                                      popupInitialDisplayDuration:
                                          const Duration(seconds: 5),
                                      animationConfig: const ScaleRAWA(),
                                      showFlutterMapAttribution: false,
                                      attributions: [
                                        TextSourceAttribution(
                                          'OpenStreetMap contributors',
                                          onTap: () => (),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.map,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    _gotoMaps(
                                        laporan.lokasiLat, laporan.lokasiLng);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorAccent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  label: const Text(
                                    'Buka Maps',
                                    style: TextStyle(
                                      color: Colors
                                          .white, // Set your desired text color
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 10),
                              ],
                            ),
                          );
                        }
                      }),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: StreamBuilder<Map<String, dynamic>>(
                    stream: _getDataChat(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // If the Future is still running, show a loading indicator
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        // If there's an error, display an error message
                        return Text('Error: ${snapshot.error}');
                      } else if (snapshot.data!.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          // Check if the widget is still mounted before calling setState
                          if (mounted) {
                            messageController.clear();
                            // _scrollToBottom();
                          }
                        });
                        dataChat = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: dataChat.length,
                          itemBuilder: (context, index) {
                            String key = dataChat.keys.elementAt(index);
                            var value = dataChat[key];
                            DataChat chat = DataChat(
                              tglChat: value['tgl_chat'] ?? '',
                              text: value['text'] ?? '',
                              userId: value['userId'] ?? '',
                              name: value['name'] ?? '',
                              laporanId: value['laporanId'] ?? '',
                              role: value['role'] ?? '',
                            );
                            return buildChatBubble(
                              sender: chat.name,
                              text: chat.text,
                              time: chat.tglChat,
                              role: chat.role,
                            );
                          },
                        );
                        // return Container();
                      } else {
                        Future.delayed(const Duration(milliseconds: 10), () {
                          _scrollToUp();
                          // Handle timeout here, e.g., cancel the ongoing operation
                        });
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.message,
                                  color: Colors.orange, size: 50),
                              SizedBox(height: 10),
                              Text('Belum ada pesan',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                    controller: messageController,
                    maxLines: null, // Allows multiline input
                    keyboardType: TextInputType
                        .multiline, // Customizes keyboard for multiline input
                    textInputAction: TextInputAction
                        .newline, // Provides Enter key on the keyboard
                    decoration: const InputDecoration(
                        hintText: 'Ketik pesan',
                        border: InputBorder.none,
                        fillColor: Color(0xfff3f3f4),
                        filled: true)),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                color: colorAccent,
                onPressed: () {
                  sendMessage();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
