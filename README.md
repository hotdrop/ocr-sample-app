# ocr_sample_app
Google ML Kitの`Text Recognition`を使用して、カメラに映した画像からテキストをリアルタイムに抽出し画面に表示するサンプルアプリです。  
`Text Recognition`で摘出したテキストはBlock->Lineと分解できますが、このアプリはサンプルなので見やすいようBlockの先頭だけ画面下部に流しています。  

## 画面イメージ
![image](images/01_flow.png)

## 参考
- Google's ML Kit for Flutter
  - Text Recognitionのサンプルコード
  - https://github.com/bharat-biradar/Google-Ml-Kit-plugin
- Flutter Catalog
  - firebase_mlkitのサンプルコード
  - https://github.com/X-Wei/flutter_catalog/blob/master/lib/routes