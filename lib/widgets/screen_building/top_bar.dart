import 'package:flutter/material.dart';
import 'package:renagro1/screens/screens.dart';

class CustomTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomTopBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: preferredSize,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: const Color(0xff1d3b6f),
            toolbarHeight: 56.0, // Standard AppBar height
            leadingWidth: 70,
            centerTitle: true,
            title: Container(
              alignment: Alignment.center,
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
              ),
            ),
            actions: <Widget>[
              Container(
                alignment: Alignment.center,
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    'Salir',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,  // This makes the line stretch across the entire width of the screen
            height: 10.0,             // Set the desired height for the line (1.0 for a thin line)
            color: const Color(0xffe62a2f),       // Set the color of the line to red
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70.0);
}
