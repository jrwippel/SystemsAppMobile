import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data'; // Para Uint8List
import 'package:http/http.dart' as http; // Para requisições HTTP
import 'dart:convert'; // Adicione esta linha para utilizar `json.decode`

class SignatureScreenDescarga extends StatefulWidget {
  final int orderId;

  const SignatureScreenDescarga({Key? key, required this.orderId}) : super(key: key);

  @override
  _SignatureScreenState createState() => _SignatureScreenState();
}

class _SignatureScreenState extends State<SignatureScreenDescarga> {
  // Controladores para as assinaturas
  final SignatureController _controllerMotorista = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  final SignatureController _controllerCliente = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _isLoading = true; // Indica se os dados estão sendo carregados
  bool _hasMotoristaSignature = false; // Indica se já existe assinatura do motorista
  bool _hasClienteSignature = false; // Indica se já existe assinatura do cliente
  String? motoristaSignatureUrl; // URL da assinatura do motorista
  String? clienteSignatureUrl; // URL da assinatura do cliente

  @override
  void initState() {
    super.initState();
    _fetchSignatures(); // Carrega as assinaturas ao iniciar a tela
  }

  // Método para buscar as assinaturas da API
  Future<void> _fetchSignatures() async {
    final url = Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/${widget.orderId}/photosassdescarga');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> photos = json.decode(response.body);

        // Verifica se há assinaturas do motorista e do cliente
        final motoristaSignature = photos.firstWhere((photo) => photo['tipoFoto'] == 8, orElse: () => null);
        final clienteSignature = photos.firstWhere((photo) => photo['tipoFoto'] == 9, orElse: () => null);

        String? motoristaFileName = motoristaSignature?['nomeArquivo'];
        String? clienteFileName = clienteSignature?['nomeArquivo'];

        setState(() {
          if (motoristaFileName != null) {
            _hasMotoristaSignature = true;
            motoristaSignatureUrl = 'http://10.0.2.2:8000/api/ApiPedidos/download/$motoristaFileName';
          }
          if (clienteFileName != null) {
            _hasClienteSignature = true;
            clienteSignatureUrl = 'http://10.0.2.2:8000/api/ApiPedidos/download/$clienteFileName';
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assinaturas - Pedido #${widget.orderId}'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Exibe carregamento
          : Column(
              children: [
                // Campo de assinatura para o Motorista
                Text('Assinatura do Motorista', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Garante que o fundo é transparente
                    ),
                    child: _hasMotoristaSignature
                        ? Image.network(
                            motoristaSignatureUrl!,
                            height: 150, // Define a altura da imagem
                            width: 300,  // Define a largura da imagem
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Text('Erro ao carregar a imagem');
                            },
                          ) // Exibe a assinatura se existir
                        : Signature(
                            controller: _controllerMotorista,
                            backgroundColor: Colors.white,
                          ),
                  ),
                ),
                SizedBox(height: 20),
                // Campo de assinatura para o Cliente
                Text('Assinatura do Cliente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Garante que o fundo é transparente
                    ),
                    child: _hasClienteSignature
                        ? Image.network(
                            clienteSignatureUrl!,
                            height: 150, // Define a altura da imagem
                            width: 300,  // Define a largura da imagem
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Text('Erro ao carregar a imagem');
                            },
                          ) // Exibe a assinatura se existir
                        : Signature(
                            controller: _controllerCliente,
                            backgroundColor: Colors.white,
                          ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botão para limpar as assinaturas
                    ElevatedButton(
                      onPressed: (_hasMotoristaSignature || _hasClienteSignature)
                          ? null
                          : () {
                              _controllerMotorista.clear();
                              _controllerCliente.clear();
                            },
                      child: Text('Limpar'),
                    ),
                    // Botão para salvar as assinaturas
                    ElevatedButton(
                      onPressed: (_hasMotoristaSignature || _hasClienteSignature) ? null : _saveSignatures,
                      child: Text('Salvar'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Future<void> _saveSignatures() async {
    final url = Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/UploadFotoPedido');

    try {
      // Verificar se as assinaturas estão preenchidas
      if (!_controllerMotorista.isNotEmpty || !_controllerCliente.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor, preencha ambas as assinaturas!')),
        );
        return;
      }

      // Exportar as assinaturas para bytes
      final motoristaSignature = await _controllerMotorista.toPngBytes();
      final clienteSignature = await _controllerCliente.toPngBytes();

      if (motoristaSignature != null && clienteSignature != null) {
        // Enviar as duas assinaturas para o backend
        final motoristaRequest = http.MultipartFile.fromBytes(
          'foto',
          motoristaSignature,
          filename: 'motorista_signature.png',
        );

        final clienteRequest = http.MultipartFile.fromBytes(
          'foto',
          clienteSignature,
          filename: 'cliente_signature.png',
        );

        final request = http.MultipartRequest('POST', url);
        request.files.add(motoristaRequest);
        request.fields['PedidoId'] = widget.orderId.toString();
        request.fields['TipoFoto'] = 'AssMotorista'; // Tipo de assinatura do motorista
        request.fields['NomeFoto'] = 'descarga_motorista_signature.png';
        request.fields['TipoFotoPedido'] = '2'; // 1 = Carga, 2 = Descarga

        // Adicionar assinatura do cliente
        final requestCliente = http.MultipartRequest('POST', url);
        requestCliente.files.add(clienteRequest);
        requestCliente.fields['PedidoId'] = widget.orderId.toString();
        requestCliente.fields['TipoFoto'] = 'AssCliente'; // Tipo de assinatura do cliente
        requestCliente.fields['NomeFoto'] = 'descarga_cliente_signature.png';
        requestCliente.fields['TipoFotoPedido'] = '2'; // 1 = Carga, 2 = Descarga

        // Enviar ambas as requisições
        await request.send();
        await requestCliente.send();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Assinaturas salvas com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar assinaturas: $e')),
      );
    }
  }
}
