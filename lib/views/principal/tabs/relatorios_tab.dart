import 'package:flutter/material.dart';

class RelatoriosTab extends StatelessWidget {
  const RelatoriosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seus Relatórios',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          _buildRelatorioCard(
            'Descarte Orgânico',
            '5 relatórios este mês',
            Icons.compost,
            Colors.green,
            '120 kg',
          ),
          const SizedBox(height: 12),
          _buildRelatorioCard(
            'Reciclagem',
            '8 relatórios este mês',
            Icons.recycling,
            Colors.blue,
            '45 kg',
          ),
          const SizedBox(height: 12),
          _buildRelatorioCard(
            'Descartes Irregulares',
            '2 denúncias feitas',
            Icons.warning_amber,
            Colors.orange,
            '2 locais',
          ),
          const SizedBox(height: 30),
          const Text(
            'Notícias Ambientais',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          _buildNoticiaCard(
            'Nova lei de reciclagem aprovada',
            'Medida visa aumentar a coleta seletiva em 40%',
            'Há 2 horas',
          ),
          const SizedBox(height: 12),
          _buildNoticiaCard(
            'Campanha de limpeza de praias',
            'Voluntários coletaram 5 toneladas de resíduos',
            'Há 5 horas',
          ),
          const SizedBox(height: 12),
          _buildNoticiaCard(
            'Novo ponto de coleta inaugurado',
            'Unidade aceita eletrônicos e pilhas',
            'Ontem',
          ),
        ],
      ),
    );
  }

  Widget _buildRelatorioCard(
      String titulo, String subtitulo, IconData icone, Color cor, String valor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icone, color: cor, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              valor,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoticiaCard(String titulo, String descricao, String tempo) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tempo,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
