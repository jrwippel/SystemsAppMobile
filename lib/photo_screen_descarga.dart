import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class PhotoScreenDescarga extends StatefulWidget {
  final int orderId;
  final String? horaInicio; // Adicione este campo para receber a hora de início

  const PhotoScreenDescarga({Key? key, required this.orderId, this.horaInicio}) : super(key: key);

  @override
  _PhotoScreenState createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreenDescarga> {
  List<Map<String, dynamic>> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;
  bool _isUploading = false;
  String? _selectedPhotoType;

  // Tipos de foto e IDs
  final Map<String, int> _photoTypes = {
    'Local de estacionamento': 11,  
  };

  @override
  void initState() {
    super.initState();
    _loadExistingPhotos(); // Carregar fotos ao iniciar a tela
  }

  // Carregar fotos existentes do servidor
  Future<void> _loadExistingPhotos() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/${widget.orderId}/photosdescarga'),
      );

      if (response.statusCode == 200) {
        final photos = List<Map<String, dynamic>>.from(json.decode(response.body));
        setState(() {
          _images = photos.map((photo) {
            return {
              'url': photo['urlFoto'], // URL do servidor
              'type': _photoTypes.keys.firstWhere(
                (key) => _photoTypes[key] == photo['tipoFoto'],
                orElse: () => 'Desconhecido',
              ),
              'name': photo['nomeArquivo'], // Nome do arquivo
              'isLocal': false, // Indica que a imagem vem do servidor
            };
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showError('Erro ao carregar fotos: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erro de conexão: $error');
    }
  }

  // Tirar ou selecionar uma foto
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _images.add({
          'url': pickedFile.path, // Caminho local da imagem
          'type': _selectedPhotoType,
          'name': pickedFile.path.split('/').last,
          'isLocal': true, // Indica que a imagem é local
        });
      });
    }
  }

  // Visualizar imagem (local ou do servidor)
  void _viewImage(Map<String, dynamic> image) {
    if (image['isLocal'] == true) {
      // Visualizar imagem local
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Image.file(
            File(image['url']),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      // Visualizar imagem do servidor
      _openImageFromServer(image['name']);
    }
  }

  // Abrir imagem do servidor
  Future<void> _openImageFromServer(String fileName) async {
    try {
      final url = 'http://10.0.2.2:8000/api/ApiPedidos/download/$fileName';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Image.memory(imageBytes),
          ),
        );
      } else {
        _showError('Erro ao carregar imagem do servidor');
      }
    } catch (error) {
      _showError('Erro ao abrir a imagem do servidor: $error');
    }
  }

  // Mostrar mensagem de erro
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.red))),
    );
  }

  Future<void> _deleteImage(String fileName) async {
  final url = Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/DeleteFotoPedido/$fileName');

  try {
    final response = await http.delete(url);

    if (response.statusCode == 200) {
      setState(() {
        _images.removeWhere((image) => image['name'] == fileName);
      });
      _showMessage("Foto removida com sucesso!");
    } else {
      _showError("Erro ao remover a foto: ${response.statusCode}");
    }
  } catch (error) {
    _showError("Erro de conexão: $error");
  }
}


  // Enviar fotos para o servidor (somente novas fotos)
Future<void> _uploadImages() async {
  // Filtrar apenas fotos locais (novas)
  final newPhotos = _images.where((image) => image['isLocal'] == true).toList();

  if (newPhotos.isEmpty) {
    _showMessage('Nenhuma nova foto para enviar.');
    return;
  }

  setState(() {
    _isUploading = true;
  });

  try {
    for (var image in newPhotos) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/UploadFotoPedido'),
      );

      request.files.add(await http.MultipartFile.fromPath('foto', image['url']));
      request.fields['PedidoId'] = widget.orderId.toString();
      request.fields['TipoFoto'] = _photoTypes[image['type']].toString();
      request.fields['NomeFoto'] = image['name'];
      request.fields['TipoFotoPedido'] = '2'; // 1 = Carga, 2 = Descarga

      final response = await request.send();

      if (response.statusCode != 200) {
        setState(() {
          _isUploading = false;
        });
        _showError('Erro ao enviar imagem: ${image['name']}');
        return;
      }
    }

    // Atualizar o estado das fotos para marcar como enviadas
    setState(() {
      _images = _images.map((image) {
        if (image['isLocal'] == true) {
          image['isLocal'] = false; // Marcar como salva
        }
        return image;
      }).toList();
      _isUploading = false;
      _showMessage('Novas fotos foram enviadas com sucesso!');
    });
  } catch (error) {
    setState(() {
      _isUploading = false;
    });
    _showError('Erro ao enviar as fotos: $error');
  }
}


  // Mostrar mensagem de sucesso
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.green))),
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Fotos do Pedido [Descarga] #${widget.orderId}'),
    ),
    body: _isLoading
        ? Center(child: CircularProgressIndicator()) // Indicador de carregamento
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButton<String>(
                  hint: Text('Selecione o tipo de foto'),
                  value: _selectedPhotoType,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedPhotoType = newValue;
                    });
                  },
                  items: _photoTypes.keys.map<DropdownMenuItem<String>>((String key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(key),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                _images.isEmpty
                    ? Text('Nenhuma imagem selecionada.')
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            final image = _images[index];
                            return ListTile(
                              leading: image['isLocal'] == true
                                  ? Icon(Icons.image) // Ícone para imagem local
                                  : Icon(Icons.cloud), // Ícone para imagem do servidor
                              title: Text(image['type']),
                              onTap: () => _viewImage(image), // Abre a visualização
trailing: IconButton(
  icon: Icon(Icons.delete, color: Colors.red),
  onPressed: () {
    if (!image['isLocal']) {
      // Se a imagem não for local (do servidor), chamar o método de exclusão
      _deleteImage(image['name']);
    } else {
      // Se a imagem for local, apenas remove da lista
      setState(() {
        _images.removeAt(index);
      });
    }
  },
),
                              
                            );
                          },
                        ),
                      ),
                SizedBox(height: 20),
                if (_isUploading) // Indicador de carregamento enquanto envia
                  CircularProgressIndicator()
                else
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _selectedPhotoType == null
                                ? null
                                : () => _pickImage(ImageSource.camera),
                            icon: Icon(Icons.camera),
                            label: Text('Tirar Foto'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _selectedPhotoType == null
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                            icon: Icon(Icons.photo),
                            label: Text('Selecionar da Galeria'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _images.any((image) => image['isLocal'] == true)
                            ? _uploadImages // Envia apenas novas fotos
                            : null,
                        child: Text('Salvar'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
  );
}  
}
