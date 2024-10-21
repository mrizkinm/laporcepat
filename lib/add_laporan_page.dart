import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:laporcepat/storage_service.dart';
import 'package:laporcepat/firebase_laporan.dart';
import 'package:laporcepat/data_users.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:laporcepat/widget/zoombuttons.dart';
import 'package:geocoding/geocoding.dart';

class AddLaporanPage extends StatefulWidget {
  const AddLaporanPage({Key? key, required this.status}) : super(key: key);

  final String status;

  @override
  _AddLaporanPageState createState() => _AddLaporanPageState();
}

class _AddLaporanPageState extends State<AddLaporanPage> {
  String? currentStatus;
  final _formKey = GlobalKey<FormBuilderState>();
  bool counterRotate = false;
  late Color colorStatus;
  List<Marker> customMarkers = <Marker>[];
  late LatLng latlng;
  final firebaseLaporanService = FirebaseLaporanService();
  final colorAccent = const Color(0xff060e61);
  final String serverKey =
      'AAAAiHJkPQE:APA91bG7uwp5P_XwFEbEwur-efuejWLadqdWTUnIOa0mVDAPCSkZ822AooyjtzL5F43va9FB0NwEzfMwo5SjpufCukp8_OnpL8hvi8mzCn2oMSyOskNNrx70ITGYexue1zA5MZtFSMzz';
  final String fcmEndpoint = 'https://fcm.googleapis.com/fcm/send';
  final String topic = 'pejabat';
  final String apiUrl = 'https://laporcepat.id/index.php/upload/image';
  late LocationPermission _permission;
  MapController mapController = MapController();
  File? _image;
  bool isLoading = false;
  final TextEditingController searchController = TextEditingController();
  String? token = '';

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
    getToken();
    currentStatus = widget.status;
    if (currentStatus == 'ringan') {
      colorStatus = Colors.green;
    } else if (currentStatus == 'sedang') {
      colorStatus = const Color.fromARGB(255, 246, 226, 44);
    } else {
      colorStatus = Colors.red;
    }
    _checkPermission();
  }

  getToken() async {
    token = await FirebaseMessaging.instance.getToken();
    // Call setState to trigger a rebuild with the updated token value
    setState(() {});
  }

  Future<void> _pickImages(int source) async {
    XFile? pickedFile;
    if (source == 1) {
      pickedFile = await ImagePicker().pickImage(
        imageQuality: 70,
        source: ImageSource.gallery,
      );
    } else {
      pickedFile = await ImagePicker().pickImage(
        imageQuality: 50,
        source: ImageSource.camera,
      );
    }

    setState(() {
      if (pickedFile != null) {
        File imageFile = File(pickedFile.path);
        int fileSizeInBytes = imageFile.lengthSync();
        double fileSizeInKB = fileSizeInBytes / 1024; // Convert to KB

        // debugPrint('File size: $fileSizeInKB KB');

        // Set your maximum allowed file size
        double maxFileSizeAllowedInKB = 5120;

        if (fileSizeInKB > maxFileSizeAllowedInKB) {
          showToast('Ukuran maksimal file 5 MB');
          // You can handle this case, e.g., show a warning to the user
        } else {
          _image = File(pickedFile.path);
        }
      } else {
        showToast('No image selected');
      }
    });
  }

  Future<void> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    setState(() {
      _permission = permission;
    });
  }

  Future<void> _requestPermission() async {
    if (_permission == LocationPermission.denied ||
        _permission == LocationPermission.deniedForever) {
      LocationPermission permission = await Geolocator.requestPermission();
      setState(() {
        _permission = permission;
      });
    }
  }

  Future<void> _getLocation() async {
    if (_permission == LocationPermission.denied ||
        _permission == LocationPermission.deniedForever) {
      await _requestPermission();
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      double latitude = position.latitude;
      double longitude = position.longitude;

      goToLocation(latitude, longitude);
      var latLng = LatLng(latitude, longitude);
      addMarker(latLng);
      // searchByLatLang(latitude, longitude);
    } catch (e) {
      showToast('Error getting location: $e');
    }
  }

  void goToLocation(double latitude, double longitude) {
    mapController.move(
        LatLng(latitude, longitude), 14.0); // Use the desired zoom level
  }

  Future<bool> sendNotification(String title, String body, String nama,
      String role, String laporanId) async {
    final Map<String, dynamic> message = {
      'to': '/topics/$topic',
      'priority': 'high',
      'notification': {
        'title': title,
        'body': body,
        'sound': '$currentStatus.mp3',
        'android_channel_id': 'laporcepat'
      },
      'data': {
        'title': title,
        'body': body,
        'status': currentStatus,
        'laporanId': laporanId,
        'type': 1,
        'userId': token,
        'nama': nama,
        'role': role
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

  void _showImageDetail(File image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Image.file(image),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _sendImagesToBackend(String key) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.headers['Content-Type'] = 'multipart/form-data';

      // Add the single image to the request
      if (_image != null) {
        // var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        var bytes = await _image!.readAsBytes();
        var extension = path.extension(_image!.path);
        var multipartFile = http.MultipartFile.fromBytes(
          'image', // Field name on the server
          bytes,
          filename: '$key$extension', // Default filename, customize as needed
        );
        request.files.add(multipartFile);
      }

      var response = await request.send();

      if (response.statusCode == 200) {
        debugPrint('Images uploaded successfully');
        var responseBody = await response.stream.bytesToString();
        debugPrint(responseBody);
        return responseBody;
      } else {
        debugPrint(
            'Failed to upload images. Status code: ${response.statusCode}');
        debugPrint(await response.stream.bytesToString());
        return null;
      }
    } catch (error) {
      debugPrint('Error uploading images: $error');
      return null;
    }
  }

  void addMarker(LatLng latLng) {
    setState(() {
      latlng = latLng;
      customMarkers = [buildPin(latLng)];
    });
  }

  void insertLaporan(value) async {
    if (customMarkers.isEmpty) {
      showToast('Pin Point harus dipilih');
      return;
    }
    setState(() {
      isLoading = true;
    });
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    var dataInsert = {
      'tgl_lapor': formattedDate,
      'status': currentStatus,
      'lokasi': value['lokasi'],
      'lokasi_lat': latlng.latitude,
      'lokasi_lng': latlng.longitude,
      'pelaku': value['pelaku'],
      'deskripsi': value['deskripsi'],
      'nama': value['nama'],
      'pangkat': value['pangkat'],
      'role': 'pengawas',
      'pengawas': token
    };
    var insertResponse = await firebaseLaporanService.insertData(dataInsert);
    if (insertResponse != null) {
      await _sendImagesToBackend(insertResponse);
      String title = 'Laporan dari ${value['nama']}';
      String body = """
Lokasi: ${value['lokasi']}
Deskripsi: ${value['deskripsi']}
""";
      await FirebaseMessaging.instance.subscribeToTopic(insertResponse);
      await sendNotification(
          title, body, value['nama'], value['role'], insertResponse);
      showToast('Laporan berhasil dikirim');
      Navigator.pop(context);
    } else {
      showToast('Laporan gagal dikirim');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> searchLocation() async {
    try {
      if (searchController.text.isNotEmpty) {
        List<Location> locations =
            await locationFromAddress(searchController.text);

        if (locations.isNotEmpty) {
          goToLocation(locations[0].latitude, locations[0].longitude);
          var latLng = LatLng(locations[0].latitude, locations[0].longitude);
          addMarker(latLng);
        } else {
          // Handle case when no locations are found
          showToast('Lokasi tidak ditemukan');
        }
      } else {
        showToast('Lokasi harus diisi');
      }
    } catch (e) {
      // Handle any errors that occur during geocoding
      debugPrint('Error search: $e');
      // showToast(
      //     'Tidak dapat menemukan hasil untuk alamat atau koordinat yang diberikan');
    }
  }

  Future<void> searchByLatLang(lat, lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        setState(() {
          searchController.text = placemarks[0].street!;
        });
      } else {
        // Handle case when no locations are found
        showToast('Alamat tidak ditemukan');
      }
    } catch (e) {
      // Handle any errors that occur during geocoding
      debugPrint('Error search by latlng: $e');
    }
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
        title: const Text('Tambah Laporan'),
      ),
      body: Column(
        children: [
          Expanded(
              child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(10),
            child: FormBuilder(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Status',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.all(5.0),
                          decoration: BoxDecoration(
                            color: colorStatus, // Set the background color
                            borderRadius: BorderRadius.circular(
                                5.0), // Set the border radius
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5.0),
                            child: Text(
                              '${currentStatus?.toUpperCase()}',
                              style: const TextStyle(
                                  color: Colors.white, // Set the text color
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Nama',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        FormBuilderTextField(
                            name: 'nama',
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                            decoration: const InputDecoration(
                                hintText: 'Masukkan nama',
                                border: InputBorder.none,
                                fillColor: Color(0xfff3f3f4),
                                filled: true))
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Pangkat',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        FormBuilderTextField(
                            name: 'pangkat',
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                            decoration: const InputDecoration(
                                hintText: 'Masukkan pangkat',
                                border: InputBorder.none,
                                fillColor: Color(0xfff3f3f4),
                                filled: true))
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Pelaku',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        FormBuilderTextField(
                            name: 'pelaku',
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                            decoration: const InputDecoration(
                                hintText: 'Masukkan nama pelaku',
                                border: InputBorder.none,
                                fillColor: Color(0xfff3f3f4),
                                filled: true))
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Deskripsi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        FormBuilderTextField(
                            name: 'deskripsi',
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                            decoration: const InputDecoration(
                                hintText: 'Masukkan deskripsi',
                                border: InputBorder.none,
                                fillColor: Color(0xfff3f3f4),
                                filled: true))
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                        width: MediaQuery.of(context).size.width,
                        padding: const EdgeInsets.all(5),
                        height: 150.0,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey,
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                        child: _image != null
                            ? GestureDetector(
                                onTap: () {
                                  _showImageDetail(_image!);
                                },
                                child: Image.file(
                                  _image!,
                                  height: 150.0,
                                  // fit: BoxFit.cover,
                                ),
                              )
                            : const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 40,
                                  ),
                                  Text(
                                    'Belum ada foto yang dipilih',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.image_search,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _pickImages(1);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            label: const Text(
                              'Pilih Foto',
                              style: TextStyle(
                                color:
                                    Colors.white, // Set your desired text color
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.45,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onPressed: () {
                              _pickImages(2);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            label: const Text(
                              'Ambil Foto',
                              style: TextStyle(
                                color:
                                    Colors.white, // Set your desired text color
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Lokasi',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        FormBuilderTextField(
                            controller: searchController,
                            name: 'lokasi',
                            onChanged: (value) => searchLocation(),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                            ]),
                            decoration: InputDecoration(
                              hintText: 'Masukkan alamat lokasi',
                              suffixIcon: IconButton(
                                color: Colors.black,
                                icon: const Icon(Icons.search),
                                onPressed: () {
                                  searchLocation();
                                },
                              ),
                              border: InputBorder.none,
                              fillColor: Color(0xfff3f3f4),
                              filled: true,
                            ))
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.location_pin,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          _getLocation();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorAccent,
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        label: const Text(
                          'Get My Location',
                          style: TextStyle(
                            color: Colors.white, // Set your desired text color
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300,
                      child: FlutterMap(
                        mapController: mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(-6.168329, 106.758850),
                          initialZoom: 10,
                          onTap: (_, p) => addMarker(p),
                          interactionOptions: const InteractionOptions(
                            flags: ~InteractiveFlag.doubleTapZoom,
                          ),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.laporcepat',
                            // Use the recommended flutter_map_cancellable_tile_provider package to
                            // support the cancellation of loading tiles.
                            tileProvider: CancellableNetworkTileProvider(),
                          ),
                          MarkerLayer(
                              markers: customMarkers, rotate: counterRotate),
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
                                const Duration(seconds: 1),
                            animationConfig: const ScaleRAWA(),
                            showFlutterMapAttribution: false,
                            attributions: [
                              TextSourceAttribution(
                                'OpenStreetMap contributors',
                                onTap: () => (),
                                prependCopyright: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          )),
          Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.saveAndValidate() ?? false) {
                  insertLaporan(_formKey.currentState?.value);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorAccent,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20, // Set your desired size
                      height: 20, // Set your desired size
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 3, // Set your desired stroke width
                      ),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white, // Set your desired text color
                      ),
                    ),
            ),
          )
        ],
      ),
    );
  }
}
