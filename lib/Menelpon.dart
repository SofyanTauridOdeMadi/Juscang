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
  bool _pemanggilBergabung = false;
  bool _penerimaBergabung = false;
  bool _suaraDibisukan = false;
  bool _kameraDimatikan = false;
  late String _idSaluran;
  final AudioPlayer _pemutarAudio = AudioPlayer();
  Timer? _penghitungDurasi;
  Timer? _timerTimeout;
  int _durasiPanggilan = 0;

  @override
  void initState() {
    super.initState();
    _putarSuaraMenunggu();
    _inisialisasiAgora();

    _cekPanggilanAktif(widget.idSaluran).then((panggilanAktif) {
      if (panggilanAktif) {
        _mulaiPanggilan();
      } else {
        _aturTimerTimeout();
        _putarSuaraMenunggu();
      }
    });

    FirebaseDatabase.instance
        .ref('pengguna/${widget.idPemanggil}/riwayatPanggilan/${widget.idPanggilan}')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        if (data['status'] == 'Panggilan Ditolak') {
          _akhiriPanggilan("Panggilan ditolak oleh penerima.");
        }
      }
    });

    _pengontrolAnimasi = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.9,
      upperBound: 1.0,
    )..repeat(reverse: true);
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
            _pemanggilBergabung = true;
          });
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          setState(() {
            _penerimaBergabung = true;
          });

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
        _perbaruiRiwayatStatus(widget.idPengguna, 'Panggilan Tak Terjawab');
        _perbaruiRiwayatStatus(widget.idPenerima, 'Panggilan Tak Terjawab');
      }
    });
  }

  void _mulaiPanggilan() async {
    try {
      String namaPemanggil = await Utils.ambilNamaPengguna(widget.idPemanggil);
      String namaPenerima = await Utils.ambilNamaPengguna(widget.idPenerima);

      await FirebaseDatabase.instance
          .ref('pengguna/${widget.idPemanggil}/riwayatPanggilan/${widget.idPanggilan}')
          .set({
        'idPemanggil': widget.idPemanggil,
        'namaPemanggil': namaPemanggil,
        'idPenerima': widget.idPenerima,
        'namaPenerima': namaPenerima,
        'idSaluran': widget.idSaluran,
        'status': 'Menghubungkan Panggilan',
        'waktu': DateTime.now().millisecondsSinceEpoch,
      });

      await FirebaseDatabase.instance
          .ref('pengguna/${widget.idPenerima}/riwayatPanggilan/${widget.idPanggilan}')
          .set({
        'idPemanggil': widget.idPemanggil,
        'namaPemanggil': namaPemanggil,
        'idPenerima': widget.idPenerima,
        'namaPenerima': namaPenerima,
        'idSaluran': widget.idSaluran,
        'status': 'Menghubungkan Panggilan',
        'waktu': DateTime.now().millisecondsSinceEpoch,
      });

      _pemutarAudio.stop();
      _timerTimeout?.cancel();
      _penghitungDurasi = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _durasiPanggilan++;
        });
      });
    } catch (e) {
      print("Error saat memulai panggilan: $e");
    }
  }

  void _akhiriPanggilan(String pesan) {
    final referensiRiwayatPemanggil = FirebaseDatabase.instance
        .ref('pengguna/${widget.idPengguna}/riwayatPanggilan/${widget.idPanggilan}');
    referensiRiwayatPemanggil.update({
      'status': 'Panggilan Berakhir',
      'waktu': DateTime.now().millisecondsSinceEpoch,
    });

    final referensiRiwayatPenerima = FirebaseDatabase.instance
        .ref('pengguna/${widget.idPenerima}/riwayatPanggilan/${widget.idPanggilan}');
    referensiRiwayatPenerima.update({
      'status': 'Panggilan Berakhir',
      'waktu': DateTime.now().millisecondsSinceEpoch,
    });

    _penghitungDurasi?.cancel();
    _timerTimeout?.cancel();

    _mesinRTC.leaveChannel();
    _mesinRTC.release();

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LayarBeranda()),
      );
    }

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
    final DatabaseReference referensiPemanggil = FirebaseDatabase.instance
        .ref('pengguna/${widget.idPengguna}/riwayatPanggilan/$idSaluran');
    final DatabaseReference referensiPenerima = FirebaseDatabase.instance
        .ref('pengguna/${widget.idPenerima}/riwayatPanggilan/$idSaluran');

    final DataSnapshot snapshotPemanggil = await referensiPemanggil.get();
    final DataSnapshot snapshotPenerima = await referensiPenerima.get();

    if (snapshotPemanggil.exists && snapshotPemanggil.value != null) {
      final dataPemanggil = snapshotPemanggil.value as Map<dynamic, dynamic>;
      if (dataPemanggil['status'] == 'Menghubungkan Panggilan' ||
          dataPemanggil['status'] == 'Aktif') {
        return true;
      }
    }

    if (snapshotPenerima.exists && snapshotPenerima.value != null) {
      final dataPenerima = snapshotPenerima.value as Map<dynamic, dynamic>;
      if (dataPenerima['status'] == 'Menghubungkan Panggilan' ||
          dataPenerima['status'] == 'Aktif') {
        return true;
      }
    }

    return false;
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
            child: Stack(
              children: [
                _penerimaBergabung
                    ? AgoraVideoView(
                  controller: VideoViewController.remote(
                    rtcEngine: _mesinRTC,
                    canvas: const VideoCanvas(uid: 1),
                    connection: RtcConnection(channelId: widget.idSaluran),
                  ),
                )
                    : Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(widget.avatarPengguna ?? 'https://robohash.org/default'),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    width: 100,
                    height: 150,
                    child: _kameraDimatikan
                        ? CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(widget.avatarPengguna ?? 'https://robohash.org/default'),
                    )
                        : AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _mesinRTC,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    ),
                  ),
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