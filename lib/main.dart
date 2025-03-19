import 'package:flutter/material.dart';
import 'login_screen.dart'; // Importe a tela de login
import 'config_service.dart';
import 'login_screen.dart'; // Tela de login
import 'profile_screen.dart'; // Tela de perfil
import 'settings_screen.dart'; // Tela de configurações
import 'order_list_screen.dart'; // Tela de configurações


void main() async  {
   WidgetsFlutterBinding.ensureInitialized();    
  await ConfigService.loadConfig("dev");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LoginScreen(), // Defina a tela inicial como a tela de login
            debugShowCheckedModeBanner: false,
      title: 'Sistema com Menu',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/login', // Tela inicial
      routes: {
        '/login': (context) => LoginScreen(),       
        '/profile': (context) => ProfileScreen(), // Tela de perfil
        '/settings': (context) => SettingsScreen(), // Tela de configurações
        '/orders': (context) => OrderListScreen(),
      },
    );
  }
}





class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
       
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
       
        title: Text(widget.title),
      ),
      body: Center(
        
        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
