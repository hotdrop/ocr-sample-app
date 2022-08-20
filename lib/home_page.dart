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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(AppStrings.homePageOverviewLabel),
            const SizedBox(height: 8),
            const Text(AppStrings.homePageDetailLabel),
            const SizedBox(height: 8),
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
