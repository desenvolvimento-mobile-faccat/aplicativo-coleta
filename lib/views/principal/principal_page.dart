import 'package:flutter/material.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

import './tabs/mapa_tab.dart';
import './tabs/perfil_tab.dart';
import './tabs/premios_tab.dart';
import './tabs/relatorios_tab.dart';
import 'relatar_descarte_page.dart';
import '../adicionar_ponto_page.dart'; 

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key});

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> {
  int _abaSelecionada = 0;

  // Método para verificar se o usuário é admin
  bool _isAdmin(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    return authViewModel.isAdmin;
  }

  // ✅ CORREÇÃO: Lista de telas como propriedade do estado
  late final List<Widget> _telas;

  @override
  void initState() {
    super.initState();
    // Inicializa as telas depois que o widget está montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarTelas();
    });
  }

  void _inicializarTelas() {
    final isAdmin = _isAdmin(context);
    
    setState(() {
      _telas = [
        const MapaTab(),
        const RelatoriosTab(),
        const GamificacaoTab(),
        if (isAdmin) AdicionarPontoPage(), // ✅ SEM const
        const PerfilTab(),
      ];
    });
  }

  // Itens do bottom navigation bar dinâmicos
  List<BottomNavigationBarItem> _buildBottomNavItems(BuildContext context) {
    final isAdmin = _isAdmin(context);
    
    if (isAdmin) {
      return const [
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
          icon: Icon(Icons.add_location_outlined),
          activeIcon: Icon(Icons.add_location),
          label: 'Adicionar Ponto',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    } else {
      return const [
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
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomNavItems = _buildBottomNavItems(context);
    final isAdmin = _isAdmin(context);

    // ✅ CORREÇÃO: Se as telas ainda não foram inicializadas, mostra loading
    if (_telas.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ CORREÇÃO: Ajusta o índice baseado no admin
    final indiceAjustado = isAdmin ? _abaSelecionada : 
        (_abaSelecionada >= 3 ? 3 : _abaSelecionada);

    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        title: const Text('Coleto Certa'),
        actions: [
          if (isAdmin)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'ADMIN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
      body: _telas[indiceAjustado], // ✅ Usa índice ajustado
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
        items: bottomNavItems,
      ),
      floatingActionButton: _abaSelecionada == 0 && !isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
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