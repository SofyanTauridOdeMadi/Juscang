import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'Menelpon.dart';
import 'main.dart';

// Warna tema
const Color warnaUtama = Color(0xFF690909);
const Color warnaSekunder = Color(0xFF873A3A);
const Color warnaTeksHitam = Color(0xFF0F0F0F);

// FCM
const Map<String, dynamic> firebaseServiceAccountKey = {
  "type": "service_account",
  "project_id": "stom-juscang",
  "private_key_id": "f953e261a429a941ef55b293d58646ddcf1d95bf",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCaSFl2axeiytx3\n6jtzV348+QEoQdEE8LgikHOsuqk3olxHA9jivUcARbGLL0VQwzAWsoObb9f/e6SR\n2bQtqaZ9DvgVXMHN1/4ewJnJ701+2PhGm58TyYICmB7fvLlZ1RLnQqP9IJgz6Y6t\nmAFSPnKyoDkM3Lu/E8+6yG5FCQ4sFPP3MflIb6rMcnD0LSvOndSGkL07hiUS7sAS\nnkbNf6XvbYPL2nUvTbufTX4FNWaMIDq34Oq+a3F0x4IJzQI7mBHLp1DlXsW1VQvw\nRV6IB04/PnT4AIoaAyt7JWmg4cDMAkHV/pL8JTitUb1x9HPF506Pyx9hNrPPk1Zq\n0qcfVdO/AgMBAAECggEAAKhT8juckBritBXwi6Nq5Id9JdheudkFdNUEWAwi8WSv\nfRbZg1TrUp48eAVde4YJ0U9TyrEPXA6+M0+xJMXqNJD0UD3Z48oyUmtHMdjROJ2I\nieuLumuxpjm0deKNqm+n0wpZmLaaQPuHMrBYRp7cg3hsoHy3TAettFKV7eozj22H\nW2rcWx0AOt5a7hMdrJ/cmMsRCiaG09hkah+F1ZCXJ/Kfv2tYeJD7jc+OUxtnWnbB\nBVQpDcpk3HZiYZudBz5ppIgXqKeV90HyYKmoZweBr9VmNrV8JoQkGOESXEmby2Re\nkTIFUTAJYC0rgdFF1SJx4nH6qcjCnwgV6PeOQs2pdQKBgQDNY0v68JyTeGI2ey8a\nNHFMXRPny274ZCpx44uPG7MrWkYn2vI+oUqfSpacSUAYoYvCAgZXY8F3hXAXBpI/\n2AocNL9iaP7MpggVK85a/p3jBtrCGmwtFSfWWY4UCvJA8n7xCAStpGb9s3WqX3nu\nzkj2TmtGbX/8FpCUUVlW/dbwqwKBgQDATR/r/gZzx3LEY8hU7DGRAsyeByaUXqa8\n4Bx3t8gbupAPG52ST9azYR4ySNTeZMZkxqppaZ3Vtc9/chfDG+ZbduUja0gpx7zE\nim2dMTOD9fK+4Lx+MCtROnHoQL834N6i+POOTE+pv408b/i7+r8rjfGQ77P9PmAE\nBVHHpqlxPQKBgBq+sWgt6NWzOWbKx6lr5s0A2dS3Qu4JbRWDgerSupQMn1IVSrIp\nIqR3fAFB8JzEfIR46wZ6MPk1YRE+g9DYewiNPda8wWE4xZisKaTjvv+PJvFbq3Z7\naMKaysuFWWJnsWwFlUZfQCINOmdDI4ebSRj5wTJck+vprE4EAdQ4HcMdAoGAK4wL\nk4yF94gOBE04W4rVOqpwncSuxuCcT59MswuqRCU+ZD1ztGNiEmMGzIpTsj0N9FpM\n0uw48uFmKM00dlmGE+Zbw2aTA+sYY0WZxwQST2rN2s3XwZe054MdsmOfKc9Be5R2\nyx2a2KzpFeuhXyhMTFergY/WqZ2Lbr2ppFWof10CgYEAgq4z3bsM3CUaKNZTgA/8\nHz/pVw9XBjrmPJFbJfpvc1e64FoteU9bxX1if8e0Ir1EO7JMcvHeXhqCx4AWFwG1\nOlGP0ZWMfiCk5OAT39JWDpn3grNj+1GLcZ2XcLa0PF7/tnqxgrpzqpPqhVoxxCGx\nu7WcBF8/ji1m0jl/d4zeWoM=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-volux@stom-juscang.iam.gserviceaccount.com",
  "client_id": "111762934565070538603",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-volux%40stom-juscang.iam.gserviceaccount.com",
};

