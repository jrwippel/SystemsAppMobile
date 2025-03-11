import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

Future<void> login() async {
  final response = await http.post(
    Uri.parse('http://localhost:8000/api/ApiLogin/login'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, String>{
      'login': _emailController.text,
      'senha': _passwordController.text,
    }),
  );

  if (response.statusCode == 200) {
    // Login bem-sucedido
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()), // Navegue para a tela principal
    );
  } else {
    // Falha no login - Exibe a mensagem de erro retornada pela API
    final Map<String, dynamic> responseJson = json.decode(response.body);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(responseJson['Message'] ?? 'Falha no login')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Senha"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    login();
                  }
                },
                child: Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Menu Principal"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Bem-vindo!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Página Inicial'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
              },
            ),            
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('Pedidos'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
                Navigator.pushNamed(context, '/orders');
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Perfil'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
                Navigator.pushNamed(context, '/profile'); // Navega para a tela de Perfil
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Configurações'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
                Navigator.pushNamed(context, '/settings'); // Navega para a tela de Configurações
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Sair'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
                Navigator.pushReplacementNamed(context, '/login'); // Volta para a tela de Login
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: Text("Bem-vindo!"),
      ),
    );
  }
}

