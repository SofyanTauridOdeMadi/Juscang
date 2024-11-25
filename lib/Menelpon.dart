import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'Beranda.dart';

const Color warnaUtama = Color(0xFF690909);
const Color warnaSekunder = Color(0xFF873A3A);
const Color warnaTeksHitam = Color(0xFF0F0F0F);

class LayarMenelpon extends StatefulWidget {
  final String idPengguna;
  final String idPenerima;
  final String idPanggilan;
  final String namaPengguna;
  final String? avatarPengguna;

  final String idPemanggil;
  final String idSaluran;

  const LayarMenelpon({
    Key? key,
    required this.idPengguna,
    required this.idSaluran,
    required this.idPemanggil,
    required this.idPenerima,
    required this.idPanggilan,
    required this.namaPengguna,
    this.avatarPengguna,
  }) : super(key: key);

  @override
  _LayarMenelponState createState() => _LayarMenelponState();
}

class _LayarMenelponState extends State<LayarMenelpon> with SingleTickerProviderStateMixin {
  late final RtcEngine _mesinRTC;
  late AnimationController _pengontrolAnimasi;
  bool _pemanggilBergabung = false; // Status pemanggil bergabung
  bool _penerimaBergabung = false; // Status penerima bergabung
  bool _suaraDibisukan = false; // Status suara dimatikan
  bool _kameraDimatikan = false; // Status kamera dimatikan
  late String _idSaluran;
  final AudioPlayer _pemutarAudio = AudioPlayer();
  Timer? _penghitungDurasi; // Timer untuk durasi panggilan
  Timer? _timerTimeout; // Timer untuk timeout
  int _durasiPanggilan = 0;

