import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rtl_controller_finder/screens/device_screen.dart';
import 'package:rtl_controller_finder/utils/extra.dart';
import 'package:rtl_controller_finder/utils/snackbar.dart';
import 'package:rtl_controller_finder/widgets/scan_result_tile.dart';
import 'package:avatar_glow/avatar_glow.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  bool _animate = true;

  @override
  void initState() {
    super.initState();

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      if (mounted) {
        setState(() {});
      }
    }, onError: (e) {
      Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    // try {
    //   _systemDevices = await FlutterBluePlus.systemDevices;
    // } catch (e) {
    //   Snackbar.show(ABC.b, prettyException("System Devices Error:", e),
    //       success: false);
    // }

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Start Scan Error:", e),
          success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e),
          success: false);
    }
  }

  void onConnectPressed(BluetoothDevice device) {
    device.connectAndUpdateStream().catchError((e) {
      Snackbar.show(ABC.c, prettyException("Connect Error:", e),
          success: false);
    });
    MaterialPageRoute route = MaterialPageRoute(
        builder: (context) => DeviceScreen(device: device),
        settings: const RouteSettings(name: '/DeviceScreen'));
    Navigator.of(context).push(route);
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(const Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return AvatarGlow(
        animate: _animate,
        glowColor: Colors.grey.shade700,
        child: IconButton(
          onPressed: () {
            setState(() => _animate = false);
            onStopPressed();
          },
          iconSize: 25.0,
          icon: const Icon(
            Icons.pause_rounded,
            color: Colors.white,
          ),
        ),
      );

      // FloatingActionButton(
      //   child: Icon(
      //     Icons.bluetooth_searching,
      //     size: 50,
      //     color: Colors.grey[600],
      //   ),
      // child: Image.asset(
      //   'assets/images/banlaw_logo.png',
      //   height: 50,
      //   color: Colors.grey[700],
      // ),
      // onPressed: onStopPressed,
      //   backgroundColor: Colors.grey.shade300,
      //   shape: CircleBorder(),
      // );
    } else {
      return FloatingActionButton(
          backgroundColor: Colors.grey.shade200,
          shape: const CircleBorder(),
          onPressed: () {
            setState(() => _animate = true);
            onScanPressed();
          },
          child: ImageIcon(
            const AssetImage('assets/images/banlaw_logo.png'),
            size: 50,
            color: Colors.grey[700],
          ));
    }
  }

  // List<Widget> _buildSystemDeviceTiles(BuildContext context) {
  //   return _systemDevices
  //       .map(
  //         (d) => SystemDeviceTile(
  //           device: d,
  //           onOpen: () => Navigator.of(context).push(
  //             MaterialPageRoute(
  //               builder: (context) => DeviceScreen(device: d),
  //               settings: RouteSettings(name: '/DeviceScreen'),
  //             ),
  //           ),
  //           onConnect: () => onConnectPressed(d),
  //         ),
  //       )
  //       .toList();
  // }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () => onConnectPressed(r.device),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyB,
      child: Scaffold(
        backgroundColor: Colors.grey[300],
        appBar: AppBar(
          title: const Text(
            'RTL Controller Finder',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.grey[400],
        ),
        body: RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: <Widget>[
              // ..._buildSystemDeviceTiles(context),
              ..._buildScanResultTiles(context),
            ],
          ),
        ),
        floatingActionButton: buildScanButton(context),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
