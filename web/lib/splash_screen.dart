import 'package:flutter/material.dart';
import 'main.dart'; // NoteListPage sınıfının tanımlı olduğu dosyayı import ediyoruz

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    await Future.delayed(Duration(seconds: 2), () {});
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => NoteListPage()), // NoteListPage sınıfını kullanıyoruz
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'Not Defteri',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
      ),
    );
  }
}
