import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'Menelpon.dart';
import 'main.dart';

// Warna tema
const Color warnaUtama = Color(0xFF690909);
const Color warnaSekunder = Color(0xFF873A3A);
const Color warnaTeksHitam = Color(0xFF0F0F0F);

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

  Map<String, String> petaNamaPengguna = {}; // Menyimpan nama pengguna berdasarkan id

  @override
  void initState() {
    super.initState();
    _mintaIzin();
    _inisialisasiNotifikasiFCM();
    _pantauPanggilanMasuk();
    _ambilIdPengguna();
    _muatSemuaKontak();
  }

  Future<void> _mintaIzin() async {
    await [Permission.camera, Permission.microphone, Permission.notification, Permission.bluetooth].request();
  }

  Future<void> _ambilIdPengguna() async {
    SharedPreferences preferensi = await SharedPreferences.getInstance();
    idPengguna = preferensi.getString('idPengguna');
    if (idPengguna != null) {
      _muatDataPengguna(idPengguna!);
      _muatKontak();
      _muatRiwayatPanggilan();
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

  void _simpanTokenKeDatabase(String token) {
    if (idPengguna != null) {
      final tokenRef = FirebaseDatabase.instance.ref('pengguna/$idPengguna');
      tokenRef.update({'fcmToken': token});
    }
  }

  void _inisialisasiNotifikasiFCM() async {
    FirebaseMessaging pesan = FirebaseMessaging.instance;

    // Periksa izin saat ini
    NotificationSettings pengaturan = await pesan.getNotificationSettings();

    if (pengaturan.authorizationStatus == AuthorizationStatus.notDetermined) {
      // Jika izin belum ditentukan, minta izin
      pengaturan = await pesan.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (pengaturan.authorizationStatus == AuthorizationStatus.denied) {
        print("Notifikasi ditolak oleh pengguna.");
        return;
      }
    } else if (pengaturan.authorizationStatus == AuthorizationStatus.denied) {
      print("Izin notifikasi sebelumnya ditolak oleh pengguna.");
      return;
    }

    // Mendapatkan token FCM untuk mengidentifikasi perangkat
    String? token = await pesan.getToken();
    if (token != null) {
      _simpanTokenKeDatabase(token);
    }

    // Mendengarkan notifikasi saat aplikasi sedang aktif
    FirebaseMessaging.onMessage.listen((RemoteMessage pesan) {
      if (pesan.notification != null) {
        _tampilkanDialogPanggilanMasuk({
          'namaPemanggil': pesan.notification!.title,
          'idPanggilan': 'Menghubungkan Panggilan',
          'avatarPemanggil': 'default_avatar_url'
        }, 'id_panggilan_contoh');
      }
    });
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

  void _pantauPanggilanMasuk() {
    final referensiPanggilan = FirebaseDatabase.instance.ref('panggilan');
    referensiPanggilan.onChildAdded.listen((event) {
      try {
        final dataPanggilan = event.snapshot.value as Map<dynamic, dynamic>?;
        if (dataPanggilan != null &&
            dataPanggilan['status'] == 'memanggil' &&
            dataPanggilan['idPenerima'] == idPengguna) {
          _tampilkanDialogPanggilanMasuk(dataPanggilan, event.snapshot.key!);
        }
      } catch (error) {
        print("Error saat memantau panggilan masuk: $error");
      }
    });
  }

  void _tampilkanDialogPanggilanMasuk(Map dataPanggilan, String idPanggilan) {
    final referensiPanggilan = FirebaseDatabase.instance.ref('panggilan/$idPanggilan');

    referensiPanggilan.get().then((snapshot) {
      if (snapshot.exists) {
        final status = snapshot.child('status').value as String?;
        if (status == 'memanggil') {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Panggilan Masuk dari ${dataPanggilan['namaPemanggil'] ?? 'Tidak Diketahui'}'),
                actions: [
                  TextButton(
                    child: Text('Tolak', style: TextStyle(color: warnaUtama)),
                    onPressed: () {
                      _perbaruiStatusPanggilan(idPanggilan, 'Panggilan Ditolak');
                      Navigator.pop(context);
                      _tampilkanDialogPanggilanDitolak();
                    },
                  ),
                  TextButton(
                    child: Text('Terima', style: TextStyle(color: warnaUtama)),
                    onPressed: () async {
                      _perbaruiStatusPanggilan(idPanggilan, 'Panggilan Diterima');
                      Navigator.pop(context);

                      final String namaPemanggil = dataPanggilan['namaPemanggil'] ?? 'Tidak Diketahui';
                      final String avatarPemanggil = dataPanggilan['avatarPemanggil'] ?? 'https://robohash.org/default';

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LayarMenelpon(
                            idPengguna: dataPanggilan['idPemanggil'] ?? 'unknown_id',
                            idPenerima: idPengguna!,
                            idPanggilan: idPanggilan,
                            namaPengguna: namaPemanggil,
                            avatarPengguna: avatarPemanggil,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        }
      }
    });
  }

  void _tampilkanDialogPanggilanDitolak() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Panggilan Ditolak'),
        content: Text('Panggilan telah ditolak.'),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: warnaUtama)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _perbaruiStatusPanggilan(String idPanggilan, String status) async {
    final referensiPanggilan = FirebaseDatabase.instance.ref('panggilan/$idPanggilan');
    referensiPanggilan.update({'status': status});

    SharedPreferences preferensi = await SharedPreferences.getInstance();
    await preferensi.setString('statusPanggilanTerakhir', status);
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
    String namaPenerima = await _ambilNamaPengguna(idPenerima);
    String waktuUnik = DateTime.now().millisecondsSinceEpoch.toString();
    _idPanggilan = waktuUnik; // Setel _idPanggilan di sini

    final referensiRiwayatPemanggil = FirebaseDatabase.instance
        .ref('pengguna/$idPengguna/riwayatPanggilan/$_idPanggilan');

    referensiRiwayatPemanggil.set({
      'idPemanggil': idPengguna,
      'idPenerima': idPenerima,
      'status': 'Menghubungkan Panggilan',
      'waktu': DateTime.now().millisecondsSinceEpoch,
      'idSaluran': "$idPengguna-$idPenerima",
    });

    final referensiRiwayatPenerima = FirebaseDatabase.instance
        .ref('pengguna/$idPenerima/riwayatPanggilan/$_idPanggilan');

    referensiRiwayatPenerima.set({
      'idPemanggil': idPengguna,
      'idPenerima': idPenerima,
      'status': 'Menghubungkan Panggilan',
      'waktu': DateTime.now().millisecondsSinceEpoch,
      'idSaluran': "$idPengguna-$idPenerima",
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LayarMenelpon(
          idPengguna: idPengguna!,
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
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => AplikasiSaya()), // ganti MyApp dengan nama widget utama di main.dart
                    (Route<dynamic> route) => false, // Menghapus semua rute sebelumnya
              );
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
                    title: Text(
                      kontak['namaPengguna'],
                      style: TextStyle(
                        color: warnaTeksHitam,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      kontak['statusPengguna'],
                      style: TextStyle(
                        color: warnaTeksHitam.withOpacity(0.6),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    onTap: () {
                      // Tampilkan konfirmasi sebelum memulai panggilan
                      _tampilkanKonfirmasiPanggilan(kontak['namaPengguna'], kontak['idPengguna']);
                    },
                  );
                },
              )
                  : Center(
                child: Text(
                  'Tidak ada kontak ditemukan',
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