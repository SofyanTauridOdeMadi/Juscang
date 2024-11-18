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

  const LayarMenelpon({
    Key? key,
    required this.idPengguna,
    required this.idPenerima,
    required this.idPanggilan,
    this.namaPengguna = '???',
    this.avatarPengguna,
  }) : super(key: key);

  @override
  _LayarMenelponState createState() => _LayarMenelponState();
}

class _LayarMenelponState extends State<LayarMenelpon>
    with SingleTickerProviderStateMixin {
  late final RtcEngine _mesinRTC;
  late AnimationController _pengontrolAnimasi;
  bool _sudahTerhubung = false;
  bool _suaraDibisukan = false;
  bool _videoAktif = false;
  late String _idPanggilan;
  late String _idSaluran;
  final AudioPlayer _pemutarAudio = AudioPlayer();
  late Timer _penghitungDurasi;
  late Timer _timerTimeout;
  int _durasiPanggilan = 0;

  @override
  void initState() {
    super.initState();
    _putarSuaraMenunggu(); // Memutar suara menunggu penerima
    _inisialisasiAgora();
    _pengontrolAnimasi = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      lowerBound: 0.9,
      upperBound: 1.0,
    )..repeat(reverse: true);
    _setTimerTimeout();
  }

  Future<void> _putarSuaraMenunggu() async {
    // Memutar suara menunggu secara berulang
    await _pemutarAudio.setReleaseMode(ReleaseMode.loop); // Mengaktifkan loop
    await _pemutarAudio.play(AssetSource('MulaiTelpon.mp3'));
  }

  void _inisialisasiAgora() async {
    const appId = '23a0ce9df3984ae08b9301627b3aed68';
    const token = "";

    _idSaluran = "${widget.idPengguna}-${widget.idPenerima}";

    _mesinRTC = createAgoraRtcEngine();
    await _mesinRTC.initialize(
      const RtcEngineContext(appId: appId),
    );
    await _mesinRTC.enableVideo();
    await _mesinRTC.startPreview();

    _mesinRTC.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() {
            _sudahTerhubung = true;
          });
          _pemutarAudio.stop(); // Hentikan suara menunggu
          _mulaiPenghitungDurasi(); // Mulai hitung durasi panggilan
          _timerTimeout.cancel(); // Hentikan timer timeout jika penerima bergabung
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          setState(() {});
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          _tampilkanDialogAkhirPanggilan("Pengguna telah meninggalkan panggilan.");
        },
      ),
    );

    await _mesinRTC.joinChannel(
      token: token,
      channelId: _idSaluran,
      uid: 0,
      options: ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileCommunication,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  // Fungsi untuk memperbarui status panggilan di Firebase
  void _perbaruiRiwayatStatus(String idPengguna, String status) {
    final referensiRiwayat = FirebaseDatabase.instance
        .ref('pengguna/$idPengguna/riwayatPanggilan/${widget.idPanggilan}');
    referensiRiwayat.update({
      'status': status,
      'waktu': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void _setTimerTimeout() {
    _timerTimeout = Timer(Duration(seconds: 15), () {
      if (!_sudahTerhubung) {
        _pemutarAudio.stop(); // Hentikan suara menunggu
        _akhiriPanggilan(); // Akhiri panggilan
        _perbaruiRiwayatStatus(widget.idPengguna, 'Panggilan Tak Terjawab');
        _perbaruiRiwayatStatus(widget.idPenerima, 'Panggilan Tak Terjawab');
        _tampilkanDialogAkhirPanggilan("Panggilan tidak terjawab.");
      }
    });
  }

  void _akhiriPanggilan() {
    _penghitungDurasi.cancel();
    _timerTimeout.cancel(); // Batalkan timer timeout saat panggilan diakhiri
    _mesinRTC.leaveChannel();
    _mesinRTC.release();

    // Update status sebagai "Panggilan Berakhir"
    _perbaruiRiwayatStatus(widget.idPengguna, 'Panggilan Berakhir');
    _perbaruiRiwayatStatus(widget.idPenerima, 'Panggilan Berakhir');

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => LayarBeranda()),
    );
  }

  void _mulaiPenghitungDurasi() {
    _penghitungDurasi = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _durasiPanggilan++;
      });
    });
  }

  void _ubahStatusSuara() {
    setState(() => _suaraDibisukan = !_suaraDibisukan);
    _mesinRTC.muteLocalAudioStream(_suaraDibisukan);
  }

  void _ubahStatusVideo() {
    setState(() => _videoAktif = !_videoAktif);
    _mesinRTC.muteLocalVideoStream(!_videoAktif);
  }

  Future<void> _putarSuaraAkhirPanggilan() async {
    await _pemutarAudio.setReleaseMode(ReleaseMode.stop); // Hentikan loop
    await _pemutarAudio.play(AssetSource('SelesaiTelpon.mp3'));
  }

  String _formatDurasiPanggilan() {
    final menit = (_durasiPanggilan / 60).floor().toString().padLeft(2, '0');
    final detik = (_durasiPanggilan % 60).toString().padLeft(2, '0');
    return "$menit:$detik";
  }

  Widget _tampilkanVideo() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: _mesinRTC,
          canvas: const VideoCanvas(uid: 0),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: warnaUtama,
        title: Text(widget.idPengguna == widget.idPenerima ? '${widget.namaPengguna}' : '${widget.namaPengguna}'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: _sudahTerhubung
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Durasi Panggilan: ${_formatDurasiPanggilan()}',
                  style: TextStyle(
                    color: warnaTeksHitam,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _videoAktif
                    ? Expanded(child: _tampilkanVideo())
                    : CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.transparent,
                  backgroundImage: widget.avatarPengguna != null
                      ? NetworkImage(widget.avatarPengguna!)
                      : NetworkImage(
                      'https://robohash.org/${widget.idPenerima}?set=set1'),
                ),
                Text(
                  '${widget.namaPengguna}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: warnaTeksHitam,
                  ),
                ),
              ],
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          Divider(),
          _tampilkanTombolKontrol(),
        ],
      ),
    );
  }

  Widget _tampilkanTombolKontrol() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(_suaraDibisukan ? Icons.mic_off : Icons.mic, color: warnaUtama),
            onPressed: _ubahStatusSuara,
          ),
          IconButton(
            icon: Icon(
              _videoAktif ? Icons.videocam : Icons.videocam_off,
              color: warnaUtama,
            ),
            onPressed: _ubahStatusVideo,
          ),
          IconButton(
            icon: Icon(Icons.call_end, color: warnaUtama),
            onPressed: () async {
              await _putarSuaraAkhirPanggilan(); // Memutar suara akhir panggilan
              await Future.delayed(Duration(seconds: 1));
              _akhiriPanggilan(); // Akhiri panggilan setelah delay
            },
          ),
        ],
      ),
    );
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
              _akhiriPanggilan();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _penghitungDurasi.cancel();
    _timerTimeout.cancel();
    _pemutarAudio.dispose();
    _mesinRTC.leaveChannel();
    _mesinRTC.release();
    _pengontrolAnimasi.dispose();
    super.dispose();
  }
}