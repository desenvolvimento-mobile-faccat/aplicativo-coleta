import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/ponto_coleta.dart';


class AdicionarPontoPage extends StatefulWidget {
  const AdicionarPontoPage({super.key});

  @override
  State<AdicionarPontoPage> createState() => _AdicionarPontoPageState();
}

class _AdicionarPontoPageState extends State<AdicionarPontoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _horarioController = TextEditingController();
  final _observacoesController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _localizacaoSelecionada;
  final List<String> _tiposSelecionados = [];

  final List<Map<String, dynamic>> _tiposLixo = [
    {'nome': 'Orgânico', 'icone': Icons.eco, 'cor': Colors.brown},
    {'nome': 'Plástico', 'icone': Icons.recycling, 'cor': Colors.red},
    {'nome': 'Papel', 'icone': Icons.description, 'cor': Colors.blue},
    {'nome': 'Metal', 'icone': Icons.hardware, 'cor': Colors.grey},
    {'nome': 'Vidro', 'icone': Icons.wine_bar, 'cor': Colors.green},
    {'nome': 'Eletrônico', 'icone': Icons.devices, 'cor': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _obterLocalizacaoAtual();
  }

  Future<void> _obterLocalizacaoAtual() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _localizacaoSelecionada = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      // Localização padrão se falhar (Porto Alegre)
      setState(() {
        _localizacaoSelecionada = const LatLng(-30.0346, -51.2177);
      });
    }
  }

  Future<void> _salvarPonto() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tiposSelecionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um tipo de material aceito'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_localizacaoSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione a localização no mapa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Criar objeto PontoColeta
    final novoPonto = PontoColeta(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nome: _nomeController.text,
      endereco: _enderecoController.text,
      latitude: _localizacaoSelecionada!.latitude,
      longitude: _localizacaoSelecionada!.longitude,
      tiposAceitos: _tiposSelecionados,
      telefone: _telefoneController.text.isEmpty ? null : _telefoneController.text,
      horarioFuncionamento: _horarioController.text.isEmpty ? null : _horarioController.text,
      observacoes: _observacoesController.text.isEmpty ? null : _observacoesController.text,
      dataCriacao: DateTime.now(),
    );

    // AQUI VOCÊ SALVARIA NO FIREBASE/BACKEND
    // Exemplo: await FirebaseFirestore.instance.collection('pontos_coleta').add(novoPonto.toMap());
    
    await Future.delayed(const Duration(seconds: 2)); // Simular salvamento

    if (mounted) {
      Navigator.pop(context); // Fechar loading

      // Mostrar sucesso
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Sucesso!'),
            ],
          ),
          content: const Text('Ponto de coleta adicionado com sucesso!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Fechar diálogo
                Navigator.pop(context); // Voltar para tela anterior
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    print('Ponto salvo: ${novoPonto.toMap()}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Ponto de Coleta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Como usar'),
                  content: const Text(
                    '1. Preencha os dados do ponto de coleta\n'
                    '2. Selecione os tipos de materiais aceitos\n'
                    '3. Toque no mapa para definir a localização\n'
                    '4. Clique em Salvar',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Entendi'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card de aviso admin
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.orange[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Área Administrativa',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nome do ponto
            const Text(
              'Nome do Ponto *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(
                hintText: 'Ex: Ecoponto Centro',
                prefixIcon: const Icon(Icons.place),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do ponto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Endereço
            const Text(
              'Endereço *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _enderecoController,
              decoration: InputDecoration(
                hintText: 'Ex: Rua dos Andradas, 1000 - Centro',
                prefixIcon: const Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o endereço';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Telefone
            const Text(
              'Telefone (opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _telefoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: '(51) 3333-4444',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Horário
            const Text(
              'Horário de Funcionamento (opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _horarioController,
              decoration: InputDecoration(
                hintText: 'Ex: Seg-Sex: 8h-18h',
                prefixIcon: const Icon(Icons.access_time),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Observações
            const Text(
              'Observações (opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _observacoesController,
              decoration: InputDecoration(
                hintText: 'Informações adicionais...',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Tipos aceitos
            const Text(
              'Materiais Aceitos *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tiposLixo.map((tipo) {
                    final isSelected = _tiposSelecionados.contains(tipo['nome']);
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tipo['icone'] as IconData,
                            size: 18,
                            color: isSelected ? Colors.white : tipo['cor'] as Color,
                          ),
                          const SizedBox(width: 6),
                          Text(tipo['nome'] as String),
                        ],
                      ),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _tiposSelecionados.add(tipo['nome'] as String);
                          } else {
                            _tiposSelecionados.remove(tipo['nome']);
                          }
                        });
                      },
                      selectedColor: tipo['cor'] as Color,
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Mapa para selecionar localização
            const Text(
              'Localização no Mapa *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _localizacaoSelecionada == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _localizacaoSelecionada!,
                          zoom: 15,
                        ),
                        markers: _localizacaoSelecionada != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('ponto'),
                                  position: _localizacaoSelecionada!,
                                  draggable: true,
                                  onDragEnd: (newPosition) {
                                    setState(() {
                                      _localizacaoSelecionada = newPosition;
                                    });
                                  },
                                ),
                              }
                            : {},
                        onTap: (position) {
                          setState(() {
                            _localizacaoSelecionada = position;
                          });
                        },
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no mapa ou arraste o marcador para definir a localização',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (_localizacaoSelecionada != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lat: ${_localizacaoSelecionada!.latitude.toStringAsFixed(6)}, '
                'Lon: ${_localizacaoSelecionada!.longitude.toStringAsFixed(6)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 32),

            // Botão salvar
            ElevatedButton.icon(
              onPressed: _salvarPonto,
              icon: const Icon(Icons.save, size: 24),
              label: const Text(
                'Salvar Ponto de Coleta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _enderecoController.dispose();
    _telefoneController.dispose();
    _horarioController.dispose();
    _observacoesController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}