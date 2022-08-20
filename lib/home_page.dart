import 'package:flutter/material.dart';

import 'common/app_strings.dart';
import 'ocr_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.appName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                AppStrings.homePageOverviewLabel,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                OcrPage.start(context);
              },
              icon: const Icon(Icons.camera),
              label: const Text(AppStrings.homePageStartCameraButton),
            ),
          ],
        ),
      ),
    );
  }
}
