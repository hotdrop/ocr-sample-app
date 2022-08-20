import 'package:flutter_riverpod/flutter_riverpod.dart';

final readTextSNProvider = StateNotifierProvider<_ReadTextStateNotifier, String?>((_) {
  return _ReadTextStateNotifier(null);
});

class _ReadTextStateNotifier extends StateNotifier<String?> {
  _ReadTextStateNotifier(super.state);

  void setText(String text) {
    state = text;
  }

  void clear() {
    state = null;
  }
}
