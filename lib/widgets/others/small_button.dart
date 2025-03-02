import 'package:flutter/material.dart';

class CustomSmallButton extends StatelessWidget {
  final void Function()? buttonAction;
  final Color buttonColor;
  final String buttonText;
  final Color textColor;

  const CustomSmallButton({
    super.key,
    this.buttonAction,
    required this.buttonColor,
    required this.buttonText,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: buttonAction,
      style: ButtonStyle(
        backgroundColor: MaterialStatePropertyAll(buttonColor),
        fixedSize: const MaterialStatePropertyAll(Size.fromWidth(130)),
      ),
      child: Text(buttonText, style: TextStyle(color: textColor),)
    );
  }
}