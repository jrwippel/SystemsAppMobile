import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'checklist_carga_screen.dart';
import 'checklist_descarga_screen.dart';
import 'config_service.dart';

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
        Uri.parse('${ConfigService.apiBaseUrl}/ApiPedidos/details/${widget.orderId}'), // Endpoint dinâmico
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
        title: Text('Pedido #${widget.orderId}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
  elevation: 4.0,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: _buildFieldWithLabel(
                'Data do Pedido',
                _formatDate(orderDetails!['dataPedido']),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildFieldWithLabel(
                'Status',
                _getStatus(orderDetails!['horaInicio'], orderDetails!['horaFinal']),
              ),
            ),
          ],
        ),
        _buildFieldWithLabel(
          'Data Pretendida',
          _formatDate(orderDetails!['dataPretendida']),
        ),
        Divider(),
        _buildFieldWithLabel(
          'Matrícula',
          '${orderDetails!['veiculoDescricao']} / ${orderDetails!['marcaVeiculo']}',
        ),
        _buildFieldWithLabel('Motorista', orderDetails!['motoristaNome']),
        _buildFieldWithLabel('Cliente Carga', orderDetails!['clienteCargaNome']),
        _buildFieldWithLabel('Endereço Carga', orderDetails!['clienteCargaLocal']),
        _buildFieldWithLabel('Cliente Descarga', orderDetails!['clienteDescargaNome']),
        _buildFieldWithLabel('Endereço Descarga', orderDetails!['clienteDescargaLocal']),
      ],
    ),
  ),
),

            SizedBox(height: 20),

            GridView.count(
  shrinkWrap: true,
  crossAxisCount: 2,
  crossAxisSpacing: 10,
  mainAxisSpacing: 10,
  physics: NeverScrollableScrollPhysics(),
  children: [
    _buildButtonItem(
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
      isEnabled: true, // Sempre habilitado
    ),
    _buildButtonItem(
      context,
      icon: Icons.checklist,
      label: 'CheckList Descarga',
      onPressed: (orderDetails!['horaInicio'] != null && orderDetails!['horaInicio'] != 0)
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChecklistDesargaScreen(orderId: widget.orderId),
                ),
              );
            }
          : null, // Deixe o onPressed como null para desabilitar nativamente
      isEnabled: orderDetails!['horaInicio'] != null && orderDetails!['horaInicio'] != 0, // Define o estado
    ),
  ],
)

            
          ],
        ),
      ),
    );
  }

  // Campo com rótulo e valor
  Widget _buildFieldWithLabel(String label, String value) {
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

Widget _buildButtonItem(BuildContext context,
    {required IconData icon, required String label, required VoidCallback? onPressed, required bool isEnabled}) {
  return GestureDetector(
    onTap: isEnabled ? onPressed : null, // Apenas habilita o tap se estiver ativo
    child: Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isEnabled ? Colors.white : Colors.grey[300], // Cor muda se desabilitado
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: isEnabled ? Colors.blue : Colors.grey),
          SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isEnabled ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
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

String _getStatus(dynamic horaInicio, dynamic horaFinal) {
  if (horaFinal != null && horaFinal != 0) {
    return 'Finalizado';
  }
  if (horaInicio == null || horaInicio == 0) {
    return 'Não iniciado';
  }
  return 'Iniciado';
}


}
