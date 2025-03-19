import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'config_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

Future<void> login() async {
  final String url = '${ConfigService.apiBaseUrl}/ApiLogin/login';
  try {
    final response = await http.post(
      Uri.parse(url), // URL dinâmica com base no ambiente
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
      // Falha no login - Exibe mensagem de erro retornada pela API
      final Map<String, dynamic> responseJson = json.decode(response.body);
      String errorMessage = responseJson['Message'] ?? 'Falha no login';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $errorMessage\nURL: $url')),
      );
    }
  } catch (error) {
    // Erro ao conectar - Inclui a URL na mensagem de erro
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao conectar com o servidor: $error\nURL: $url')),
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
                decoration: InputDecoration(labelText: "Usuário"),
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
                Navigator.pushNamed(context, '/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Configurações'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
                Navigator.pushNamed(context, '/settings');
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Sair'),
              onTap: () {
                Navigator.pop(context); // Fecha o menu
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Define 2 colunas
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
          children: <Widget>[
            _buildMenuItem(
              context,
              icon: Icons.assignment,
              label: 'Pedidos',
              route: '/orders',
            ),
            _buildMenuItem(
              context,
              icon: Icons.person,
              label: 'Perfil',
              route: '/profile',
            ),
            _buildMenuItem(
              context,
              icon: Icons.settings,
              label: 'Configurações',
              route: '/settings',
            ),
            _buildMenuItem(
              context,
              icon: Icons.exit_to_app,
              label: 'Sair',
              route: '/login',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon, required String label, required String route}) {
    return GestureDetector(
      onTap: () {
        if (route == '/login') {
          Navigator.pushReplacementNamed(context, route);
        } else {
          Navigator.pushNamed(context, route);
        }
      },
      child: Card(
        elevation: 4.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.blue),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

