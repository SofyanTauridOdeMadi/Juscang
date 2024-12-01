import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'beranda.dart';

const Color warnaUtama = Color(0xFF690909);
const Color warnaSekunder = Color(0xFF873A3A);

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

class _LayarMenelponState extends State<LayarMenelpon> {
  late final RtcEngine _mesinRTC;
  bool _suaraDibisukan = false;
  bool _kameraDimatikan = false;
  bool _kameraRemoteDimatikan = false;
  bool _penerimaBergabung = false;
  int? _uidLokal;
  int? _uidRemote;
  late String _idSaluran;
  Timer? _timerTimeout;
  Timer? _penghitungDurasi;
  int _durasiPanggilan = 0;
  final AudioPlayer _pemutarAudio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _putarSuaraMenunggu();
    _inisialisasiAgora();
    _aturTimerTimeout();
    _perbaruiStatus("Memulai Panggilan");

    // Tambahkan listener untuk mendeteksi perubahan status panggilan
    _setupStatusListener();
  }

  // Fungsi untuk mendengarkan perubahan status di Firebase
  void _setupStatusListener() {
    final referensiPanggilan = FirebaseDatabase.instance
        .ref('pengguna/${widget.idPemanggil}/riwayatPanggilan/${widget.idPanggilan}');

    referensiPanggilan.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        final status = data['status'] ?? '';
        print("Status diperbarui: $status");

        if (status == "Panggilan Ditolak") {
          _akhiriPanggilan("Panggilan Ditolak oleh penerima.");
        } else if (status == "Panggilan Berakhir") {
          _akhiriPanggilan("Panggilan berakhir.");
        }
      }
    });
  }

  Future<void> _putarSuaraMenunggu() async {
    await _pemutarAudio.setReleaseMode(ReleaseMode.loop);
    await _pemutarAudio.play(AssetSource('MulaiTelpon.mp3'));
  }

  void _inisialisasiAgora() async {
    const appId = '23a0ce9df3984ae08b9301627b3aed68';
    const token = "";

    _idSaluran = widget.idSaluran;

    _mesinRTC = createAgoraRtcEngine();
    await _mesinRTC.initialize(const RtcEngineContext(appId: appId));
    await _mesinRTC.enableVideo();

    _mesinRTC.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _uidLokal = connection.localUid;
          });
          print("Berhasil bergabung ke saluran: ${connection.channelId}");
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          setState(() {
            _uidRemote = uid;
            _penerimaBergabung = true;
          });
          print("Pengguna lain bergabung ke saluran dengan UID: $uid");
          _pemutarAudio.stop();
          _mulaiPenghitungDurasi();
          _perbaruiStatus("Dalam Panggilan");
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          print("Pengguna lain meninggalkan saluran dengan UID: $uid, alasan: $reason");
          if (uid == _uidRemote) {
            setState(() {
              _penerimaBergabung = false;
              _uidRemote = null;
            });

            if (reason == UserOfflineReasonType.userOfflineQuit) {
              _akhiriPanggilan("Pengguna meninggalkan panggilan.");
            } else {
              _akhiriPanggilan("Koneksi Terputus.");
            }
          }
        },
        onUserMuteVideo: (RtcConnection connection, int uid, bool muted) {
          print("Pengguna ${muted ? "mematikan" : "menyalakan"} kamera dengan UID: $uid");
          if (uid == _uidRemote) {
            setState(() {
              _kameraRemoteDimatikan = muted;
            });
            if (!muted) {
              _tampilkanBanner("Pengguna menyalakan kamera");
            } else {
              _tampilkanBanner("Pengguna mematikan kamera");
            }
          }
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
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  void _aturTimerTimeout() {
    _timerTimeout = Timer(Duration(seconds: 15), () {
      if (!_penerimaBergabung) {
        // Hentikan audio menunggu
        _pemutarAudio.stop();

        // Perbarui status di Firebase menjadi "Panggilan Tak Terjawab"
        _perbaruiStatus("Panggilan Tak Terjawab");

        // Akhiri panggilan
        _akhiriPanggilan("Panggilan tidak terjawab.");
      }
    });
  }

  void _mulaiPenghitungDurasi() {
    _penghitungDurasi = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _durasiPanggilan++;
      });
    });
  }

  String _formatDurasiPanggilan() {
    final menit = (_durasiPanggilan ~/ 60).toString().padLeft(2, '0');
    final detik = (_durasiPanggilan % 60).toString().padLeft(2, '0');
    return "$menit:$detik";
  }

  void _perbaruiStatus(String status) {
    final referensiPemanggil = FirebaseDatabase.instance
        .ref('pengguna/${widget.idPemanggil}/riwayatPanggilan/${widget.idPanggilan}');
    referensiPemanggil.update({
      'status': status,
      'waktu': DateTime.now().millisecondsSinceEpoch,
    });

    final referensiPenerima = FirebaseDatabase.instance
        .ref('pengguna/${widget.idPenerima}/riwayatPanggilan/${widget.idPanggilan}');
    referensiPenerima.update({
      'status': status,
      'waktu': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _tampilkanBanner(String pesan) {
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        content: Text(
          pesan,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: warnaUtama,
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
            child: Text(
              "Tutup",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  void _akhiriPanggilan(String pesan) {
    // Hentikan semua timer dan keluarkan pengguna dari saluran
    _penghitungDurasi?.cancel();
    _timerTimeout?.cancel();
    _mesinRTC.leaveChannel();
    _mesinRTC.release();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LayarBeranda()),
          (Route<dynamic> route) => false, // Menghapus semua layar sebelumnya
    );

    // Tampilkan pesan SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan, style: TextStyle(color: Colors.white)),
        backgroundColor: warnaUtama,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video penerima atau avatar penerima
          Positioned.fill(
            child: _penerimaBergabung
                ? (_kameraRemoteDimatikan
                ? Container(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(
                        widget.avatarPengguna ?? 'https://robohash.org/defaultset=set5',
                      ),
                      backgroundColor: warnaSekunder,
                    ),
                    SizedBox(height: 10),
                    Text(
                      widget.namaPengguna,
                      style: TextStyle(
                        color: warnaUtama,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
                : AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _mesinRTC,
                canvas: VideoCanvas(uid: _uidRemote ?? 0),
                connection: RtcConnection(channelId: _idSaluran),
              ),
            ))
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(
                      widget.avatarPengguna ?? 'https://robohash.org/defaultset=set5',
                    ),
                    backgroundColor: warnaSekunder,
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.namaPengguna,
                    style: TextStyle(
                      color: warnaUtama,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Kontrol
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _durasiPanggilan > 0
                        ? "Durasi: ${_formatDurasiPanggilan()}"
                        : "Menunggu penerima...",
                    style: TextStyle(color: Colors.white),
                  ),
                  Row(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pemutarAudio.dispose();
    _penghitungDurasi?.cancel();
    _timerTimeout?.cancel();
    _mesinRTC.leaveChannel();
    _mesinRTC.release();
    super.dispose();
  }
}