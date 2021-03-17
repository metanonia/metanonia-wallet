// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:logger/logger.dart';
import 'package:metanoniawallet/utils/scanner_utils.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'utils/detector_painters.dart';

class QRCodePage extends StatefulWidget {
  QRCodePage({this.title});
  final String title;

  @override
  State<StatefulWidget> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  List<Barcode> _scanResults;
  CameraController _camera;
  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.back;

  final BarcodeDetector _barcodeDetector =
      FirebaseVision.instance.barcodeDetector();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final CameraDescription description =
        await ScannerUtils.getCamera(_direction);

    _camera = CameraController(
      description,
      defaultTargetPlatform == TargetPlatform.iOS
          ? ResolutionPreset.low
          : ResolutionPreset.medium,
      enableAudio: false,
    );
    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      _isDetecting = true;

      ScannerUtils.detect(
        image: image,
        detectInImage: _barcodeDetector.detectInImage,
        imageRotation: description.sensorOrientation,
      ).then((dynamic results) => results as List<Barcode>).then(
        (List<Barcode> results) {
          setState(() {
            _scanResults = results
               // .where((item) => _basicAddress.hasMatch(item.displayValue))
                .toList();
          });
        },
      ).whenComplete(() {
        var msg = "";
        if (_scanResults.length > 0) {
          msg = _scanResults.first.displayValue;
          var logger = Logger();
          logger.d(msg);
          _isDetecting = true;
          Navigator.of(context).popAndPushNamed("/");
          return;
        }

        _isDetecting = false;
      });
    });
  }

  Widget _buildResults() {
    if (_scanResults == null ||
        _camera == null ||
        !_camera.value.isInitialized) {
      return Container();
    }

    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );

    return CustomPaint(
      painter: BarcodeDetectorPainter(imageSize, _scanResults),
    );
  }

  Widget _buildImage() {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: _camera == null
          ? const Center(
              child: Text('Initialising camera, please wait.'),
            )
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CameraPreview(_camera),
                _buildResults(),
              ],
            ),
    );
  }

  void _toggleCameraDirection() async {
    if (_direction == CameraLensDirection.back) {
      _direction = CameraLensDirection.front;
    } else {
      _direction = CameraLensDirection.back;
    }

    await _camera.stopImageStream();
    await _camera.dispose();

    setState(() {
      _camera = null;
    });

    _initializeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildImage(),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleCameraDirection,
        child: _direction == CameraLensDirection.back
            ? const Icon(Icons.camera_front)
            : const Icon(Icons.camera_rear),
      ),
    );
  }

  @override
  void dispose() {
    _camera.dispose().then((_) {
      _barcodeDetector.close();
    });

    super.dispose();
  }
}
