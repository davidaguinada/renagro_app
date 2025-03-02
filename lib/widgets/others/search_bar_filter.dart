import 'package:flutter/material.dart';

class SearchBarFilter extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final void Function(String) onSubmitted;

  const SearchBarFilter({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SizedBox(
        height: 30,
        child: Center(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              icon: const Icon(Icons.search, color: Colors.grey),
              hintText: hintText,
              hintStyle: const TextStyle(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12.0),
            ),
            onSubmitted: onSubmitted,
          ),
        ),
      ),
    );
  }
}
