import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'photo_screen_carga.dart';
import 'signature_screen.dart';
import 'observacoes_carga_screen.dart';
import 'avarias_screen.dart';
import 'config_service.dart';

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
  String? horaInicio;
  bool _isEditable = true;
  String? combustivelValue;
  TextEditingController kmInicialController = TextEditingController();

  Future<void> fetchChecklistData() async {
    try {
      final response = await http.get(
        Uri.parse('${ConfigService.apiBaseUrl}/ApiPedidos/GetChecklistCarga/${widget.orderId}'), // Endpoint dinâmico
      );
      if (response.statusCode == 200) {
        setState(() {
          checklistData = json.decode(response.body);
          if (checklistData?['horaInicio'] != null && checklistData?['horaInicio'] > 0) {
            final DateTime dt = DateTime.fromMillisecondsSinceEpoch(checklistData?['horaInicio']);
            horaInicio = DateFormat('HH:mm').format(dt);
            _isEditable = false;
          } else {
            _isEditable = true;
          }
          combustivelValue = checklistData?['combustivelInicial']?.toString() ?? '0';
          kmInicialController.text = (checklistData?['kmInicial'] != null && checklistData!['kmInicial'] != 0)
              ? checklistData!['kmInicial'].toString()
              : '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao carregar dados: ${response.statusCode}';
          _isEditable = true;
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _errorMessage = 'Erro de conexão: $error';
        _isEditable = true;
        _isLoading = false;
      });
    }
  }

bool isSalvarEnabled = false;

Future<void> checkChecklistPrerequisites(int pedidoId) async {
  // Valida os campos da tela
  bool camposValidos = validarCamposTela();

  if (!camposValidos) {
    setState(() {
      isSalvarEnabled = false;
    });
    return;
  }

  final String url = '${ConfigService.apiBaseUrl}/ApiPedidos/ValidateChecklistPrerequisites/$pedidoId';
  debugPrint('URL gerada: $url');

  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      debugPrint('Resposta recebida: $data');

      setState(() {
        isSalvarEnabled = data['habilitarSalvar'];
      });
    } else {
      debugPrint('Erro ao verificar checklist. Código: ${response.statusCode}');
    }
  } catch (e) {
    debugPrint('Erro de conexão: $e');
  }
}


bool validarCamposTela() {
  // Verifica KM Inicial
  if (kmInicialController.text.isEmpty || double.tryParse(kmInicialController.text) == null) {
    return false;
  }

  // Verifica Combustível Inicial
  if (combustivelValue == null || combustivelValue == '0') {
    return false;
  }
  return true;
}


Future<void> saveChecklistData() async {
  if (checklistData == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erro: os dados do checklist estão vazios."),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  setState(() {
    checklistData?['kmInicial'] = double.tryParse(kmInicialController.text) ?? 0;
  });

  try {
    final String url = '${ConfigService.apiBaseUrl}/ApiPedidos/ChecklistCarga';
    debugPrint('URL: $url');
    debugPrint('Dados enviados: ${json.encode(checklistData)}');

    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(checklistData),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Checklist salvo!"),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      final responseBody = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar: ${response.statusCode} - ${responseBody['Message'] ?? 'Erro desconhecido'}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erro: $error"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  void initState() {
    super.initState();
    fetchChecklistData(); 
    checkChecklistPrerequisites(widget.orderId);
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Checklist de Carga #${widget.orderId}'),
    ),
    body: _isLoading
        ? _buildLoading()
        : _errorMessage != null
            ? _buildError()
            : _buildMainContent(),
  );
}

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
         // SizedBox(height: 20),
          Text('Carregando checklist...', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red),
          SizedBox(height: 20),
          Text(_errorMessage!, 
            style: TextStyle(color: Colors.red.shade800, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: fetchChecklistData,
            child: Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(8),
      child: Column(
        children: [          
         // SizedBox(height: 20),
          _buildChecklistForm(),
          SizedBox(height: 10),
          _buildActionButtons(),
        ],
      ),
    );
  }

