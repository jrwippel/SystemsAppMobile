import 'package:flutter/material.dart';
import 'dart:convert'; // Para converter a resposta JSON
import 'package:http/http.dart' as http;
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<dynamic> _orders = []; // Lista para armazenar os pedidos
  bool _isLoading = true; // Variável para indicar carregamento
  String? _errorMessage; // Variável para armazenar mensagem de erro

  // Método para buscar os pedidos da API
  Future<void> fetchOrders() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8000/api/ApiPedidos'), // Substitua pelo endereço da sua API
      );

      if (response.statusCode == 200) {
        // Decodifica a resposta JSON e atualiza a lista de pedidos
        setState(() {
          _orders = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        // Caso a API retorne erro
        setState(() {
          _errorMessage = 'Erro ao carregar pedidos: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (error) {
      // Captura erros de conexão ou outros problemas
      setState(() {
        _errorMessage = 'Erro de conexão: $error';
        _isLoading = false;
      });
    }
  }

  // Carregar os pedidos assim que a tela abrir
  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de Pedidos'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Exibe carregamento
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!)) // Exibe erro, se houver
              : 
              ListView.builder(
  itemCount: _orders.length,
  itemBuilder: (context, index) {
    final order = _orders[index];
    return Column(
      children: [
        Card(
          margin: EdgeInsets.all(8.0),
          child: ListTile(
            title: Text('Pedido ID: ${order['id']}'),
            subtitle: Text(
              'Data: ${order['dataPedido']}\nVeículo: ${order['veiculoId']}',
            ),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailScreen(order: order),
                ),
              );
            },
          ),
        ),
        Divider(color: Colors.grey), // Divisor entre os itens
      ],
    );
  },
),

    );
  }
}
