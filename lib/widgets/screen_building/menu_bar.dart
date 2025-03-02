import 'package:flutter/material.dart';
import 'package:renagro1/screens/screens.dart';

class CustomMenuBar extends StatelessWidget {
  final String userRole;
  final String userName;

  const CustomMenuBar({
    super.key,
    required this.userRole,
    required this.userName
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Color(0xff1d3b6f),
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.rule_outlined),
            title: const Text('Control de Calidad'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CalidadScreen(userRole: userRole, userName: userName,))
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Inventario de Fincas'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => FincasScreen(userRole: userRole, userName: userName,))
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.work_history),
            title: const Text('Monitoreo de Actividad'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ActividadScreen(userRole: userRole, userName: userName,))
              );
            },
          ),
        ],
      ),
    );
  }
}

