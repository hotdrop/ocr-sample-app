import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ocr_sample_app/ocr_provider.dart';

import 'common/app_logger.dart';
import 'common/app_strings.dart';

class OcrPage extends StatefulWidget {
  const OcrPage._({super.key});

  static Future<void> start(BuildContext context, {Key? key}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => OcrPage._(key: key)),
    );
  }

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  CameraController? _cameraController;
  bool _nowScanning = false;

  @override
  void initState() {
    // 端末に搭載されている利用可能なカメラレンズ情報を取得してカメラの準備をします
    availableCameras().then((value) => _preparedCamera(value));
    super.initState();
  }

  ///
  /// カメラの初期処理を行います
  ///
  void _preparedCamera(List<CameraDescription> availableCameras) {
    // リストの最初に来るものが背面カメラのようです
    final useCamera = availableCameras.first;

    // <ResolutionPreset>
    // 　カメラで読み取る画像の解像度で、veryHigh以上にしないとほぼ読み取りに失敗します。
    // 　mediumだと白紙のノートに大きく「123」と書いた物を読み取ろうとしても無理でした。
    //
    // <enableAudio>
    // 　pub.devのcameraライブラリページにあるサンプルをほぼそのまま使うと何故かマイク音声の権限許諾ダイアログも出てきてしまいます。
    // 　今回はカメラだけ許可したいのになんでやねんと調べていたらenableAudioにたどりきました。
    // 　cameraライブラリは標準でマイク音声も使うようになっているため、カメラ権限と音声マイクの権限両方許可する必要がありました。
    // 　今回はカメラ権限しか利用しないのでenableAudioはfalseに設定しています。
    _cameraController = CameraController(useCamera, ResolutionPreset.veryHigh, enableAudio: false);

    // initializeが走るとカメラ権限の許可ダイアログ処理（AndroidのRuntimePermission）が走ります。
    // PermissionHandlerなどを利用して自分で作り込む必要はありません。
    _cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      }

      // スキャン処理開始
      _scanStart(useCamera);

      setState(() {});
    }).catchError((error) {
      if (error is CameraException) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _scanStart(CameraDescription camera) async {
    _cameraController?.startImageStream((image) async {
      // カメラに映った画像がストリームで流れてくるので1度流れてきたらスキャン終了するまで止めています。
      if (_nowScanning) {
        return;
      }

      setState(() => _nowScanning = true);

      final inputImage = _processCameraImage(image, camera.sensorOrientation);
      if (inputImage != null) {
        // ここからテキストを抽出するための処理です。Google ML KitのTextRecognizerを使っていきます。
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);
        final recognizedText = await textRecognizer.processImage(inputImage);

        final firstBlockText = recognizedText.blocks.first;
        AppLogger.d('読み取った ${firstBlockText.text}');
        if (firstBlockText.text.isNotEmpty) {
          // TODO 読み取れたらストリームへ流す
          return;
        }
      }

      setState(() => _nowScanning = false);
    });
  }

  ///
  /// カメラからStreamで流れてきたイメージ情報（CameraImage）をMLKitが読めるInputImageに変換する関数です
  /// この処理はGoogleMLKitのサンプルプロジェクトのcamera_view.dartにあるものを丸ぱくりしています。
  ///
  InputImage? _processCameraImage(CameraImage image, int sensorOrientation) {
    final allBytes = WriteBuffer();
    for (var plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    // 画像の回転情報
    final imageRotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (imageRotation == null) {
      AppLogger.d('画像変換処理 InputImageRotationValueでエラー');
      return null;
    }

    // 画像フォーマット情報
    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) {
      AppLogger.d('画像変換処理 InputImageFormatValueでエラー');
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

    final inputImageData = InputImageData(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    return InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appName)),
      body: Center(
        child: Column(
          children: [
            _ViewCamera(_cameraController),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _ViewReadTextArea(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewCamera extends StatelessWidget {
  const _ViewCamera(this._cameraController, {Key? key}) : super(key: key);

  final CameraController? _cameraController;

  @override
  Widget build(BuildContext context) {
    final preparedCamera = _cameraController?.value.isInitialized ?? false;

    if (preparedCamera) {
      return SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        child: AspectRatio(
          aspectRatio: _cameraController!.value.previewSize!.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
      );
    } else {
      return SizedBox(
        height: MediaQuery.of(context).size.height / 2,
        child: const Center(
          child: SizedBox(
            height: 50,
            width: 50,
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
  }
}

class _ViewReadTextArea extends ConsumerWidget {
  const _ViewReadTextArea({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO ここリストにして、読み取ったテキストをどんどん流していく
    return Container();
  }
}
