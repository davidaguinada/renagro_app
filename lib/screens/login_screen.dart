import 'package:flutter/material.dart';
import 'package:renagro1/services/login_service.dart';
import 'package:renagro1/screens/calidad_screen.dart';
import 'package:renagro1/widgets/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final LoginService _loginService = LoginService();
  String? _errorMessage = '';
  bool _isLoading = false;  // New variable to track loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Container(
                  width: double.infinity,
                  height: 550,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                CustomTextInputField(
                                  controller: _usernameController,
                                  hintText: 'Usuario',
                                ),
                                CustomTextInputField(
                                  controller: _passwordController,
                                  hintText: 'Contraseña',
                                  obscureText: true,
                                ),
                                const SizedBox(height: 0,),
                                SizedBox(
                                  width: 400,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _login(),
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty.all(const Color(0xffe62a2f)),
                                    ),
                                    child: const Text('Ingresar', style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                                if (_isLoading) // Loading indicator
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                if (_errorMessage != null && _errorMessage!.isNotEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(_errorMessage!, style: const TextStyle(color: Color(0xfff0333c)), textAlign: TextAlign.center,),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        VerticalDivider(
                          color: Colors.grey[700],
                          thickness: 1,
                          width: 20,
                        ),
                        Expanded(child: Image.asset('images/Logo.png')),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50,),
              const Text('Propulsado por Neorik', style: TextStyle(fontSize: 14, color: Colors.black),),
            ],
          ),
        ),
      ),
    );
  }

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    if (_passwordController.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'El campo de la contraseña está vacío. Por favor, ingrese una contraseña.';
      });
      return;
    }

    try {
      final user = await _loginService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (!mounted) return; // Check if the widget is still mounted

      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CalidadScreen(
              userRole: user['Role'],
              userName: user['UserName'],
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Usuario no encontrado. Por favor, verifique sus credenciales.';
        });
      }
    } catch (e) {
      if (!mounted) return; // Check if the widget is still mounted

      setState(() {
        _errorMessage = 'Ocurrió un error. Por favor, inténtelo de nuevo más tarde.';
      });
    } finally {
      if (!mounted) return; // Check if the widget is still mounted

      setState(() {
        _isLoading = false;
      });
    }
  }
}
