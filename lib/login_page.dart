import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:laporcepat/data_users.dart';
import 'package:laporcepat/storage_service.dart';
import 'package:laporcepat/home_page.dart';
import 'package:laporcepat/widget/bezier_container.dart';
import 'package:laporcepat/firebase_users.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool isLoading = false;
  final firebaseUsersService = FirebaseUsersService();
  final colorAccent = const Color(0xff060e61);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
        body: SizedBox(
      child: Stack(
        children: <Widget>[
          Positioned(
              top: -height * .15,
              right: -MediaQuery.of(context).size.width * .4,
              child: const BezierContainer()),
          Container(
            padding: const EdgeInsets.all(20),
            child: FormBuilder(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: height * .2),
                    _title(),
                    // const SizedBox(height: 20),
                    _emailPasswordWidget(),
                    const SizedBox(height: 20),
                    _submitButton(),
                    // Container(
                    //   padding: const EdgeInsets.symmetric(vertical: 10),
                    //   alignment: Alignment.centerRight,
                    //   child: const Text('Forgot Password?',
                    //       style: TextStyle(
                    //           fontSize: 14, fontWeight: FontWeight.w500)),
                    // )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _title() {
    // return RichText(
    //   textAlign: TextAlign.center,
    //   text: TextSpan(
    //       text: 'LAPOR ',
    //       style: TextStyle(
    //           fontSize: 30, fontWeight: FontWeight.w700, color: colorAccent),
    //       children: [
    //         TextSpan(
    //           text: 'CEPAT',
    //           style: TextStyle(color: Color(0xffffaa02), fontSize: 30),
    //         ),
    //       ]),
    // );
    return Image.asset(
      'assets/img/logo.png',
      width: 200,
    );
  }

  Widget _emailPasswordWidget() {
    return Column(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'No. Hp',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(
                height: 10,
              ),
              FormBuilderTextField(
                  name: 'phone',
                  obscureText: false,
                  keyboardType: TextInputType.phone,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                  decoration: const InputDecoration(
                      hintText: 'Masukkan No. Hp',
                      border: InputBorder.none,
                      fillColor: Color(0xfff3f3f4),
                      filled: true,
                      prefixIcon: Icon(Icons.phone)))
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(
                height: 10,
              ),
              FormBuilderTextField(
                  name: 'password',
                  obscureText: true,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                  ]),
                  decoration: const InputDecoration(
                      hintText: 'Masukkan Password',
                      border: InputBorder.none,
                      fillColor: Color(0xfff3f3f4),
                      filled: true,
                      prefixIcon: Icon(Icons.lock)))
            ],
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: ElevatedButton(
        onPressed: () {
          if (_formKey.currentState?.saveAndValidate() ?? false) {
            _sendDataToApi(_formKey.currentState?.value);
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
                'Login',
                style: TextStyle(
                  color: Colors.white, // Set your desired text color
                ),
              ),
      ),
    );
  }

  void _sendDataToApi(value) async {
    setState(() {
      isLoading = true;
    });

    // Simulasi verifikasi login (ganti dengan logika yang sesuai)

    // if (usernameController.text == '08123456789' &&
    //     passwordController.text == '123456') {
    //   DataLogin dataToSave =
    //       DataLogin(phone: '08123456789', name: 'Joni Susilo', role: 'PENGAWAS');
    //   await StorageService.saveData('dataLogin', dataToSave);
    //   Navigator.pushReplacementNamed(context, '/home');
    // } else if (usernameController.text == '08987654321' &&
    //     passwordController.text == '123456') {
    //   DataLogin dataToSave = DataLogin(
    //       phone: '08987654321', name: 'Yudi Kurniawan', role: 'PEJABAT');
    //   await StorageService.saveData('dataLogin', dataToSave);
    //   Navigator.pushReplacementNamed(context, '/home');
    // } else {
    //   // Login gagal, tampilkan pesan atau lakukan tindakan yang sesuai
    //   showToast('No. Hp atau password salah');
    // }
    var service = await firebaseUsersService.loginWithPhoneAndPassword(
        value['phone'], value['password']);
    if (service.isNotEmpty) {
      DataUsers dataToSave = DataUsers(
          name: service['data']['name'],
          password: service['data']['password'],
          phone: service['data']['phone'],
          role: service['data']['role'],
          status: service['data']['status'],
          userId: service['userId']);
      StorageService storageService = StorageService();
      await storageService.saveData('dataLogin', dataToSave);
      await firebaseUsersService.updateLoginStatus(service['userId']);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    } else {
      showToast('No. Hp atau password salah');
    }

    setState(() {
      isLoading = false;
    });
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
}
