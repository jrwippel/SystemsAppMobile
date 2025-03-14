import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  @override
  _OrderListScreenState createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<dynamic> _orders = []; // Lista de pedidos
  bool _isLoading = true; // Indica se os dados estão sendo carregados
  String? _errorMessage; // Armazena mensagens de erro

  // Método para buscar os pedidos da API
  Future<void> fetchOrders() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/ApiPedidos'), // Endpoint para dados principais
      );

      if (response.statusCode == 200) {
        setState(() {
          _orders = json.decode(response.body); // Decodifica a resposta JSON
          // Ordena a lista por data e número de pedido em ordem decrescente
          _orders.sort((a, b) {
            final dateA = DateTime.parse(a['dataPedido']);
            final dateB = DateTime.parse(b['dataPedido']);
            if (dateA == dateB) {
              return b['id'].compareTo(a['id']); // Ordena por número do pedido se as datas forem iguais
            }
            return dateB.compareTo(dateA); // Ordena por data
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar pedidos: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Erro de conexão: $error';
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchOrders(); // Busca os pedidos ao iniciar a tela
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
              ? Center(child: Text(_errorMessage!)) // Exibe erro, se existir
              : ListView.separated(
                  itemCount: _orders.length,
                  separatorBuilder: (context, index) => Divider(), // Separador entre os itens
                  itemBuilder: (context, index) {
                    final order = _orders[index]; // Dados de um pedido
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                OrderDetailScreen(orderId: order['id']), // Passa o ID para a próxima tela
                          ),
                        );
                      },
                      child: Container(
                        margin: EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4.0,
                              spreadRadius: 1.0,
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Icon(Icons.assignment, color: Colors.blue), // Ícone principal
                          title: Text(
                            'Pedido ID: ${order['id']}', // Exibe o ID do pedido
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Cliente Carga: ${order['clienteCargaNome']}\n'
                            'Cliente Descarga: ${order['clienteDescargaNome']}', // Exibe clientes
                          ),
                          trailing: Icon(Icons.arrow_forward, color: Colors.grey), // Ícone de seta
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