Widget _buildChecklistForm() {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: Padding(
      //padding: EdgeInsets.all(20),
      padding: EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 20), // Reduz o espaço superior
      child: Column(
        children: [
          // Hora Início e KM Inicial na mesma linha
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildInputField(
                  label: 'Hora Início',
                  value: horaInicio,
                  icon: Icons.access_time,
                  isEditable: false,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildInputField(
                  label: 'KM Inicial',
                  controller: kmInicialController,
                  icon: Icons.speed,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildDropdownField(), // Dropdown de combustível
          //SizedBox(height: 20),
          _buildSectionTitle('Itens de Verificação'),
          _buildSwitchItem(
            'Triângulo Homologado', 
            Icons.warning_amber_rounded,
            checklistData?['trianguloHomologado'] == 1,
            (value) => checklistData?['trianguloHomologado'] = value ? 1 : 0,
          ),
          _buildSwitchItem(
            'Colete Homologado', 
            Icons.security,
            checklistData?['coleteHomologado'] == 1,
            (value) => checklistData?['coleteHomologado'] = value ? 1 : 0,
          ),
          _buildSwitchItem(
            'Documento Seguro', 
            Icons.assignment,
            checklistData?['documentoSeguro'] == 1,
            (value) => checklistData?['documentoSeguro'] = value ? 1 : 0,
          ),
          _buildSwitchItem(
            'Documento Veículo', 
            Icons.description,
            checklistData?['documentoVeiculo'] == 1,
            (value) => checklistData?['documentoVeiculo'] = value ? 1 : 0,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildInputField({
    required String label,
    TextEditingController? controller,
    String? value,
    IconData? icon,
    TextInputType? keyboardType,
    bool isEditable = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller ?? TextEditingController(text: value),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null 
              ? Icon(icon, color: Colors.blue.shade600)
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabled: _isEditable && isEditable,
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        style: TextStyle(fontSize: 16, color: Colors.black),
        keyboardType: keyboardType,
              onChanged: (value) {
        setState(() {
          // Atualiza o valor
          if (label == 'KM Inicial') {
            checklistData?['kmInicial'] = double.tryParse(value) ?? 0;
          }
        });
        // Chama o método para verificar o estado do botão
        checkChecklistPrerequisites(widget.orderId);
      },
      ),
    );
  }

Widget _buildDropdownField() {
  return DropdownButtonFormField<String>(
    value: combustivelValue, // Valor selecionado
    decoration: InputDecoration(
      labelText: 'Combustível Inicial',
      prefixIcon: Icon(Icons.local_gas_station, color: Colors.blue.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    items: [
      DropdownMenuItem(value: '0', child: Text('Selecionar', style: TextStyle(color: Colors.black))),
      DropdownMenuItem(value: '1', child: Text('Reserva', style: TextStyle(color: Colors.black))),
      DropdownMenuItem(value: '2', child: Text('1/4', style: TextStyle(color: Colors.black))),
      DropdownMenuItem(value: '3', child: Text('Meio', style: TextStyle(color: Colors.black))),
      DropdownMenuItem(value: '4', child: Text('3/4', style: TextStyle(color: Colors.black))),
      DropdownMenuItem(value: '5', child: Text('1/2', style: TextStyle(color: Colors.black))),
      DropdownMenuItem(value: '6', child: Text('Abastecimento', style: TextStyle(color: Colors.black))),
    ],
    onChanged: _isEditable ? (String? value) {
      setState(() {
        combustivelValue = value; // Atualiza o valor selecionado
        checklistData?['combustivelInicial'] = int.parse(value ?? '0'); // Atualiza os dados
      });
      // Chama o método para verificar o estado do botão
      checkChecklistPrerequisites(widget.orderId);
    } : null,
    icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade600),
    dropdownColor: Colors.white,
    borderRadius: BorderRadius.circular(10),
    style: TextStyle(fontSize: 16),
  );
}


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchItem(String title, IconData icon, bool value, Function(bool) onChanged) {
  return ListTile(
    leading: Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.blue.shade600, size: 24),
    ),
    title: Text(title, style: TextStyle(fontSize: 16)),
    trailing: Switch(
      value: value,
      activeColor: Colors.blue,
      onChanged: _isEditable ? (newValue) {
        setState(() => onChanged(newValue));
        // Chama o método para verificar o estado do botão
        checkChecklistPrerequisites(widget.orderId);
      } : null,
    ),
    contentPadding: EdgeInsets.symmetric(vertical: 4),
  );
}


  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildModernButton(
          icon: Icons.photo_camera,
          label: 'Fotos da Carga',
          color: Colors.purple,
          onPressed: () => _navigateTo(PhotoScreen(orderId: widget.orderId)),
        ),
        SizedBox(height: 10),
        _buildModernButton(
          icon: Icons.edit,
          label: 'Assinar Carga',
          color: Colors.green,
          onPressed: () => _navigateTo(SignatureScreen(orderId: widget.orderId)),
        ),
        SizedBox(height: 10),
        _buildModernButton(
          icon: Icons.note_add,
          label: 'Observações',
          color: Colors.orange,
          onPressed: () => _navigateTo(ObservacaoCargaScreen(orderId: widget.orderId)),
        ),
        SizedBox(height: 10),
        _buildModernButton(
          icon: Icons.warning,
          label: 'Avarias',
          color: Colors.red,
          onPressed: () => _navigateTo(AvariasScreen(orderId: widget.orderId)),
        ),
        SizedBox(height: 15),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildModernButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.9),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        icon: Icon(icon, size: 24),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(     
       onPressed: isSalvarEnabled ? saveChecklistData : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'Iniciar Recolha',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}