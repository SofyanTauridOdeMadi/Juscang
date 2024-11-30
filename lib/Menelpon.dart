import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'Beranda.dart';

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
  bool _penerimaBergabung = false;
  int? _uidLokal;
  int? _uidRemote;
  late String _idSaluran;
  final AudioPlayer _pemutarAudio = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _putarSuaraMenunggu();
    _inisialisasiAgora();
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
          print("onJoinChannelSuccess: UID Lokal = ${connection.localUid}");
        },
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          setState(() {
            _uidRemote = uid;
            _penerimaBergabung = true;
          });
          _pemutarAudio.stop();
          print("onUserJoined: UID Remote = $uid");
        },
        onUserOffline: (RtcConnection connection, int uid, UserOfflineReasonType reason) {
          setState(() {
            _penerimaBergabung = false;
          });
          print("onUserOffline: UID Remote = $uid");
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

  Widget _buildVideoView() {
    if (_uidRemote != null && _penerimaBergabung) {
      return Stack(
        children: [
          Expanded(
            child: AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: _mesinRTC,
                canvas: VideoCanvas(uid: _uidRemote!),
                connection: RtcConnection(channelId: _idSaluran),
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: SizedBox(
              width: 100,
              height: 150,
              child: AgoraVideoView(
                controller: VideoViewController(
                  rtcEngine: _mesinRTC,
                  canvas: VideoCanvas(uid: _uidLokal ?? 0),
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Center(
        child: CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(
            widget.avatarPengguna ?? 'https://robohash.org/default',
          ),
          backgroundColor: warnaSekunder,
        ),
      );
    }
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
          Expanded(child: _buildVideoView()),
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
                  onPressed: () => Navigator.of(context).pop(),
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
    _pemutarAudio.dispose();
    _mesinRTC.leaveChannel();
    _mesinRTC.release();
    super.dispose();
  }
}