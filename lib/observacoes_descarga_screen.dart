import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:duration_picker/duration_picker.dart';
import 'config_service.dart';

class ObservacaoDescargaScreen extends StatefulWidget {
  final int orderId;

  const ObservacaoDescargaScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _ObservacaoDescargaScreenState createState() => _ObservacaoDescargaScreenState();
}

class _ObservacaoDescargaScreenState extends State<ObservacaoDescargaScreen> {
  bool _isLoading = true;
  bool _isEditable = true; // Controla se os campos estão editáveis
  String? _errorMessage;
  Map<String, dynamic>? observacaoData;

  // Controladores para os campos
  TextEditingController tempoEsperaController = TextEditingController();
  TextEditingController observacaoController = TextEditingController();
  TextEditingController nomePessoaController = TextEditingController();
  TextEditingController emailPessoaController = TextEditingController();
  TextEditingController telPessoaController = TextEditingController();

  // Método para buscar os dados da observação Descarga
  Future<void> fetchObservacaoData() async {
    try {
      final response = await http.get(
        Uri.parse('${ConfigService.apiBaseUrl}/ApiPedidos/GetObservacaoDescarga/${widget.orderId}'), // Endpoint dinâmico
      );
      if (response.statusCode == 200) {
        setState(() {
          observacaoData = json.decode(response.body);
          _isEditable = observacaoData?['horaInicio'] == null || observacaoData?['horaInicio'] == 0;

          // Preenchendo os campos com dados do backend
          tempoEsperaController.text = observacaoData?['tempoEspera'] ?? '';
          observacaoController.text = observacaoData?['observacao'] ?? '';
          nomePessoaController.text = observacaoData?['nomePessoa'] ?? '';
          emailPessoaController.text = observacaoData?['emailPessoa'] ?? '';
          telPessoaController.text = observacaoData?['telPessoa'] ?? '';

          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar dados: ${response.statusCode}';
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

  // Método para salvar os dados da observação Descarga
  Future<void> saveObservacaoData() async {
    setState(() {
      observacaoData?['tempoEspera'] = tempoEsperaController.text;
      observacaoData?['observacao'] = observacaoController.text;
      observacaoData?['nomePessoa'] = nomePessoaController.text;
      observacaoData?['emailPessoa'] = emailPessoaController.text;
      observacaoData?['telPessoa'] = telPessoaController.text;
    });

    try {
      final response = await http.post(        
        Uri.parse('${ConfigService.apiBaseUrl}/ApiPedidos/SaveObservacaoDescarga'), // Endpoint dinâmico
        headers: {'Content-Type': 'application/json'},
        body: json.encode(observacaoData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Observação salva com sucesso!")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro ao salvar observação: ${response.statusCode}")));
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro de conexão: $error")));
    }
  } 

Duration selectedDuration = Duration();

Future<void> _pickDuration() async {
  Duration? picked = await showDurationPicker(
    context: context,
    initialTime: selectedDuration,
  );
  if (picked != null) {
    setState(() {
      selectedDuration = picked;
      tempoEsperaController.text = _formatDurationFromPicker(selectedDuration);
    });
  }
}

String _formatDurationFromPicker(Duration duration) {
  return '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
}

Widget buildDurationPicker() {
  return InkWell(
    onTap: _isEditable ? _pickDuration : null,
    child: InputDecorator(
      decoration: InputDecoration(labelText: "Tempo de Espera (HH:mm:ss)"),
      child: Text(
        tempoEsperaController.text.isEmpty
            ? "Selecione o Tempo"
            : tempoEsperaController.text,
        style: TextStyle(fontSize: 16),
      ),
    ),
  );
}


  @override
  void initState() {
    super.initState();
    fetchObservacaoData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Observação Descarga'),
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
                      _buildObservacaoForm(),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isEditable ? saveObservacaoData : null,
                        child: Text("Salvar Observação"),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildObservacaoForm() {
    return Column(
      children: [
      buildDurationPicker(),
        TextFormField(
          controller: observacaoController,
          decoration: InputDecoration(labelText: "Observação Descarga"),
          enabled: _isEditable,
        ),
        TextFormField(
          controller: nomePessoaController,
          decoration: InputDecoration(labelText: "Nome da Pessoa"),
          enabled: _isEditable,
        ),
        TextFormField(
          controller: emailPessoaController,
          decoration: InputDecoration(labelText: "Email da Pessoa"),
          keyboardType: TextInputType.emailAddress,
          enabled: _isEditable,
        ),
        TextFormField(
          controller: telPessoaController,
          decoration: InputDecoration(labelText: "Telefone da Pessoa"),
          keyboardType: TextInputType.phone,
          enabled: _isEditable,
        ),
      ],
    );
  }
}
