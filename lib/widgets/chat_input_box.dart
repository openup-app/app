import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';

class EmojiInputBox extends StatelessWidget {
  final void Function(String emoji) onEmoji;

  const EmojiInputBox({
    Key? key,
    required this.onEmoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        onEmoji(emoji.emoji);
      },
      config: const Config(initCategory: Category.SMILEYS),
    );
  }
}
