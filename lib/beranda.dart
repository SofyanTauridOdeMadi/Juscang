import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'menelpon.dart';
import 'main.dart';
import 'utils.dart';

// Warna tema
const Color warnaUtama = Color(0xFF690909);
const Color warnaSekunder = Color(0xFF873A3A);
const Color warnaTeksHitam = Color(0xFF0F0F0F);


class LayarBeranda extends StatefulWidget {
  @override
  _LayarBerandaState createState() => _LayarBerandaState();
}

class Utils {
  static Future<String> ambilNamaPengguna(String idPengguna) async {
    final ref = FirebaseDatabase.instance.ref('pengguna/$idPengguna');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      return data['namaPengguna'] ?? 'Tidak diketahui';
    } else {
      return 'Tidak ditemukan';
    }
  }

  static Future<String> ambilTokenPenerima(String idPenerima) async {
    final ref = FirebaseDatabase.instance.ref('pengguna/$idPenerima/Token');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      return snapshot.value.toString(); // Mengembalikan token FCM
    } else {
      print("Token FCM untuk ID penerima ($idPenerima) tidak ditemukan.");
      return ""; // Kembalikan string kosong jika token tidak ditemukan
    }
  }
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

  bool _dialogPanggilanAktif = false;

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await FirebaseAuth.instance.signOut(); // Pastikan logout selesai

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => AplikasiSaya()),
          (Route<dynamic> route) => false, // Menghapus semua rute sebelumnya
    );
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
                  'avatar': 'https://robohash.org/$id?set=set5', // Avatar menggunakan Robohash
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
          'Token': newToken,
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
          'Token': token,
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
      if (_dialogPanggilanAktif) {
        print("Dialog sudah aktif, mengabaikan notifikasi.");
        return; // Abaikan jika dialog sedang aktif
      }

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

  void tolakPanggilan(String idSaluran, String idPemanggil, String idPenerima) async {
    try {
      // Ambil nama pengguna untuk pemanggil
      String namaPemanggil = await _ambilNamaPengguna(idPemanggil);

      // Ambil nama pengguna untuk penerima
      String namaPenerima = await _ambilNamaPengguna(idPenerima);

      // Perbarui status panggilan di database
      DatabaseReference referensiPanggilanPemanggil = FirebaseDatabase.instance
          .ref('pengguna/$idPemanggil/riwayatPanggilan/$idSaluran');
      await referensiPanggilanPemanggil.update({
        'status': 'Panggilan Ditolak',
        'namaPenerima': namaPenerima,
        'namaPemanggil': namaPemanggil,
      });

      DatabaseReference referensiPanggilanPenerima = FirebaseDatabase.instance
          .ref('pengguna/$idPenerima/riwayatPanggilan/$idSaluran');
      await referensiPanggilanPenerima.update({
        'status': 'Panggilan Ditolak',
        'namaPenerima': namaPenerima,
        'namaPemanggil': namaPemanggil,
      });

      print("Panggilan dengan saluran $idSaluran ditolak.");
    } catch (e) {
      print("Error saat menolak panggilan: $e");
    }
  }

