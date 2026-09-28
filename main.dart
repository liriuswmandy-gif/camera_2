import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa as câmeras disponíveis no dispositivo
  final cameras = await availableCameras();
  final primeiraCamera = cameras.isNotEmpty ? cameras.first : null;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TelaPrincipal(camera: primeiraCamera),
    ),
  );
}

// Widget principal com navegação por abas
class TelaPrincipal extends StatefulWidget {
  final CameraDescription? camera;

  const TelaPrincipal({super.key, this.camera});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  int _abaSelecionada = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> paginas = [
      const ConsultaELocalizacao(),
      widget.camera != null
          ? CameraApp(camera: widget.camera!)
          : const Center(child: Text('Nenhuma câmera encontrada.')),
    ];

    return Scaffold(
      body: paginas[_abaSelecionada],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _abaSelecionada,
        onTap: (index) {
          setState(() {
            _abaSelecionada = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'CEP & Localização',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Câmera',
          ),
        ],
      ),
    );
  }
}

// --- TELA DE CONSULTA E LOCALIZAÇÃO ---
class ConsultaELocalizacao extends StatefulWidget {
  const ConsultaELocalizacao({super.key});

  @override
  State<ConsultaELocalizacao> createState() => _ConsultaELocalizacaoState();
}

class _ConsultaELocalizacaoState extends State<ConsultaELocalizacao> {
  final cepController = TextEditingController();
  final latitudeController = TextEditingController(text: '-23.5505');
  final longitudeController = TextEditingController(text: '-46.6333');
  String endereco = '';

  String latitude = 'Aguardando...';
  String longitude = 'Aguardando...';

  Future<void> consultarCep() async {
    if (cepController.text.isEmpty) return;

    final url = Uri.parse(
      'https://viacep.com.br/ws/${cepController.text}/json/',
    );

    try {
      final resposta = await http.get(url);
      if (resposta.statusCode == 200) {
        final dados = jsonDecode(resposta.body);

        if (dados.containsKey('erro')) {
          setState(() {
            endereco = 'CEP não encontrado.';
          });
          return;
        }

        setState(() {
          endereco =
              '${dados['logradouro']}\n'
              '${dados['bairro']}\n'
              '${dados['localidade']} - ${dados['uf']}';
        });
      } else {
        setState(() {
          endereco = 'Erro ao buscar o CEP.';
        });
      }
    } catch (e) {
      setState(() {
        endereco = 'Erro de conexão.';
      });
    }
  }

  Future<void> buscarLocalizacao() async {
    final latitudeInformada = latitudeController.text.trim();
    final longitudeInformada = longitudeController.text.trim();

    if (latitudeInformada.isEmpty || longitudeInformada.isEmpty) {
      setState(() {
        latitude = 'Latitude inválida';
        longitude = 'Longitude inválida';
      });
      return;
    }

    setState(() {
      latitude = latitudeInformada;
      longitude = longitudeInformada;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CEP & Localização'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.location_on, size: 80, color: Colors.blue),
            const SizedBox(height: 20),

            // --- SEÇÃO DO CEP ---
            TextField(
              controller: cepController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Informe o CEP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: consultarCep,
              icon: const Icon(Icons.search),
              label: const Text('Consultar CEP'),
            ),
            const SizedBox(height: 15),
            Text(
              endereco,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),

            const Divider(height: 40, thickness: 1),

            // --- SEÇÃO DA LOCALIZAÇÃO ---
            TextField(
              controller: latitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitude',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: longitudeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitude',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            Text('Latitude: $latitude'),
            Text('Longitude: $longitude'),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: buscarLocalizacao,
              icon: const Icon(Icons.my_location),
              label: const Text('Usar coordenadas'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- TELA DA CÂMERA ---
class CameraApp extends StatefulWidget {
  final CameraDescription camera;

  const CameraApp({super.key, required this.camera});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController camera;
  XFile? foto;

  @override
  void initState() {
    super.initState();

    camera = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    camera.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    camera.dispose();
    super.dispose();
  }

  Future<void> tirarFoto() async {
    foto = await camera.takePicture();
    setState(() {});
  }

  Future<void> abrirCamera() async {
    foto = null;
    await camera.initialize();
    setState(() {});
  }

  Future<void> galeria() async {
    foto = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!camera.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Câmera'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: foto == null
                ? CameraPreview(camera)
                : FutureBuilder(
                    future: foto!.readAsBytes(),
                    builder: (_, imagem) {
                      if (!imagem.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return Image.memory(imagem.data!, fit: BoxFit.contain);
                    },
                  ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: foto == null ? tirarFoto : abrirCamera,
                child: Icon(foto == null ? Icons.camera_alt : Icons.camera),
              ),
              const SizedBox(width: 30),
              FloatingActionButton(
                onPressed: galeria,
                child: const Icon(Icons.photo),
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
