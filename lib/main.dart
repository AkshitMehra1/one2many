import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_ion/flutter_ion.dart' as ion;
import 'package:uuid/uuid.dart';
import 'dart:developer';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test1',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Test1'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Participant {
  Participant(this.title, this.renderer, this.stream);
  MediaStream? stream;
  String title;
  RTCVideoRenderer renderer;
}

class _MyHomePageState extends State<MyHomePage> {
//publish function
  List<Participant> plist = <Participant>[];
  bool isPub = false;

  RTCVideoRenderer _localRender = RTCVideoRenderer();
  RTCVideoRenderer _remoteRender = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    initRender();
    initSfu();
  }

  initRender() async {
    await _localRender.initialize();
    await _remoteRender.initialize();
  }

  getUrl() {
    if (kIsWeb) {
      return ion.GRPCWebSignal('http://localhost:9090');
    } else {
      setState(() {
        isPub = true;
      });
      return ion.GRPCWebSignal('http://192.168.29.209:9090');
    }
  }

  ion.Signal? _signal;
  ion.Client? _client;
  ion.LocalStream? _localStream;
  final String _uuid = Uuid().v4();

  initSfu() async {
    final _signal = await getUrl();
    _client =
        await ion.Client.create(sid: "TEST ROOM", uid: _uuid, signal: _signal);
    if (isPub == false) {
      _client?.ontrack = (track, ion.RemoteStream remoteStream) async {
        if (track.kind == 'video') {
          print('ontrack: remote stream => ${remoteStream.id}');
          setState(() {
            _remoteRender.srcObject = remoteStream.stream;
          });
        }
      };
    }
  }
  //publish wala

  void publish() async {
    _localStream = await ion.LocalStream.getUserMedia(
        constraints: ion.Constraints.defaults..simulcast = false);

    setState(() {
      _localRender.srcObject = _localStream?.stream;
    });

    await _client?.publish(_localStream!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[getVideoView()],
        ),
      ),
      floatingActionButton:
          getFab(), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  //video view

  Widget getVideoView() {
    if (isPub == true) {
      return Expanded(
        child: RTCVideoView(_localRender),
      );
    } else {
      return Expanded(
        child: RTCVideoView(_remoteRender),
      );
    }
  }

  Widget getFab() {
    if (isPub == false) {
      return Container();
    } else {
      return FloatingActionButton(
          onPressed: publish, child: const Icon(Icons.video_call));
    }
  }
}
