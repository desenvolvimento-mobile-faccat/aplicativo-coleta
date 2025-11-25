import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import "../../../models/ponto_coleta.dart";
import "../../../viewmodels/auth_viewmodel.dart";


class MapaTab extends StatefulWidget {
  const MapaTab({super.key});

  @override
  State<MapaTab> createState() => _MapaTabState();
}

class _MapaTabState extends State<MapaTab> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _loading = true;

  // Posição inicial, mudar para o local do usuario
  static const LatLng _initialPosition = const LatLng(-29.644201, -50.781591); 

  @override
  void initState() {
    super.initState();
    _carregarPontos();
  }

  Future<void> _carregarPontos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('pontos_coleta').get();

      final Set<Marker> markers = {};

      for (var doc in snapshot.docs) {
        final ponto = PontoColeta.fromMap(doc.data());

        // Define a cor do marcador conforme sua própria lógica

        Color corMarcador;
        switch (ponto.getCorMarcador()) {
          case 'verde':
            corMarcador = Colors.green;
            break;
          case 'azul':
            corMarcador = Colors.blue;
            break;
          case 'laranja':
            corMarcador = Colors.orange;
            break;
          default:
            corMarcador = Colors.red;
        }

        markers.add(
          Marker(
            markerId: MarkerId(ponto.id),
            position: LatLng(ponto.latitude, ponto.longitude),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              corMarcador == Colors.green ? BitmapDescriptor.hueGreen :
              corMarcador == Colors.blue ? BitmapDescriptor.hueBlue :
              corMarcador == Colors.orange ? BitmapDescriptor.hueOrange :
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: ponto.nome,
              snippet:
                  '${ponto.tiposAceitos.join(', ')}\n${ponto.endereco ?? ''}',
            ),
            onTap: () => _mostrarDetalhesPonto(ponto),
          ),
        );
      }

      setState(() {
        _markers.clear();
        _markers.addAll(markers);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar pontos: $e')),
        );
      }
    }
  }

  void _mostrarDetalhesPonto(PontoColeta ponto) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final isAdmin = authViewModel.isAdmin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(ponto.nome,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (ponto.endereco != null)
                Text(ponto.endereco!, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ponto.tiposAceitos
                    .map((tipo) => Chip(
                          label: Text(tipo),
                          backgroundColor: Colors.green[100],
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              if (ponto.telefone != null)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(ponto.telefone!),
                ),
              if (ponto.horarioFuncionamento != null)
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(ponto.horarioFuncionamento!),
                ),
              if (ponto.observacoes != null)
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(ponto.observacoes!),
                ),
              
              // Botões de ação para administradores
              if (isAdmin) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _editarPonto(ponto);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _confirmarExclusao(ponto);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Excluir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _editarPonto(PontoColeta ponto) {
    // Controllers para os campos
    final nomeController = TextEditingController(text: ponto.nome);
    final enderecoController = TextEditingController(text: ponto.endereco);
    final telefoneController = TextEditingController(text: ponto.telefone ?? '');
    final horarioController = TextEditingController(text: ponto.horarioFuncionamento ?? '');
    final observacoesController = TextEditingController(text: ponto.observacoes ?? '');
    
    List<String> tiposSelecionados = List.from(ponto.tiposAceitos);
    final List<String> tiposDisponiveis = [
      'Plástico',
      'Papel',
      'Vidro',
      'Metal',
      'Orgânico',
      'Eletrônico',
      'Óleo',
      'Pilhas e Baterias',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Ponto de Coleta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: enderecoController,
                  decoration: const InputDecoration(
                    labelText: 'Endereço',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telefoneController,
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: horarioController,
                  decoration: const InputDecoration(
                    labelText: 'Horário de Funcionamento',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: observacoesController,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tipos Aceitos:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: tiposDisponiveis.map((tipo) {
                    final isSelected = tiposSelecionados.contains(tipo);
                    return FilterChip(
                      label: Text(tipo),
                      selected: isSelected,
                      onSelected: (selected) {
                        setDialogState(() {
                          if (selected) {
                            tiposSelecionados.add(tipo);
                          } else {
                            tiposSelecionados.remove(tipo);
                          }
                        });
                      },
                      selectedColor: Colors.green[200],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomeController.text.isEmpty || 
                    enderecoController.text.isEmpty ||
                    tiposSelecionados.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preencha os campos obrigatórios'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                try {
                  final pontoAtualizado = ponto.copyWith(
                    nome: nomeController.text,
                    endereco: enderecoController.text,
                    telefone: telefoneController.text.isEmpty ? null : telefoneController.text,
                    horarioFuncionamento: horarioController.text.isEmpty ? null : horarioController.text,
                    observacoes: observacoesController.text.isEmpty ? null : observacoesController.text,
                    tiposAceitos: tiposSelecionados,
                  );

                  await FirebaseFirestore.instance
                      .collection('pontos_coleta')
                      .doc(ponto.id)
                      .update(pontoAtualizado.toMap());

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ponto atualizado com sucesso!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _carregarPontos(); // Recarrega os pontos
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao atualizar: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao(PontoColeta ponto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o ponto "${ponto.nome}"?\n\nEsta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('pontos_coleta')
                    .doc(ponto.id)
                    .delete();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ponto excluído com sucesso!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _carregarPontos(); // Recarrega os pontos
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _initialPosition,
            zoom: 12,
          ),
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        ),
        if (_loading)
          const Center(child: CircularProgressIndicator()),
        // Card de informação
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.recycling, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(
                    '${_markers.length} pontos de coleta na região',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}