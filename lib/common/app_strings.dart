class AppStrings {
  const AppStrings._();

  static const String appName = 'OCRアプリ';

  static const String homePageOverviewLabel = '[Start]ボタンを押すとOCR画面を表示します。';
  static const String homePageDetailLabel = '''画面が表示されると、画面上部でカメラが起動します。
  \n読み込ませたい画像を映してください。
  \n映したテキストの読み取りに成功すると画面下部に結果が表示されていきます。''';
  static const String homePageStartCameraButton = 'Start';

  static const String ocrPageEmptyResultLabel = 'ここに検出したテキストが表示されます。';
}
