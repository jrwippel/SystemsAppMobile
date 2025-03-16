import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AvariasScreen extends StatefulWidget {
  final int orderId;

  const AvariasScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _AvariasScreenState createState() => _AvariasScreenState();
}

class _AvariasScreenState extends State<AvariasScreen> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final List<Map<String, dynamic>> _markers = [];
  final String _imagePath = 'assets/avarias.png';
  ui.Image? _loadedImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final image = AssetImage(_imagePath);
    final completer = Completer<ui.Image>();

    image.resolve(ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      }),
    );

    _loadedImage = await completer.future;

    setState(() {}); // Atualiza a interface quando a imagem for carregada
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Selecionar Avarias"),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTapDown: (TapDownDetails details) {
                if (_loadedImage != null) {
                  _handleTap(details.localPosition);
                }
              },
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: CustomPaint(
                  size: Size.infinite,
                  painter: AvariaPainter(
                    image: _loadedImage,
                    markers: _markers,
                  ),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _captureAndSendImage,
            child: Text("Salvar Imagem"),
          ),
        ],
      ),
    );
  }

  void _handleTap(Offset position) {
    int? markerIndex = _getMarkerIndexAtPosition(position);

    if (markerIndex != null) {
      // Perguntar se o usuário deseja remover o marcador
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Remover Marcador'),
            content: Text('Deseja remover este marcador?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _markers.removeAt(markerIndex);
                  });
                  Navigator.of(context).pop();
                },
                child: Text('Remover'),
              ),
            ],
          );
        },
      );
    } else {
      // Adicionar novo marcador
      _addMarker(position);
    }
  }

  void _addMarker(Offset position) {
    setState(() {
      _markers.add({
        'position': position,
        'tipo': 'Tipo não definido',
      });
    });

    // Exibir o diálogo para selecionar o tipo de avaria
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedValue;
        return AlertDialog(
          title: Text('Selecionar Tipo de Avaria'),
          content: DropdownButtonFormField<String>(
            items: ['Riscos', 'Mossas', 'Falta', 'Partido', 'Arranhado', 'Não funciona']
                .map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (String? newValue) {
              selectedValue = newValue;
            },
            decoration: InputDecoration(
              labelText: 'Tipo de Avaria',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (selectedValue != null) {
                  setState(() {
                    _markers.last['tipo'] = selectedValue;
                  });
                }
                Navigator.of(context).pop();
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  int? _getMarkerIndexAtPosition(Offset position) {
    const double tolerance = 15.0; // Tolerância para detectar cliques próximos

    for (int i = 0; i < _markers.length; i++) {
      final Offset markerPosition = _markers[i]['position'];
      if ((markerPosition - position).distance <= tolerance) {
        return i; // Retorna o índice do marcador encontrado
      }
    }
    return null; // Retorna null se nenhum marcador for encontrado
  }

  Future<void> _captureAndSendImage() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        Uint8List capturedImage = byteData.buffer.asUint8List();

        await _sendImageToBackend(capturedImage);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagem salva com sucesso!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar a imagem. Tente novamente!')),
      );
      print("Erro ao capturar a imagem: $e");
    }
  }

  Future<void> _sendImageToBackend(Uint8List imageBytes) async {
    try {
      final uri = Uri.parse('http://10.0.2.2:8000/api/ApiPedidos/UploadFotoPedido');
      final request = http.MultipartRequest('POST', uri);

      request.fields['TipoFoto'] = 'Avaria';
      request.fields['NomeFoto'] = 'avaria_imagem.png';
      request.fields['PedidoId'] = widget.orderId.toString();
      request.fields['TipoFotoPedido'] = '1';

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'avaria_imagem.png',
        contentType: MediaType('image', 'png'),
      ));

      final response = await request.send();

      if (response.statusCode == 200) {
        print('Imagem enviada com sucesso');
      } else {
        print('Erro ao enviar imagem: ${response.statusCode}');
      }
    } catch (e) {
      print("Erro ao enviar a imagem: $e");
    }
  }
}

class AvariaPainter extends CustomPainter {
  final ui.Image? image;
  final List<Map<String, dynamic>> markers;

  AvariaPainter({required this.image, required this.markers});

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      final paint = Paint();

      double scaleX = size.width / image!.width;
      double scaleY = size.height / image!.height;
      double scale = scaleX < scaleY ? scaleX : scaleY;

      double imageWidth = image!.width * scale;
      double imageHeight = image!.height * scale;

      double offsetX = (size.width - imageWidth) / 2;
      double offsetY = (size.height - imageHeight) / 2;

      canvas.drawImageRect(
        image!,
        Rect.fromLTWH(0, 0, image!.width.toDouble(), image!.height.toDouble()),
        Rect.fromLTWH(offsetX, offsetY, imageWidth, imageHeight),
        paint,
      );

      for (var marker in markers) {
        Offset position = marker['position'];
        canvas.drawCircle(
          position,
          8.0,
          Paint()..color = Colors.red,
        );
        TextSpan span = TextSpan(
          text: marker['tipo'],
          style: TextStyle(color: Colors.red, fontSize: 12),
        );
        TextPainter textPainter = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, position.translate(10, -10));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
