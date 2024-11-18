import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Beranda.dart';
import 'Otentikasi.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
    );
  }

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(AplikasiSaya());
}

// Definisi warna sesuai dengan palet yang diinginkan
const Color warnaUtama = Color(0xFF690909);
const Color warnaSekunder = Color(0xFF873A3A);
const Color warnaKetiga = Color(0xFF855052);
const Color warnaTeksUtama = Color(0xFF690909);
const Color warnaTeksSekunder = Color(0xFF625D5D);
const Color warnaTeksHitam = Color(0xFF0F0F0F);

class AplikasiSaya extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Juscang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: warnaUtama,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: warnaTeksUtama),
          bodyMedium: TextStyle(color: warnaTeksSekunder),
          headlineLarge: TextStyle(color: warnaUtama),
          headlineSmall: TextStyle(color: warnaTeksHitam),
        ),
        buttonTheme: ButtonThemeData(
          buttonColor: warnaUtama,
          textTheme: ButtonTextTheme.primary,
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: warnaUtama,
          secondary: warnaSekunder,
        ),
      ),
      home: LayarSplash(),
    );
  }
}

class LayarSplash extends StatefulWidget {
  @override
  _LayarSplashState createState() => _LayarSplashState();
}

class _LayarSplashState extends State<LayarSplash> with SingleTickerProviderStateMixin {
  late AnimationController _pengontrolAnimasi;
  late Animation<double> _animasiFade;

  @override
  void initState() {
    super.initState();
    _pengontrolAnimasi = AnimationController(
      duration: Duration(seconds: 5),
      vsync: this,
    );
    _animasiFade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _pengontrolAnimasi,
      curve: Curves.easeIn,
    ));
    _pengontrolAnimasi.forward();
    Timer(Duration(seconds: 5), () {
      _periksaStatusLogin();
    });
  }

  Future<void> _periksaStatusLogin() async {
    User? pengguna = FirebaseAuth.instance.currentUser;

    // Log untuk memastikan kode mencapai bagian ini
    print("Memeriksa status login...");

    if (!mounted) return; // Pastikan widget masih aktif sebelum melanjutkan

    if (pengguna != null) {
      // Jika pengguna sudah login, navigasikan ke `LayarBeranda`
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LayarBeranda()),
      );
    } else {
      // Jika pengguna belum login, navigasikan ke `LayarOtentikasi`
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LayarOtentikasi()),
      );
    }
  }


  @override
  void dispose() {
    _pengontrolAnimasi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: FadeTransition(
            opacity: _animasiFade,
            child: Container(
              width: 256,
              height: 256,
              child: Image.asset('assets/logo.png'),
            ),
          ),
        ),
      ),
    );
  }
}