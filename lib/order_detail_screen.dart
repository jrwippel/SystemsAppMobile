import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'photo_screen.dart';
import 'checklist_carga_screen.dart';
import 'signature_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? orderDetails;
  bool _isLoading = true;
  String? _errorMessage;

  // Método para buscar os detalhes do pedido
  Future<void> fetchOrderDetails() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/details/${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          orderDetails = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar detalhes: ${response.statusCode}';
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
    fetchOrderDetails();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Detalhes do Pedido')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Detalhes do Pedido')),
        body: Center(child: Text(_errorMessage!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhes do Pedido #${widget.orderId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do pedido
            _buildRowWithTwoFields(
              context,
              'Data do Pedido',
              _formatDate(orderDetails!['dataPedido']),
              'Data Pretendida',
              _formatDate(orderDetails!['dataPretendida']),
            ),
            SizedBox(height: 20),
            _buildFieldWithLabel(
              context,
              'Matrícula',
              '${orderDetails!['veiculoDescricao']} / ${orderDetails!['marcaVeiculo']}',
            ),
            _buildFieldWithLabel(context, 'Motorista', orderDetails!['motoristaNome']),
            _buildFieldWithLabel(context, 'Cliente Carga', orderDetails!['clienteCargaNome']),
            _buildFieldWithLabel(context, 'Endereço Carga', orderDetails!['clienteCargaLocal']),
            _buildFieldWithLabel(context, 'Cliente Descarga', orderDetails!['clienteDescargaNome']),
            _buildFieldWithLabel(context, 'Endereço Descarga', orderDetails!['clienteDescargaLocal']),
            SizedBox(height: 30),

            // Botões estilizados
            _buildModernButton(
              context,
              icon: Icons.photo,
              label: 'Fotos',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoScreen(orderId: widget.orderId),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            _buildModernButton(
              context,
              icon: Icons.checklist,
              label: 'CheckList Carga',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChecklistCargaScreen(orderId: widget.orderId),
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            _buildModernButton(
              context,
              icon: Icons.edit,
              label: 'Assinar Carga',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SignatureScreen(orderId: widget.orderId),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Campo com rótulo e valor
  Widget _buildFieldWithLabel(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  // Linha com dois campos (exemplo: Data do Pedido e Data Pretendida)
  Widget _buildRowWithTwoFields(
      BuildContext context, String label1, String value1, String label2, String value2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildFieldWithLabel(context, label1, value1),
        ),
        SizedBox(width: 20),
        Expanded(
          child: _buildFieldWithLabel(context, label2, value2),
        ),
      ],
    );
  }

  // Botão estilizado com ícone e texto
  Widget _buildModernButton(BuildContext context,
      {required IconData icon, required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, size: 30),
        label: Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: onPressed,
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Data inválida';
    }
  }
}
