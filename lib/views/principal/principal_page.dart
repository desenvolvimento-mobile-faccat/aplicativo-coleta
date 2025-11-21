import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

import './tabs/mapa_tab.dart';
import './tabs/perfil_tab.dart';
import './tabs/premios_tab.dart';
import './tabs/relatorios_tab.dart';
import 'relatar_descarte_page.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  int _abaSelecionada = 0;

  final List<Widget> _telas = [
    const MapaTab(),
    const RelatoriosTab(),
    const GamificacaoTab(),
    const PerfilTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Coleto Certa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Notificações
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              // Configurações
            },
          ),
        ],
      ),
      body: _telas[_abaSelecionada],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _abaSelecionada,
        onTap: (index) {
          setState(() {
            _abaSelecionada = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Mapa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'Relatórios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Prêmios',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
      floatingActionButton: _abaSelecionada == 0
          ? FloatingActionButton.extended(
              onPressed: () {
                // Relatar descarte
                _mostrarDialogoRelatar(context);
              },
              backgroundColor: Colors.green,
              icon: const Icon(Icons.add_location),
              label: const Text('Relatar Descarte'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _mostrarDialogoRelatar(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const RelatarDescartePage(),
    ),
  );
  }
}