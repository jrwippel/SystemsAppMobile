import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order; // Receberá os dados do pedido selecionado

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Pedido'),
      ),
      body: 
      Padding(
  padding: const EdgeInsets.all(16.0),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Pedido ID: ${order['id']}',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      Divider(color: Colors.grey), // Divisor entre o ID e a data
      Text('Data do Pedido: ${order['dataPedido']}'),
      Divider(color: Colors.grey), // Divisor entre a data e o veículo
      Text('Veículo: ${order['veiculoId']}'),
      Divider(color: Colors.grey), // Outro divisor
      Text('Cliente Carga: ${order['clienteCargaId']}'),
      Divider(color: Colors.grey),
      Text('Cliente Descarga: ${order['clienteDescargaId']}'),
      SizedBox(height: 20),
      Text(
        'Detalhes Adicionais',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Divider(color: Colors.grey), // Divisor para a seção adicional
      Text('Observação Carga: ${order['observacaoCarga'] ?? "N/A"}'),
      Divider(color: Colors.grey),
      Text('Observação Descarga: ${order['observacaoDescarga'] ?? "N/A"}'),
    ],
  ),
),
    );

  }
}
