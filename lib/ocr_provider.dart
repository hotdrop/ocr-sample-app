import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final _textRecognizerProvider = Provider((_) => TextRecognizer(script: TextRecognitionScript.japanese));

final cameraImageProvider = Provider((ref) => _CameraImageProvider(ref.read));

class _CameraImageProvider {
  const _CameraImageProvider(this._read);

  final Reader _read;

  ///
  /// カメラからStreamで流れてきたイメージ情報（CameraImage）をMLKitが読めるInputImageに変換する関数です
  /// この処理はGoogleMLKitのサンプルプロジェクトのcamera_view.dartにあるものを参考にしています。
  ///
  Future<void> process({required CameraImage cameraImage, required int sensorOrientation, required Function onComplete}) async {
    final bytes = _createBytesFromImage(cameraImage);

    final inputImageData = _createInputImageData(cameraImage, sensorOrientation);
    if (inputImageData != null) {
      final inputImage = InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

      // Google ML KitのTextRecognizerを使って画像からテキストを検出します。
      final textRecognizer = _read(_textRecognizerProvider);
      final recognizedText = await textRecognizer.processImage(inputImage);

      if (recognizedText.blocks.isNotEmpty) {
        final firstBlockText = recognizedText.blocks.first.text;
        _read(readTextSNProvider.notifier).add(firstBlockText);
      }
    }

    onComplete();
  }

  Uint8List _createBytesFromImage(CameraImage image) {
    final allBytes = WriteBuffer();
    for (var plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  InputImageData? _createInputImageData(CameraImage image, int sensorOrientation) {
    // 画像の回転情報
    final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (imageRotation == null) {
      return null;
    }

    // 画像フォーマット情報
    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) {
      return null;
    }

    // 画像のプレーン情報
    final planeData = image.planes
        .map((plane) => InputImagePlaneMetadata(
              bytesPerRow: plane.bytesPerRow,
              height: plane.height,
              width: plane.width,
            ))
        .toList();

    return InputImageData(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );
  }
}

final readTextSNProvider = StateNotifierProvider<_ReadTextsStateNotifer, List<String>>((_) {
  return _ReadTextsStateNotifer([]);
});

class _ReadTextsStateNotifer extends StateNotifier<List<String>> {
  _ReadTextsStateNotifer(super.state);

  void add(String text) {
    state = [text, ...state];
  }
}