// Fungsi untuk mengambil nama pengguna berdasarkan ID pengguna
  Future<String> _ambilNamaPengguna(String idPengguna) async {
    try {
      DatabaseReference referensiPengguna = FirebaseDatabase.instance.ref('pengguna/$idPengguna');
      final snapshot = await referensiPengguna.get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data['namaPengguna'] ?? 'Tidak diketahui';
      } else {
        return 'Tidak ditemukan';
      }
    } catch (e) {
      print("Error saat mengambil nama pengguna: $e");
      return 'Tidak ditemukan';
    }
  }

  void _terimaPanggilan(String idSaluran, String idPemanggil) async {
    try {
      // Ambil nama pemanggil dari Firebase
      final DataSnapshot snapshotPemanggil = await FirebaseDatabase.instance
          .ref('pengguna/$idPemanggil/namaPengguna')
          .get();

      String namaPemanggil = snapshotPemanggil.exists
          ? snapshotPemanggil.value.toString()
          : 'Nama Tidak Diketahui';

      // Simpan status "Panggilan Diterima" ke Firebase
      final referensiRiwayat = FirebaseDatabase.instance
          .ref('pengguna/$idPengguna/riwayatPanggilan/$idSaluran');
      await referensiRiwayat.update({
        'status': 'Panggilan Diterima',
      });

      // Reset flag dialog saat berpindah layar
      _dialogPanggilanAktif = false;

      // Navigasi ke layar menelpon dengan UID dan informasi pengguna
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LayarMenelpon(
            idPengguna: idPengguna!, // ID lokal pengguna
            idSaluran: idSaluran,   // Saluran Agora
            idPemanggil: idPemanggil, // ID pemanggil
            idPenerima: idPengguna!, // ID penerima
            idPanggilan: idSaluran, // ID panggilan (bisa sama dengan saluran)
            namaPengguna: namaPemanggil, // Nama dinamis dari pemanggil
            avatarPengguna: null, // Tambahkan avatar jika tersedia
          ),
        ),
      );
    } catch (e) {
      print("Error saat menerima panggilan: $e");
    }
  }

  void _tampilkanDialogPanggilanMasuk(Map<String, dynamic> data) async {
    // Cek apakah dialog sudah aktif
    if (_dialogPanggilanAktif) {
      print("Dialog panggilan masuk sudah aktif. Mengabaikan notifikasi berikutnya.");
      return; // Jangan tampilkan dialog jika sudah ada
    }

    _dialogPanggilanAktif = true; // Tandai bahwa dialog aktif
    String namaPemanggil = data['namaPemanggil'] ?? await _ambilNamaPengguna(data['idPemanggil']);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('Panggilan Masuk'),
          content: Text('Anda menerima panggilan dari $namaPemanggil'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                tolakPanggilan(data['idSaluran'], data['idPemanggil'], idPengguna!);
                _dialogPanggilanAktif = false;
              },
              child: Text('Tolak', style: TextStyle(color: warnaUtama)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _dialogPanggilanAktif = false; // Reset flag setelah dialog ditutup
                _terimaPanggilan(data['idSaluran'], data['idPemanggil']);
              },
              style: ElevatedButton.styleFrom(backgroundColor: warnaUtama),
              child: Text('Terima', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
          title: Text('Panggilan Baru'),
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
    try {
      // Ambil nama pemanggil dan penerima
      String namaPemanggil = await _ambilNamaPengguna(idPengguna!);
      String namaPenerima = await _ambilNamaPengguna(idPenerima);

      // Buat idSaluran unik
      String idSaluran = "$idPengguna-$idPenerima-${DateTime.now().millisecondsSinceEpoch}";
      _idPanggilan = "$idPengguna-$idPenerima-${DateTime.now().millisecondsSinceEpoch}";

      // Simpan riwayat panggilan untuk pemanggil
      final referensiRiwayatPemanggil = FirebaseDatabase.instance
          .ref('pengguna/$idPengguna/riwayatPanggilan/$_idPanggilan');
      await referensiRiwayatPemanggil.set({
        'idPemanggil': idPengguna,
        'namaPemanggil': namaPemanggil, // Nama pemanggil
        'idPenerima': idPenerima,
        'namaPenerima': namaPenerima, // Nama penerima
        'status': 'Menghubungkan Panggilan',
        'waktu': DateTime.now().millisecondsSinceEpoch,
        'idSaluran': idSaluran,
      });

      // Simpan riwayat panggilan untuk penerima
      final referensiRiwayatPenerima = FirebaseDatabase.instance
          .ref('pengguna/$idPenerima/riwayatPanggilan/$_idPanggilan');
      await referensiRiwayatPenerima.set({
        'idPemanggil': idPengguna,
        'namaPemanggil': namaPemanggil, // Nama pemanggil
        'idPenerima': idPenerima,
        'namaPenerima': namaPenerima, // Nama penerima
        'status': 'Menghubungkan Panggilan',
        'waktu': DateTime.now().millisecondsSinceEpoch,
        'idSaluran': idSaluran,
      });

      // Ambil FCM Token penerima
      String tokenPenerima = await Utils.ambilTokenPenerima(idPenerima);

      // Kirim notifikasi ke penerima
      await kirimNotifikasi(
        tokenPenerima,
        "Panggilan Masuk",
        "$namaPemanggil sedang menelepon Anda.",
        {
          'idSaluran': idSaluran,
          'idPemanggil': idPengguna!,
          'namaPemanggil': namaPemanggil,
        },
      );

      // Navigasi ke layar menelpon
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LayarMenelpon(
            idPengguna: idPengguna!,
            idSaluran: idSaluran,
            idPemanggil: idPengguna!,
            idPenerima: idPenerima,
            idPanggilan: _idPanggilan!,
            namaPengguna: namaPenerima,
            avatarPengguna: 'https://robohash.org/$idPenerima?set=set5',
          ),
        ),
      );
    } catch (e) {
      print("Error saat memulai panggilan: $e");
    }
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

                  final avatarUrl = 'https://robohash.org/${panggilan['idPemanggil']}?set=set5';

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

    final avatarUrl = 'https://robohash.org/$idPengguna?set=set5';

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