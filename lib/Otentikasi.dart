import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'Beranda.dart';

class LayarOtentikasi extends StatefulWidget {
  @override
  _LayarOtentikasiState createState() => _LayarOtentikasiState();
}

class _LayarOtentikasiState extends State<LayarOtentikasi> {
  final FirebaseAuth _otentikasi = FirebaseAuth.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _kunciForm = GlobalKey<FormState>();
  final TextEditingController _penggunaController = TextEditingController();
  final TextEditingController _kataSandiController = TextEditingController();

  // Warna kustom dan font untuk konsistensi
  final Color warnaUtama = Color(0xFF690909);
  final Color warnaLatar = Color(0xFFCEB9BA);
  final Color warnaIsiInput = Color(0xFFF5F5F5);

  bool _modeMasuk = true;
  String _pesanKesalahan = '';

  // Fungsi untuk mengganti mode formulir antara masuk dan daftar
  void _gantiModeFormulir() {
    setState(() {
      _modeMasuk = !_modeMasuk;
      _pesanKesalahan = ''; // Reset pesan kesalahan ketika mengganti mode
    });
  }

  Future<void> _kirimFormulir() async {
    if (!_kunciForm.currentState!.validate()) return;

    try {
      UserCredential kredensialPengguna;
      final idPengguna = _penggunaController.text.trim();

      if (_modeMasuk) {
        // Validasi email menggunakan domain khusus
        final email = '$idPengguna@juscang.id';
        kredensialPengguna = await _otentikasi.signInWithEmailAndPassword(
          email: email,
          password: _kataSandiController.text,
        );
      } else {
        // Validasi apakah ID pengguna sudah ada
        final snapshot = await _database.child('pengguna/$idPengguna').get();
        if (snapshot.exists) {
          setState(() {
            _pesanKesalahan = "ID Pengguna sudah digunakan.";
          });
          return;
        }

        // Buat akun baru
        final email = '$idPengguna@juscang.id';
        kredensialPengguna = await _otentikasi.createUserWithEmailAndPassword(
          email: email,
          password: _kataSandiController.text,
        );

        // Tambahkan data pengguna ke database
        await _database.child('pengguna/$idPengguna').set({
          'idPengguna': idPengguna,
          'namaPengguna': kredensialPengguna.user?.email,
          'status': 'online',
        });
      }

      // Simpan data pengguna ke SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('idPengguna', idPengguna);

      // Navigasikan ke beranda
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LayarBeranda()),
      );
    } catch (e) {
      setState(() {
        _pesanKesalahan = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _kunciForm,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _modeMasuk ? 'MASUK' : 'DAFTAR',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: warnaUtama,
                    fontFamily: 'Poppins',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _modeMasuk
                      ? 'Selamat datang kembali!\nSaling Berkomunikasi Antar Perangkat'
                      : 'Buatlah akun agar dapat\nSaling Berkomunikasi Antar Perangkat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _penggunaController,
                  decoration: InputDecoration(
                    labelText: 'ID Pengguna',
                    filled: true,
                    fillColor: warnaIsiInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (nilai) {
                    if (nilai == null || nilai.isEmpty) {
                      return 'Masukkan ID Pengguna Anda';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _kataSandiController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Kata Sandi',
                    filled: true,
                    fillColor: warnaIsiInput,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (nilai) {
                    if (nilai == null || nilai.length < 6) {
                      return 'Kata sandi minimal 6 karakter';
                    }
                    return null;
                  },
                ),
                if (!_modeMasuk)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi',
                        filled: true,
                        fillColor: warnaIsiInput,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (nilai) {
                        if (nilai != _kataSandiController.text) {
                          return 'Kata sandi tidak sesuai';
                        }
                        return null;
                      },
                    ),
                  ),
                SizedBox(height: 16),
                if (_pesanKesalahan.isNotEmpty)
                  Text(
                    _pesanKesalahan,
                    style: TextStyle(color: Colors.red),
                  ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _kirimFormulir,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: warnaUtama,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text(
                    _modeMasuk ? 'MASUK' : 'DAFTAR',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _gantiModeFormulir,
                  child: Text(
                    _modeMasuk ? 'Belum punya akun? Daftar' : 'Sudah punya akun? Masuk',
                    style: TextStyle(
                      color: Colors.black87,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}