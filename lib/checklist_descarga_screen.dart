import 'package:app_systems/photo_screen_descarga.dart';
import 'package:app_systems/signature_screen_descarga.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Pacote necessário para formatação de data/hora

import 'photo_screen_descarga.dart';
import 'signature_screen_descarga.dart';

class ChecklistDesargaScreen extends StatefulWidget {
  final int orderId;

  const ChecklistDesargaScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _ChecklistCargaScreenState createState() => _ChecklistCargaScreenState();
}

class _ChecklistCargaScreenState extends State<ChecklistDesargaScreen> {
  Map<String, dynamic>? checklistData;
  bool _isLoading = true;
  String? _errorMessage;
  String? horaFinal; // Para armazenar o formato de hora

  bool _isEditable = true; // Para controlar se os campos são editáveis
  String? combustivelValue; // Para armazenar o valor do dropdown

  TextEditingController kmFinalController = TextEditingController();

  // Método para buscar os dados do checklist
  Future<void> fetchChecklistData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/GetChecklistDescarga/${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          checklistData = json.decode(response.body);
          if (checklistData?['horaFinal'] != null && checklistData?['horaFinal'] > 0) {
            // Converte milissegundos para hora no formato hh:mm
            final DateTime dt = DateTime.fromMillisecondsSinceEpoch(checklistData?['horaFinal']);
            horaFinal = DateFormat('HH:mm').format(dt);
            _isEditable = false; // Desabilita edição se dados do backend estão presentes
          } else {
            _isEditable = true; // Habilita edição se dados do backend não estão presentes ou são zeros
          }
          combustivelValue = (checklistData?['combustivelFinal']?.toString() ?? '0') == '0' ? null : checklistData?['combustivelFinal']?.toString();
          kmFinalController.text = checklistData?['kmFinal']?.toString() ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar dados do checklist: ${response.statusCode}';
          _isEditable = true; // Habilita edição se ocorrer erro ao carregar dados do backend
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Erro de conexão: $error';
        _isEditable = true; // Habilita edição se ocorrer erro de conexão
        _isLoading = false;
      });
    }
  }

  // Método para salvar os dados do checklist
  Future<void> saveChecklistData() async {
    setState(() {
      checklistData?['kmFinal'] = double.tryParse(kmFinalController.text) ?? 0;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/ChecklistDescarga'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(checklistData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Checklist salvo com sucesso!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar checklist: ${response.statusCode}")));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro de conexão: $error")));
    }
  }

  @override
  void initState() {
    super.initState();
    fetchChecklistData();
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Checklist Descarga #${widget.orderId}'),
    ),
    body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChecklistForm(),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isEditable ? saveChecklistData : null,
                      child: Text("Salvar Checklist"),
                    ),
                    SizedBox(height: 20),
                    _buildModernButton(
                      context,
                      icon: Icons.photo,
                      label: 'Fotos Descarga',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PhotoScreenDescarga(orderId: widget.orderId),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    _buildModernButton(
                      context,
                      icon: Icons.edit,
                      label: 'Assinar Descarga',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SignatureScreenDescarga(orderId: widget.orderId),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
  );
}
// Definição do método _buildModernButton
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

  Widget _buildChecklistForm() {
    combustivelValue = combustivelValue ?? '0'; // Garante que sempre haverá um valor válido para o dropdown

    return Column(
      children: [
        TextFormField(
          controller: TextEditingController(text: horaFinal),
          decoration: InputDecoration(labelText: "Hora Final"),
          readOnly: true,
        ),
        TextFormField(controller: kmFinalController, decoration: InputDecoration(labelText: "Km Final"), enabled: _isEditable),
        DropdownButtonFormField<String>(
          value: combustivelValue,
          decoration: InputDecoration(labelText: "Combustível Final"),
          items: [
            DropdownMenuItem(value: '0', child: Text('Selecionar')),
            DropdownMenuItem(value: '1', child: Text('Reserva')),
            DropdownMenuItem(value: '2', child: Text('1/4')),
            DropdownMenuItem(value: '3', child: Text('Meio')),
            DropdownMenuItem(value: '4', child: Text('3/4')),
            DropdownMenuItem(value: '5', child: Text('Cheio')),
            DropdownMenuItem(value: '6', child: Text('Abastecimento')),
          ],
          onChanged: _isEditable ? (value) {
            setState(() {
              combustivelValue = value!;
              checklistData?['combustivelFinal'] = int.parse(combustivelValue!);
            });
          } : null,
        ),    
      ],
    );
  }
}
