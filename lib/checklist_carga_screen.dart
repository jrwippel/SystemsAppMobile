import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Pacote necessário para formatação de data/hora
import 'dart:ui' as ui;
import 'photo_screen_carga.dart';
import 'signature_screen.dart';
import 'observacoes_carga_screen.dart';
import 'avarias_screen.dart';

class ChecklistCargaScreen extends StatefulWidget {
  final int orderId;

  const ChecklistCargaScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _ChecklistCargaScreenState createState() => _ChecklistCargaScreenState();
}

class _ChecklistCargaScreenState extends State<ChecklistCargaScreen> {
  Map<String, dynamic>? checklistData;
  bool _isLoading = true;
  String? _errorMessage;
  String? horaInicio; // Para armazenar o formato de hora

  bool _isEditable = true; // Para controlar se os campos são editáveis
  String? combustivelValue; // Para armazenar o valor do dropdown

  TextEditingController kmInicialController = TextEditingController();

  // Método para buscar os dados do checklist
  Future<void> fetchChecklistData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/GetChecklistCarga/${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          checklistData = json.decode(response.body);
          if (checklistData?['horaInicio'] != null && checklistData?['horaInicio'] > 0) {
            // Converte milissegundos para hora no formato hh:mm
            final DateTime dt = DateTime.fromMillisecondsSinceEpoch(checklistData?['horaInicio']);
            horaInicio = DateFormat('HH:mm').format(dt);
            _isEditable = false; // Desabilita edição se dados do backend estão presentes
          } else {
            _isEditable = true; // Habilita edição se dados do backend não estão presentes ou são zeros
          }
          combustivelValue = (checklistData?['combustivelInicial']?.toString() ?? '0') == '0' ? null : checklistData?['combustivelInicial']?.toString();          
          kmInicialController.text = (checklistData?['kmInicial'] != null && checklistData!['kmInicial'] != 0)
            ? checklistData!['kmInicial'].toString()
            : '';

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
      checklistData?['kmInicial'] = double.tryParse(kmInicialController.text) ?? 0;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/ChecklistCarga'),
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
      title: Text('Checklist Carga #${widget.orderId}'),
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
                      label: 'Fotos Carga',
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
                    SizedBox(height: 20),
                    _buildModernButton(
                      context,
                      icon: Icons.edit,
                      label: 'Obvservações Carga',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ObservacaoCargaScreen(orderId: widget.orderId),
                          ),
                        );
                      },
                    ),
                      SizedBox(height: 20),
                    _buildModernButton(
                      context,
                      icon: Icons.edit,
                      label: 'Avarias',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AvariasScreen(orderId: widget.orderId),
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

    bool trianguloHomologadoValue = checklistData?['trianguloHomologado'] == 1;
    bool coleteHomologadoValue = checklistData?['coleteHomologado'] == 1;
    bool documentoSeguroValue = checklistData?['documentoSeguro'] == 1;
    bool documentoVeiculoValue = checklistData?['documentoVeiculo'] == 1;

    return Column(
      children: [
        TextFormField(
          controller: TextEditingController(text: horaInicio),
          decoration: InputDecoration(labelText: "Hora Início"),
          readOnly: true,
        ),
        TextFormField(controller: kmInicialController, decoration: InputDecoration(labelText: "Km Inicial"), enabled: _isEditable),
        DropdownButtonFormField<String>(
          value: combustivelValue,
          decoration: InputDecoration(labelText: "Combustível Inicial"),
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
              checklistData?['combustivelInicial'] = int.parse(combustivelValue!);
            });
          } : null,
        ),
        SwitchListTile(
          title: Text("Triângulo Homologado"),
          value: trianguloHomologadoValue,
          onChanged: _isEditable ? (bool value) {
            setState(() {
              trianguloHomologadoValue = value;
              checklistData?['trianguloHomologado'] = value ? 1 : 0;
            });
          } : null,
        ),
        SwitchListTile(
          title: Text("Colete Homologado"),
          value: coleteHomologadoValue,
          onChanged: _isEditable ? (bool value) {
            setState(() {
              coleteHomologadoValue = value;
              checklistData?['coleteHomologado'] = value ? 1 : 0;
            });
          } : null,
        ),
        SwitchListTile(
          title: Text("Documento Seguro"),
          value: documentoSeguroValue,
          onChanged: _isEditable ? (bool value) {
            setState(() {
              documentoSeguroValue = value;
              checklistData?['documentoSeguro'] = value ? 1 : 0;
            });
          } : null,
        ),
        SwitchListTile(
          title: Text("Documento Veículo"),
          value: documentoVeiculoValue,
          onChanged: _isEditable ? (bool value) {
            setState(() {
              documentoVeiculoValue = value;
              checklistData?['documentoVeiculo'] = value ? 1 : 0;
            });
          } : null,
        ),
      ],
    );
  }
}
