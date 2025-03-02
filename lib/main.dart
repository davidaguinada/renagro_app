// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:renagro1/screens/screens.dart';
import 'package:renagro1/globals.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadConfig();
  runApp(const Renagro1());
}

class Renagro1 extends StatelessWidget {
  const Renagro1({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp( 
      title: 'Renagro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        fontFamily: 'Roboto',
        useMaterial3: true
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // English
        Locale('es', ''),   // Spanish
      ],
      
      home: const FincasScreen(userRole: "Headquarter", userName: "vladimirHQ")
    );
  }
}
/*
LoginScreen()
CalidadScreen(userRole: 'Supervisor', userName: 'supp42',)
CalidadScreen(userRole: 'Interviewer', userName: 'userp812',)
FincasScreen(userRole: "Headquarter", userName: "vladimirHQ")
ActividadScreen(userRole: "Headquarter", userName: "vladimirHQ")
*/
