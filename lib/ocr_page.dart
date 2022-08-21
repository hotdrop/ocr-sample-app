import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ocr_sample_app/ocr_provider.dart';

import 'common/app_strings.dart';

class OcrPage extends ConsumerStatefulWidget {
  const OcrPage._({super.key});

  static Future<void> start(BuildContext context, {Key? key}) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => OcrPage._(key: key)),
    );
  }

  @override
  ConsumerState<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends ConsumerState<OcrPage> {
  CameraController? _cameraController;
  bool _processing = false;

  @override
  void initState() {
    super.initState();

    // 端末に搭載されている利用可能なカメラレンズ情報を取得してカメラの準備をします
    availableCameras().then((availableCameras) {
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
      _cameraController!.initialize().then((_) {
        _initializeCamera(useCamera);
      }).catchError((e) {
        // カメラ権限を拒否した場合もここに来ます。カメラが利用できない場合はこの画面を表示する意味がないため閉じます。
        Navigator.pop(context);
      });
    });
  }

  void _initializeCamera(CameraDescription useCamera) {
    if (!mounted) return;

    // カメラに映った画像を順次処理していきます。
    _cameraController?.startImageStream((image) {
      // かなり高速でStreamに入ってくるので_processingで処理中は流れてきたデータを無視するようにしています。
      if (_processing) return;

      setState(() => _processing = true);

      ref.read(cameraImageProvider).process(
            cameraImage: image,
            sensorOrientation: useCamera.sensorOrientation,
            onComplete: () {
              // 画像からテキストの検出処理が完了した後、すぐ次の処理に入って読んだ値が流れてしまうので分かりやすく2秒ラグを入れています。
              Future<void>.delayed(const Duration(seconds: 2)).then((_) {
                setState(() => _processing = false);
              });
            },
          );
    });

    setState(() {});
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
            SizedBox(
              height: MediaQuery.of(context).size.height / 2,
              child: _ViewCamera(_cameraController),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2.0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const _ViewReadResult(),
              ),
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
      return AspectRatio(
        aspectRatio: _cameraController!.value.previewSize!.aspectRatio,
        child: CameraPreview(_cameraController!),
      );
    } else {
      return const Center(
        child: SizedBox(
          height: 50,
          width: 50,
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}

class _ViewReadResult extends ConsumerWidget {
  const _ViewReadResult({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readTextList = ref.watch(readTextSNProvider);

    if (readTextList.isEmpty) {
      return const Center(
        child: Text(AppStrings.ocrPageEmptyResultLabel),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: readTextList.length,
      itemBuilder: (_, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(readTextList[index]),
      ),
    );
  }
}