class LayarBeranda extends StatefulWidget {
  @override
  _LayarBerandaState createState() => _LayarBerandaState();
}

class _LayarBerandaState extends State<LayarBeranda> {
  final List<Map<String, dynamic>> daftarKontak = [];
  final List<Map<String, dynamic>> riwayatPanggilan = [];

  String? idPengguna;
  String? _idPanggilan;
  String? namaPengguna;
  String? avatarPengguna;
  String? statusPengguna;
  String idSaluran = ''; // Atur nilai awal default
  String idPemanggil = ''; // Atur nilai awal default

  Map<String, String> petaNamaPengguna = {}; // Menyimpan nama pengguna berdasarkan id

  @override
  void initState() {
    super.initState();
    _setupFirebaseMessaging();
    _setupFCMListener();
    _mintaIzin();
    _ambilIdPengguna();
    _muatSemuaKontak();
    _muatRiwayatPanggilan();
  }

  Future<void> _mintaIzin() async {
    await [Permission.camera, Permission.microphone, Permission.notification, Permission.bluetooth].request();
  }

  Future<void> logoutPengguna(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => AplikasiSaya()),
      );
    } catch (e) {
      print("Kesalahan saat logout: $e");
    }
  }

  Future<void> _ambilIdPengguna() async {
    SharedPreferences preferensi = await SharedPreferences.getInstance();
    idPengguna = preferensi.getString('idPengguna');
    if (idPengguna != null) {
      _muatDataPengguna(idPengguna!);
      _muatKontak();
      _muatRiwayatPanggilan();

      // Simpan token FCM setelah mendapatkan idPengguna
      await _simpanTokenFCM();
    } else {
      print("idPengguna tidak ditemukan di SharedPreferences");
    }
  }

  void _muatSemuaKontak() {
    DatabaseReference referensiPengguna = FirebaseDatabase.instance.ref('pengguna');
    referensiPengguna.onValue.listen((DatabaseEvent event) {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        setState(() {
          daftarKontak.clear();
          if (data != null) {
            data.forEach((id, nilai) {
              // Cek jika idPengguna sama dengan idPengguna saat ini, lewati
              if (id != idPengguna) {
                daftarKontak.add({
                  'idPengguna': id,
                  'namaPengguna': nilai['namaPengguna'] ?? 'Tidak diketahui',
                  'statusPengguna': nilai['statusPengguna'] ?? '',
                  'avatar': 'https://robohash.org/$id?set=set1', // Avatar menggunakan Robohash
                });
              }
            });
          }
        });
      } catch (error) {
        print("Error saat memuat semua kontak: $error");
      }
    });
  }

  void _setupFCMListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (idPengguna != null) {
        // Perbarui token FCM di Firebase Realtime Database
        await FirebaseDatabase.instance.ref('pengguna/$idPengguna').update({
          'fcmToken': newToken,
        });
        print("Token FCM diperbarui untuk $idPengguna: $newToken");
      } else {
        print("idPengguna belum ditemukan saat token FCM diperbarui");
      }
    });
  }

  Future<void> _simpanTokenFCM() async {
    try {
      // Ambil token FCM dari Firebase Messaging
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null && idPengguna != null) {
        // Simpan token FCM ke Firebase Realtime Database di bawah idPengguna
        await FirebaseDatabase.instance.ref('pengguna/$idPengguna').update({
          'fcmToken': token,
        });
        print("Token FCM berhasil disimpan untuk $idPengguna: $token");
      } else {
        print("Token FCM atau idPengguna tidak valid");
      }
    } catch (e) {
      print("Error saat menyimpan token FCM: $e");
    }
  }

  void perbaruiStatusPanggilan(
      String idSaluran,
      String idPemanggil,
      String idPenerima, {
        required String status,
      }) {
    final DatabaseReference database = FirebaseDatabase.instance.ref();

    // Simpan riwayat panggilan pemanggil
    database.child("pengguna/$idPemanggil/riwayatPanggilan/$idSaluran").set({
      'idPenerima': idPenerima,
      'status': status,
      'waktu': DateTime.now().millisecondsSinceEpoch,
    });

    // Simpan riwayat panggilan penerima
    database.child("pengguna/$idPenerima/riwayatPanggilan/$idSaluran").set({
      'idPemanggil': idPemanggil,
      'status': status,
      'waktu': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _setupFirebaseMessaging() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Meminta izin notifikasi untuk iOS
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Izin notifikasi diberikan');
    } else {
      print('Izin notifikasi tidak diberikan');
    }

    // Mendapatkan token FCM perangkat
    String? token = await messaging.getToken();
    print('FCM Token: $token');

    // Listener untuk notifikasi saat aplikasi sedang aktif
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['idSaluran'] != null) {
        _tanganiPanggilanMasuk(message.data);
      }
    });

    // Listener untuk notifikasi yang membuka aplikasi
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Pesan dibuka dari notifikasi: ${message.notification?.title}');
    });
  }

  void _tanganiPanggilanMasuk(Map<String, dynamic> data) {
    String idSaluran = data['idSaluran'];
    String idPemanggil = data['idPemanggil'];
    String namaPemanggil = data['namaPemanggil'];

    // Menampilkan dialog panggilan masuk
    _tampilkanDialogPanggilanMasuk({
      'idSaluran': idSaluran,
      'idPemanggil': idPemanggil,
      'namaPemanggil': namaPemanggil,
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Pesan diterima: ${message.data}');
      if (message.data['idSaluran'] != null) {
        _tanganiPanggilanMasuk(message.data);
      } else {
        print("Data notifikasi tidak lengkap: ${message.data}");
      }
    });
  }

  void _terimaPanggilan(String idSaluran, String idPemanggil) async {
    // Simpan status "Panggilan Diterima" ke Firebase
    final referensiRiwayat = FirebaseDatabase.instance
        .ref('pengguna/$idPengguna/riwayatPanggilan/$idSaluran');
    referensiRiwayat.update({
      'status': 'Panggilan Diterima',
    });

    // Navigasi ke layar menelpon
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LayarMenelpon(
          idPengguna: idPengguna!,
          idSaluran: idSaluran,
          idPemanggil: idPemanggil,
          idPenerima: idPengguna!,
          idPanggilan: idSaluran, // idPanggilan sama dengan idSaluran
          namaPengguna: 'Nama Pemanggil', // Ambil nama pemanggil dari data
        ),
      ),
    );
  }

  void _kirimNotifikasiPanggilanDitolak({
    required String tujuan, // Bisa token atau idPemanggil
    required String idSaluran,
    required bool menggunakanToken,
  }) async {
    try {
      String token;
      if (menggunakanToken) {
        token = tujuan;
      } else {
        // Ambil token penerima berdasarkan id jika tidak menggunakan token langsung
        token = await _ambilTokenPemanggil(tujuan);
      }

      // Kirim notifikasi menggunakan token yang telah diambil
      await kirimNotifikasi(
        token,
        "Panggilan Ditolak",
        "Panggilan Anda telah ditolak oleh penerima.",
        {
          'idSaluran': idSaluran,
          'status': 'Panggilan Ditolak',
        },
      );

      // Perbarui status panggilan di Firebase
      final referensiRiwayat = FirebaseDatabase.instance
          .ref('pengguna/$idPengguna/riwayatPanggilan/$idSaluran');
      await referensiRiwayat.update({
        'status': 'Panggilan Ditolak',
        'waktu': DateTime.now().millisecondsSinceEpoch,
      });

      print('Notifikasi penolakan berhasil dikirim.');
    } catch (e) {
      print('Error saat mengirim notifikasi penolakan: $e');
    }
  }

  void _tampilkanDialogPanggilanMasuk(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Panggilan Masuk'),
        content: Text('Anda menerima panggilan dari ${data['namaPemanggil']}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _kirimNotifikasiPanggilanDitolak(
                tujuan: data['idPemanggil'],
                idSaluran: data['idSaluran'],
                menggunakanToken: false,
              );
            },
            child: Text('Tolak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _terimaPanggilan(data['idSaluran'], data['idPemanggil']);
            },
            child: Text('Angkat'),
          ),
        ],
      ),
    );
  }

  Future<String> _ambilTokenPemanggil(String idPemanggil) async {
    final snapshot = await FirebaseDatabase.instance.ref('pengguna/$idPemanggil').get();
    if (snapshot.exists && snapshot.value is Map) {
      final data = snapshot.value as Map;
      return data['fcmToken'] ?? '';
    }
    throw Exception('Token tidak ditemukan untuk $idPemanggil');
  }

  Future<String> _ambilTokenPenerima(String idPenerima) async {
    final snapshot = await FirebaseDatabase.instance.ref('pengguna/$idPenerima').get();

    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data.containsKey('fcmToken')) {
        return data['fcmToken'] as String;
      }
    }

    throw Exception('Token tidak ditemukan untuk $idPenerima');
  }

  // Fungsi kirimNotifikasi di sini
  Future<void> kirimNotifikasi(
      String tokenPenerima, String judul, String isi, Map<String, String> map) async {
    try {
      final jsonKey = firebaseServiceAccountKey;

      // Dapatkan token otorisasi
      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': _generateJwt(jsonKey),
        },
      );

      if (response.statusCode == 200) {
        final accessToken = json.decode(response.body)['access_token'];

        // Kirim notifikasi ke FCM
        final notifikasi = {
          'message': {
            'token': tokenPenerima,
            'notification': {
              'title': judul,
              'body': isi,
            },
          },
        };

        final fcmResponse = await http.post(
          Uri.parse(
              'https://fcm.googleapis.com/v1/projects/${jsonKey['project_id']}/messages:send'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(notifikasi),
        );

        if (fcmResponse.statusCode == 200) {
          print('Notifikasi berhasil dikirim');
        } else {
          print('Gagal mengirim notifikasi: ${fcmResponse.body}');
        }
      } else {
        print('Gagal mendapatkan token: ${response.body}');
      }
    } catch (e) {
      print("Error saat mengirim notifikasi: $e");
    }
  }

  // Fungsi untuk membuat JWT
  String _generateJwt(Map<String, dynamic> jsonKey) {
    // Header dan Claims
    final claims = {
      'iss': jsonKey['client_email'],
      'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      'aud': jsonKey['token_uri'],
      'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
      'iat': (DateTime.now().millisecondsSinceEpoch ~/ 1000),
    };

    // Private Key dalam format PEM
    final privateKeyPem = jsonKey['private_key'];

    // Buat JWT menggunakan dart_jsonwebtoken
    final jwt = JWT(claims);

    // Tanda tangani JWT dengan RSA256
    final token = jwt.sign(RSAPrivateKey(privateKeyPem));

    return token;
  }

  Future<String> _ambilNamaPengguna(String id) async {
    if (petaNamaPengguna.containsKey(id)) {
      return petaNamaPengguna[id]!;
    }
    DatabaseReference referensiPengguna = FirebaseDatabase.instance.ref('pengguna/$id');
    final snapshot = await referensiPengguna.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      String nama = data['namaPengguna'] ?? 'Tidak diketahui';
      petaNamaPengguna[id] = nama;
      return nama;
    }
    return 'Tidak diketahui';
  }

  void _muatDataPengguna(String idPengguna) {
    DatabaseReference referensiPengguna = FirebaseDatabase.instance.ref('pengguna/$idPengguna');
    referensiPengguna.onValue.listen((DatabaseEvent event) {
      try {
        final dataSnapshot = event.snapshot.value;
        if (dataSnapshot != null) {
          final data = Map<String, dynamic>.from(dataSnapshot as Map);
          setState(() {
            namaPengguna = data['namaPengguna'] ?? '';
            statusPengguna = data['statusPengguna'] ?? '';
          });
        }
      } catch (error) {
        print("Error saat memuat data pengguna: $error");
      }
    });
  }

  void _muatKontak() {
    DatabaseReference referensiKontak = FirebaseDatabase.instance.ref('pengguna/$idPengguna/kontak');
    referensiKontak.onValue.listen((DatabaseEvent event) {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        setState(() {
          daftarKontak.clear();
          if (data != null) {
            data.forEach((key, value) {
              daftarKontak.add(value);
            });
          }
        });
      } catch (error) {
        print("Error saat memuat kontak: $error");
      }
    });
  }

  void _muatRiwayatPanggilan() {
    DatabaseReference referensiRiwayat = FirebaseDatabase.instance.ref('pengguna/$idPengguna/riwayatPanggilan');
    referensiRiwayat.onValue.listen((DatabaseEvent event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      setState(() {
        riwayatPanggilan.clear();
        if (data != null) {
          data.forEach((key, value) async {
            final idPemanggil = value['idPemanggil'] ?? '';
            final idPenerima = value['idPenerima'] ?? '';
            final status = value['status'] ?? '';
            final waktu = value['waktu'] ?? 0;

            // Tentukan apakah pengguna ini adalah pemanggil atau penerima
            final isPemanggil = idPengguna == idPemanggil;
            final idLawanBicara = isPemanggil ? idPenerima : idPemanggil;

            // Ambil nama pengguna lawan bicara
            String namaLawanBicara = await _ambilNamaPengguna(idLawanBicara);

            // Tambahkan data riwayat dengan nama lawan bicara
            riwayatPanggilan.add({
              'idPemanggil': idPemanggil,
              'idPenerima': idPenerima,
              'status': status,
              'waktu': waktu,
              'namaLawanBicara': namaLawanBicara,
            });
          });
        }
      });
    });
  }

  void _lakukanPanggilanCepat() {
    TextEditingController pengontrolPanggilanCepat = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Membuat Panggilan Baru'),
          content: TextField(
            controller: pengontrolPanggilanCepat,
            decoration: InputDecoration(labelText: 'Masukkan ID Pengguna'),
          ),
          actions: [
            TextButton(
              child: Text('Batal', style: TextStyle(color: warnaUtama)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: warnaUtama),
              child: Text('Panggil', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.pop(context);
                _cariDanMulaiPanggilan(pengontrolPanggilanCepat.text);
              },
            ),
          ],
        );
      },
    );
  }

  void _cariDanMulaiPanggilan(String idPenerima) {
    DatabaseReference referensiPengguna = FirebaseDatabase.instance.ref('pengguna');
    referensiPengguna
        .orderByChild('idPengguna')
        .equalTo(idPenerima)
        .once()
        .then((DatabaseEvent event) {
      if (event.snapshot.exists) {
        _mulaiPanggilan(idPenerima);
      } else {
        _tampilkanDialogPenggunaTidakDitemukan(idPenerima);
      }
    });
  }

  void _tampilkanDialogPenggunaTidakDitemukan(String idPengguna) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pengguna Tidak Ditemukan'),
          content: Text('Pengguna dengan ID $idPengguna tidak ditemukan.'),
          actions: [
            TextButton(
              child: Text('OK', style: TextStyle(color: warnaUtama)),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _tampilkanKonfirmasiPanggilan(String namaPengguna, String idPengguna) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Menelpon $namaPengguna'),
          content: Text('Apakah anda ingin menelpon $namaPengguna?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
              },
              child: Text('Batal', style: TextStyle(color: warnaUtama)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: warnaUtama),
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                _mulaiPanggilan(idPengguna); // Memulai panggilan
              },
              child: Text('Panggil', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _mulaiPanggilan(String idPenerima) async {
    // Buat idSaluran unik untuk setiap panggilan
    String idSaluran = "$idPengguna-$idPenerima";
    String idPemanggil = idPengguna!;
    String namaPenerima = await _ambilNamaPengguna(idPenerima);
    String waktuUnik = DateTime.now().millisecondsSinceEpoch.toString();
    _idPanggilan = waktuUnik; // Setel _idPanggilan di sini

    // Simpan riwayat panggilan untuk pemanggil
    final referensiRiwayatPemanggil = FirebaseDatabase.instance
        .ref('pengguna/$idPengguna/riwayatPanggilan/$_idPanggilan');

    referensiRiwayatPemanggil.set({
      'idPemanggil': idPengguna,
      'idPenerima': idPenerima,
      'status': 'Menghubungkan Panggilan',
      'waktu': DateTime.now().millisecondsSinceEpoch,
      'idSaluran': idSaluran,
    });

    // Simpan riwayat panggilan untuk penerima
    final referensiRiwayatPenerima = FirebaseDatabase.instance
        .ref('pengguna/$idPenerima/riwayatPanggilan/$_idPanggilan');

    referensiRiwayatPenerima.set({
      'idPemanggil': idPengguna,
      'idPenerima': idPenerima,
      'status': 'Menghubungkan Panggilan',
      'waktu': DateTime.now().millisecondsSinceEpoch,
      'idSaluran': idSaluran,
    });

    // Ambil FCM Token penerima
    String tokenPenerima = await _ambilTokenPenerima(idPenerima);

    // Kirim notifikasi ke penerima
    await kirimNotifikasi(
      tokenPenerima,
      "Panggilan Masuk",
      "$namaPengguna sedang menelepon Anda.",
      {
        'idSaluran': idSaluran,
        'idPemanggil': idPengguna!,
        'namaPemanggil': namaPengguna!,
      },
    );

    // Navigasi ke layar menelpon
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LayarMenelpon(
          idPengguna: idPengguna!,
          idSaluran: idSaluran,
          idPemanggil: idPemanggil,
          idPenerima: idPenerima,
          idPanggilan: _idPanggilan!,
          namaPengguna: namaPenerima,
          avatarPengguna: 'https://robohash.org/$idPenerima?set=set1',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: warnaUtama,
        leading: IconButton(
          icon: Icon(Icons.account_circle, color: Colors.white),
          onPressed: _tampilkanPengaturanProfil,
        ),
        title: Text(
          namaPengguna ?? 'Sedang memuat...',
          style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              logoutPengguna(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daftar Pengguna',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: warnaTeksHitam,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              flex: 2,
              child: daftarKontak.isNotEmpty
                  ? ListView.builder(
                itemCount: daftarKontak.length,
                itemBuilder: (context, index) {
                  final kontak = daftarKontak[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: warnaSekunder,
                      backgroundImage: NetworkImage(kontak['avatar']),
                      radius: 20,
                    ),
                    title: FutureBuilder<String>(
                      future: _ambilNamaPengguna(kontak['idPengguna']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text('Memuat...');
                        } else if (snapshot.hasError) {
                          return Text('Error');
                        } else {
                          return Text(snapshot.data ?? 'Tidak Diketahui');
                        }
                      },
                    ),
                    subtitle: Text(
                      kontak['statusPengguna'],
                      style: TextStyle(
                        color: warnaTeksHitam.withOpacity(0.6),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    onTap: () {
                      _tampilkanKonfirmasiPanggilan(kontak['namaPengguna'], kontak['idPengguna']);
                    },
                  );
                },
              )
                  : Center(
                child: Text(
                  'Tidak ada Pengguna ditemukan',
                  style: TextStyle(color: warnaTeksHitam.withOpacity(0.6)),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Riwayat Panggilan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: warnaTeksHitam,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              flex: 3,
              child: riwayatPanggilan.isNotEmpty
                  ? ListView.builder(
                itemCount: riwayatPanggilan.length,
                itemBuilder: (context, index) {
                  final panggilan = riwayatPanggilan[index];
                  final namaLawanBicara = panggilan['namaLawanBicara'] ?? 'Tidak diketahui';
                  final status = panggilan['status'] ?? 'unknown';
                  final waktu = panggilan['waktu'] ?? 0;

                  final avatarUrl = 'https://robohash.org/${panggilan['idPemanggil']}?set=set1';

                  final waktuPanggilan = DateTime.fromMillisecondsSinceEpoch(waktu);
                  final waktuFormat = '${waktuPanggilan.hour.toString().padLeft(2, '0')}:${waktuPanggilan.minute.toString().padLeft(2, '0')}';

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: warnaSekunder,
                      backgroundImage: NetworkImage(avatarUrl),
                      radius: 20,
                    ),
                    title: Text(
                      namaLawanBicara,
                      style: TextStyle(
                        color: warnaTeksHitam,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '$status. $waktuFormat',
                      style: TextStyle(
                        color: warnaTeksHitam.withOpacity(0.6),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    onTap: () {
                      // Tentukan lawan bicara berdasarkan konteks panggilan
                      final idLawanBicara = panggilan['idPemanggil'] == idPengguna
                          ? panggilan['idPenerima']
                          : panggilan['idPemanggil'];
                      final namaLawanBicara = panggilan['namaLawanBicara'] ?? 'Tidak diketahui';

                      // Tampilkan konfirmasi sebelum memulai panggilan
                      _tampilkanKonfirmasiPanggilan(namaLawanBicara, idLawanBicara);
                    },
                  );
                },
              )
                  : Center(
                child: Text(
                  'Tidak ada riwayat panggilan',
                  style: TextStyle(color: warnaTeksHitam.withOpacity(0.6)),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: warnaUtama,
        icon: Icon(Icons.add_call, color: Colors.white),
        label: Text(
          'Baru',
          style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
        ),
        onPressed: _lakukanPanggilanCepat,
      ),
    );
  }

  void _tampilkanPengaturanProfil() {
    TextEditingController namaController = TextEditingController(text: namaPengguna);
    TextEditingController statusController = TextEditingController(text: statusPengguna);

    final avatarUrl = 'https://robohash.org/$idPengguna?set=set1';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pengaturan Profil'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(avatarUrl),
                backgroundColor: Colors.transparent,
              ),
              SizedBox(height: 10),
              Text(
                'ID Pengguna: $idPengguna',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              TextField(
                controller: namaController,
                decoration: InputDecoration(labelText: 'Nama Pengguna'),
                style: TextStyle(color: warnaUtama),
              ),
              TextField(
                controller: statusController,
                decoration: InputDecoration(labelText: 'Status'),
                style: TextStyle(color: warnaUtama),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Batal', style: TextStyle(color: warnaUtama)),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: warnaUtama),
              child: Text('Simpan', style: TextStyle(color: Colors.white)),
              onPressed: () {
                FirebaseDatabase.instance.ref('pengguna/$idPengguna').update({
                  'namaPengguna': namaController.text,
                  'statusPengguna': statusController.text,
                });
                setState(() {
                  namaPengguna = namaController.text;
                  statusPengguna = statusController.text;
                });
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}