import 'package:flutter/material.dart';
import 'package:openup/widgets/theming.dart';

class ContactTextField extends StatefulWidget {
  final TextEditingController textController;
  final String hintText;
  const ContactTextField({
    Key? key,
    required this.textController,
    required this.hintText,
  }) : super(key: key);

  @override
  State<ContactTextField> createState() => _ContactTextFieldState();
}

class _ContactTextFieldState extends State<ContactTextField> {
  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_listener);
  }

  @override
  void dispose() {
    widget.textController.removeListener(_listener);
    super.dispose();
  }

  void _listener() {
    // Side effect to show/hide hint text
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 242),
      margin: const EdgeInsets.symmetric(
        horizontal: 23,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(
          Radius.circular(18),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: widget.textController,
              textInputAction: TextInputAction.done,
              maxLines: 10,
              decoration: const InputDecoration.collapsed(
                hintText: '',
              ),
            ),
          ),
          if (widget.textController.text.isEmpty)
            Align(
              alignment: Alignment.center,
              child: Text(
                widget.hintText,
                style: Theming.of(context).text.body.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: const Color.fromRGBO(0xAD, 0xAD, 0xAD, 1.0),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
