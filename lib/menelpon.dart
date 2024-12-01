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
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          setState(() {
            _uidRemote = uid;
            _penerimaBergabung = true;
          });
          _pemutarAudio.stop();
          _mulaiPenghitungDurasi();
          _perbaruiStatus("Dalam Panggilan");
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          setState(() {
            _penerimaBergabung = false;
            _uidRemote = null;
          });
        },
        onUserMuteVideo: (RtcConnection connection, int uid, bool muted) {
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
        _pemutarAudio.stop();
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
    _perbaruiStatus("Panggilan Berakhir");
    _penghitungDurasi?.cancel();
    _timerTimeout?.cancel();
    _mesinRTC.leaveChannel();
    _mesinRTC.release();

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LayarBeranda()));

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