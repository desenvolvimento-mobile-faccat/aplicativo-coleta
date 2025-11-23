import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:geolocator/geolocator.dart';
import './../../services/descarte_service.dart';

class RelatarDescartePage extends StatefulWidget {
  const RelatarDescartePage({super.key});

  @override
  State<RelatarDescartePage> createState() => _RelatarDescartePageState();
}

class _RelatarDescartePageState extends State<RelatarDescartePage> {
  final _formKey = GlobalKey<FormState>();
  final _pesoController = TextEditingController();
  final _observacoesController = TextEditingController();
  final DescarteService _descarteService = DescarteService();
  
  String? _tipoLixo;
  File? _imagemSelecionada;
  Position? _localizacao;
  bool _carregandoLocalizacao = false;
  bool _registrandoDescarte = false;
  
  final List<Map<String, dynamic>> _tiposLixo = [
    {'nome': 'Orgânico', 'icone': Icons.eco, 'pontos': 5},
    {'nome': 'Plástico', 'icone': Icons.recycling, 'pontos': 10},
    {'nome': 'Papel/Papelão', 'icone': Icons.description, 'pontos': 8},
    {'nome': 'Metal', 'icone': Icons.hardware, 'pontos': 15},
    {'nome': 'Vidro', 'icone': Icons.wine_bar, 'pontos': 12},
    {'nome': 'Eletrônico', 'icone': Icons.devices, 'pontos': 20},
  ];

  int _calcularPontos() {
    if (_tipoLixo == null || _pesoController.text.isEmpty) return 0;
    
    final tipo = _tiposLixo.firstWhere((t) => t['nome'] == _tipoLixo);
    final peso = double.tryParse(_pesoController.text) ?? 0;
    final pontosPorKg = tipo['pontos'] as int;
    
    // Pontos = peso * pontos do tipo
    int pontos = (peso * pontosPorKg).round();
    
    // Bônus por foto
    if (_imagemSelecionada != null) {
      pontos += 10;
    }
    
    return pontos;
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _capturarLocalizacao() async {
    setState(() {
      _carregandoLocalizacao = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desabilitado');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permissão de localização negada permanentemente');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _localizacao = position;
        _carregandoLocalizacao = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Localização capturada!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _carregandoLocalizacao = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selecionarImagem(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagemSelecionada = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarOpcoesImagem() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar Foto'),
              onTap: () {
                Navigator.pop(context);
                _selecionarImagem(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da Galeria'),
              onTap: () {
                Navigator.pop(context);
                _selecionarImagem(ImageSource.gallery);
              },
            ),
            if (_imagemSelecionada != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remover Foto'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _imagemSelecionada = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _registrarDescarte() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tipoLixo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione o tipo de lixo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_localizacao == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Capture a localização do descarte'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pontos = _calcularPontos();
    final peso = double.parse(_pesoController.text);

    setState(() {
      _registrandoDescarte = true;
    });

    try {
      // 🔥 REGISTRA NO FIREBASE E ATUALIZA PONTOS
      await _descarteService.registrarDescarte(
        tipo: _tipoLixo!,
        peso: peso,
        pontos: pontos,
        observacoes: _observacoesController.text.trim().isEmpty 
            ? null 
            : _observacoesController.text.trim(),
        imagemUrl: null, // Por enquanto sem upload de imagem
        latitude: _localizacao!.latitude,
        longitude: _localizacao!.longitude,
      );

      setState(() {
        _registrandoDescarte = false;
      });

      if (mounted) {
        // Mostrar diálogo de sucesso
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Text('Parabéns!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu descarte foi registrado com sucesso!',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green[400]!, Colors.green[600]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 32),
                      const SizedBox(width: 12),
                      Text(
                        '+$pontos pontos',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.recycling, color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '$peso kg de $_tipoLixo',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (_imagemSelecionada != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(Icons.add_a_photo, color: Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'Bônus de +10 pontos por foto',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Seus pontos foram atualizados!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    } catch (e) {
      setState(() {
        _registrandoDescarte = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar descarte: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pontosEstimados = _calcularPontos();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Descarte'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Card de motivação
            Card(
              color: Colors.green[50],
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.green[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.amber[700], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Registre seu descarte e ganhe pontos!',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tipo de lixo
            const Text(
              'Tipo de Material *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tiposLixo.map((tipo) {
                final isSelected = _tipoLixo == tipo['nome'];
                return FilterChip(
                  selected: isSelected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tipo['icone'] as IconData,
                        size: 18,
                        color: isSelected ? Colors.white : Colors.green[700],
                      ),
                      const SizedBox(width: 6),
                      Text(tipo['nome'] as String),
                      const SizedBox(width: 4),
                      Text(
                        '(${tipo['pontos']}pts/kg)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected ? Colors.white70 : Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                  onSelected: (selected) {
                    setState(() {
                      _tipoLixo = selected ? tipo['nome'] as String : null;
                    });
                  },
                  selectedColor: Colors.green[600],
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.green[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Peso
            const Text(
              'Quantidade (kg) *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pesoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ex: 2.5',
                prefixIcon: const Icon(Icons.scale),
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {}); // Atualiza pontos estimados
              },
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe a quantidade';
                }
                final peso = double.tryParse(value);
                if (peso == null || peso <= 0) {
                  return 'Quantidade inválida';
                }
                if (peso > 1000) {
                  return 'Quantidade muito alta';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Observações
            const Text(
              'Observações (opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _observacoesController,
              decoration: InputDecoration(
                hintText: 'Adicione detalhes sobre o descarte...',
                prefixIcon: const Icon(Icons.notes),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Foto
            const Text(
              'Foto do Descarte (opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _mostrarOpcoesImagem,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: _imagemSelecionada != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _imagemSelecionada!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Adicionar Foto',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+10 pontos bônus',
                              style: TextStyle(
                                color: Colors.amber[900],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Localização
            const Text(
              'Localização *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  if (_localizacao != null)
                    Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700]),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Localização capturada',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Lat: ${_localizacao!.latitude.toStringAsFixed(6)}, '
                                    'Lon: ${_localizacao!.longitude.toStringAsFixed(6)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ElevatedButton.icon(
                    onPressed: _carregandoLocalizacao ? null : _capturarLocalizacao,
                    icon: _carregandoLocalizacao
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_localizacao == null
                        ? 'Capturar Localização'
                        : 'Atualizar Localização'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Preview de pontos
            if (pontosEstimados > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.amber[100]!, Colors.amber[50]!],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars, color: Colors.amber, size: 28),
                    const SizedBox(width: 12),
                    Text(
                      'Você vai ganhar $pontosEstimados pontos!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Botão registrar
            ElevatedButton(
              onPressed: _registrandoDescarte ? null : _registrarDescarte,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _registrandoDescarte
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Registrar Descarte',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}