  @override
  void initState() {
    super.initState();
    _putarSuaraMenunggu();
    _inisialisasiAgora();

    _cekPanggilanAktif(widget.idSaluran).then((panggilanAktif) {
      if (panggilanAktif) {
        // Jika panggilan sudah aktif, langsung sambungkan
        _mulaiPanggilan();
      } else {
        // Jika belum ada panggilan aktif, buat yang baru
        _aturTimerTimeout();
        _putarSuaraMenunggu();
      }
    });

    _aturTimerTimeout(); // Mulai timeout saat inisialisasi
    _pengontrolAnimasi = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.9,
      upperBound: 1.0,
    )..repeat(reverse: true);
  }

  Future<void> _putarSuaraMenunggu() async {
    // Memutar suara menunggu secara berulang
    await _pemutarAudio.setReleaseMode(ReleaseMode.loop);
    await _pemutarAudio.play(AssetSource('MulaiTelpon.mp3'));
  }

  void _inisialisasiAgora() async {
    const appId = '23a0ce9df3984ae08b9301627b3aed68';
    const token = "";

    _idSaluran = widget.idSaluran; // Gunakan idSaluran dari widget

    _mesinRTC = createAgoraRtcEngine();
    await _mesinRTC.initialize(const RtcEngineContext(appId: appId));
    await _mesinRTC.enableVideo();

    _mesinRTC.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _pemanggilBergabung = true;
          });
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          setState(() {
            _penerimaBergabung = true;
          });

          // Jika kedua pihak bergabung, mulai panggilan
          if (_pemanggilBergabung && _penerimaBergabung) {
            _mulaiPanggilan();
          }
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          _akhiriPanggilan("Pengguna telah meninggalkan panggilan.");
        },
      ),
    );

    await _mesinRTC.joinChannel(
      token: token,
      channelId: _idSaluran,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  void _aturTimerTimeout() {
    _timerTimeout = Timer(Duration(seconds: 20), () {
      if (!_penerimaBergabung) {
        _pemutarAudio.stop();
        _akhiriPanggilan("Panggilan tidak terjawab.");
        _perbaruiRiwayatStatus(widget.idPengguna, 'Panggilan Tak Terjawab');
        _perbaruiRiwayatStatus(widget.idPenerima, 'Panggilan Tak Terjawab');
      }
    });
  }

  void _mulaiPanggilan() {
    _pemutarAudio.stop();
    _timerTimeout?.cancel();
    _penghitungDurasi = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _durasiPanggilan++;
      });
    });

    // Perbarui status di Firebase
    final referensiPanggilan = FirebaseDatabase.instance.ref('panggilanAktif/${widget.idSaluran}');
    referensiPanggilan.set({
      'status': 'Aktif',
      'idSaluran': widget.idSaluran,
      'idPemanggil': widget.idPengguna,
      'idPenerima': widget.idPenerima,
      'waktuMulai': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _akhiriPanggilan(String pesan) {
    final referensiPanggilan = FirebaseDatabase.instance.ref('panggilanAktif/${widget.idSaluran}');
    referensiPanggilan.remove(); // Hapus panggilan dari Firebase
    _penghitungDurasi?.cancel(); // Hentikan timer durasi
    _timerTimeout?.cancel(); // Hentikan timer timeout
    _mesinRTC.leaveChannel(); // Keluar dari channel
    _mesinRTC.release(); // Lepaskan RTC resources

    // Perbarui status ke Firebase
    _perbaruiRiwayatStatus(widget.idPengguna, 'Panggilan Berakhir');
    _perbaruiRiwayatStatus(widget.idPenerima, 'Panggilan Berakhir');

    // Kembali ke halaman beranda
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LayarBeranda()),
      );
    }

    // Tampilkan dialog akhir jika ada pesan
    if (pesan.isNotEmpty) {
      _tampilkanDialogAkhirPanggilan(pesan);
    }
  }

  void _perbaruiRiwayatStatus(String idPengguna, String status) {
    final referensiRiwayat = FirebaseDatabase.instance
        .ref('pengguna/$idPengguna/riwayatPanggilan/${widget.idPanggilan}');
    referensiRiwayat.update({
      'status': status,
      'waktu': DateTime.now().millisecondsSinceEpoch,
    });
  }

  String _formatDurasiPanggilan() {
    final menit = (_durasiPanggilan / 60).floor().toString().padLeft(2, '0');
    final detik = (_durasiPanggilan % 60).toString().padLeft(2, '0');
    return "$menit:$detik";
  }

  Future<bool> _cekPanggilanAktif(String idSaluran) async {
    final DatabaseReference referensiPanggilan = FirebaseDatabase.instance.ref('panggilanAktif/$idSaluran');
    final DataSnapshot snapshot = await referensiPanggilan.get();
    return snapshot.exists;
  }

  Future<void> _tampilkanDialogAkhirPanggilan(String pesan) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Panggilan Berakhir'),
        content: Text(pesan),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: warnaUtama)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: warnaUtama,
        title: Text(widget.namaPengguna),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: warnaSekunder,
                  backgroundImage: widget.avatarPengguna != null
                      ? NetworkImage(widget.avatarPengguna!)
                      : AssetImage('assets/default_avatar.png') as ImageProvider,
                ),
                SizedBox(height: 18),
                _pemanggilBergabung && _penerimaBergabung
                    ? Text(
                  'Durasi Panggilan: ${_formatDurasiPanggilan()}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                )
                    : Text(
                  'Menunggu penerima bergabung...',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _suaraDibisukan ? Icons.mic_off : Icons.mic,
                    color: warnaUtama,
                  ),
                  onPressed: () {
                    setState(() {
                      _suaraDibisukan = !_suaraDibisukan;
                    });
                    _mesinRTC.muteLocalAudioStream(_suaraDibisukan);
                  },
                ),
                IconButton(
                  icon: Icon(
                    _kameraDimatikan ? Icons.videocam_off : Icons.videocam,
                    color: warnaUtama,
                  ),
                  onPressed: () {
                    setState(() {
                      _kameraDimatikan = !_kameraDimatikan;
                    });
                    _mesinRTC.muteLocalVideoStream(_kameraDimatikan);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.call_end, color: warnaUtama),
                  onPressed: () => _akhiriPanggilan("Panggilan diakhiri."),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _penghitungDurasi?.cancel();
    _timerTimeout?.cancel();
    _pemutarAudio.dispose();
    _mesinRTC.leaveChannel();
    _mesinRTC.release();
    _pengontrolAnimasi.dispose();
    super.dispose();
  }
}