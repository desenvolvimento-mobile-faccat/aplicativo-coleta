// lib/tabs/mapa_tab.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "../../../models/ponto_coleta.dart";


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
            ],
          ),
        ),
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
        // Card de filtro (opcional)
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
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
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