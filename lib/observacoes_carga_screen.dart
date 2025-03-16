import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:duration_picker/duration_picker.dart';

class ObservacaoCargaScreen extends StatefulWidget {
  final int orderId;

  const ObservacaoCargaScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _ObservacaoCargaScreenState createState() => _ObservacaoCargaScreenState();
}

class _ObservacaoCargaScreenState extends State<ObservacaoCargaScreen> {
  bool _isLoading = true;
  bool _isEditable = true; // Controla se os campos estão editáveis
  String? _errorMessage;
  Map<String, dynamic>? observacaoData;

  // Controladores para os campos
  TextEditingController tempoEsperaCargaController = TextEditingController();
  TextEditingController observacaoCargaController = TextEditingController();
  TextEditingController nomePessoaCarController = TextEditingController();
  TextEditingController emailPessoaCarController = TextEditingController();
  TextEditingController telPessoaCarController = TextEditingController();

  // Método para buscar os dados da observação carga
  Future<void> fetchObservacaoData() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/GetObservacaoCarga/${widget.orderId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          observacaoData = json.decode(response.body);
          _isEditable = observacaoData?['horaInicio'] == null || observacaoData?['horaInicio'] == 0;

          // Preenchendo os campos com dados do backend
          tempoEsperaCargaController.text = observacaoData?['tempoEsperaCarga'] ?? '';
          observacaoCargaController.text = observacaoData?['observacaoCarga'] ?? '';
          nomePessoaCarController.text = observacaoData?['nomePessoaCar'] ?? '';
          emailPessoaCarController.text = observacaoData?['emailPessoaCar'] ?? '';
          telPessoaCarController.text = observacaoData?['telPessoaCar'] ?? '';

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

  // Método para salvar os dados da observação carga
  Future<void> saveObservacaoData() async {
    setState(() {
      observacaoData?['tempoEsperaCarga'] = tempoEsperaCargaController.text;
      observacaoData?['observacaoCarga'] = observacaoCargaController.text;
      observacaoData?['nomePessoaCar'] = nomePessoaCarController.text;
      observacaoData?['emailPessoaCar'] = emailPessoaCarController.text;
      observacaoData?['telPessoaCar'] = telPessoaCarController.text;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/SaveObservacaoCarga'),
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
      tempoEsperaCargaController.text = _formatDurationFromPicker(selectedDuration);
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
        tempoEsperaCargaController.text.isEmpty
            ? "Selecione o Tempo"
            : tempoEsperaCargaController.text,
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
        title: Text('Observação Carga'),
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
          controller: observacaoCargaController,
          decoration: InputDecoration(labelText: "Observação Carga"),
          enabled: _isEditable,
        ),
        TextFormField(
          controller: nomePessoaCarController,
          decoration: InputDecoration(labelText: "Nome da Pessoa"),
          enabled: _isEditable,
        ),
        TextFormField(
          controller: emailPessoaCarController,
          decoration: InputDecoration(labelText: "Email da Pessoa"),
          keyboardType: TextInputType.emailAddress,
          enabled: _isEditable,
        ),
        TextFormField(
          controller: telPessoaCarController,
          decoration: InputDecoration(labelText: "Telefone da Pessoa"),
          keyboardType: TextInputType.phone,
          enabled: _isEditable,
        ),
      ],
    );
  }
}
