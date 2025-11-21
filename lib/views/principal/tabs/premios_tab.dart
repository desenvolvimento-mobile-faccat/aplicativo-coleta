import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../models/user_model.dart';

class GamificacaoTab extends StatelessWidget {
  const GamificacaoTab({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    print(user?.toMap());

    final userAchievementIds = user?.achievements.map((a) => a.id).toSet() ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: Colors.amber,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Seus Pontos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    '${user?.points ?? 0}',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Nível ${user?.level ?? 1}: ${user?.levelTitle ?? "Iniciante"}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Barra de progresso para o próximo nível
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nível ${user?.level ?? 1}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Nível ${(user?.level ?? 0) + 1}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: _calculateProgress(user?.points ?? 0, user?.level ?? 1),
                        backgroundColor: Colors.white30,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_getPointsToNextLevel(user?.points ?? 0, user?.level ?? 1)} pontos para o próximo nível',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Estatísticas
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.eco,
                  value: '${user?.totalCollections ?? 0}',
                  label: 'Coletas',
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.emoji_events,
                  value: '${user?.achievements.length ?? 0}',
                  label: 'Conquistas',
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Conquistas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          
          // Grid de conquistas dinâmico
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: Achievement.all.length,
            itemBuilder: (context, index) {
              final achievement = Achievement.all[index];
              final isUnlocked = userAchievementIds.contains(achievement.id);
              
              return _buildConquistaCard(
                emoji: achievement.emoji,
                titulo: achievement.title,
                descricao: achievement.description,
                desbloqueada: isUnlocked,
                requiredPoints: achievement.requiredPoints,
              );
            },
          ),
          
          const SizedBox(height: 30),
          const Text(
            'Prêmios Disponíveis',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          _buildPremioCard(
            context,
            'Desconto 10% - Loja Eco',
            500,
            Colors.green,
            user?.points ?? 0,
          ),
          const SizedBox(height: 12),
          _buildPremioCard(
            context,
            'Voucher R\$ 20 - Mercado Verde',
            1000,
            Colors.orange,
            user?.points ?? 0,
          ),
          const SizedBox(height: 12),
          _buildPremioCard(
            context,
            'Kit Sustentável',
            2500,
            Colors.red,
            user?.points ?? 0,
          ),
        ],
      ),
    );
  }

  double _calculateProgress(int points, int level) {
    final levelPoints = _getLevelPoints(level);
    final nextLevelPoints = _getLevelPoints(level + 1);
    
    if (level >= 6) return 1.0; // Nível máximo
    
    final currentLevelProgress = points - levelPoints;
    final pointsNeeded = nextLevelPoints - levelPoints;
    
    return (currentLevelProgress / pointsNeeded).clamp(0.0, 1.0);
  }
  
  int _getPointsToNextLevel(int points, int level) {
    if (level >= 6) return 0; // Nível máximo
    
    final nextLevelPoints = _getLevelPoints(level + 1);
    return nextLevelPoints - points;
  }
  
  int _getLevelPoints(int level) {
    switch (level) {
      case 1: return 0;
      case 2: return 100;
      case 3: return 300;
      case 4: return 600;
      case 5: return 1000;
      case 6: return 1500;
      default: return 0;
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
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

  Widget _buildConquistaCard({
    required String emoji,
    required String titulo,
    required String descricao,
    required bool desbloqueada,
    required int requiredPoints,
  }) {
    return GestureDetector(
      onTap: () {
        // Pode adicionar um dialog com mais detalhes da conquista
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: desbloqueada ? Colors.white : Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Text(
                    emoji,
                    style: TextStyle(
                      fontSize: 40,
                      color: desbloqueada ? null : Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: desbloqueada ? Colors.black : Colors.grey,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (!desbloqueada)
                Text(
                  '${requiredPoints}pts',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremioCard(
    BuildContext context,
    String titulo,
    int pontosNecessarios,
    Color cor,
    int pontosUsuario,
  ) {
    final bool disponivel = pontosUsuario >= pontosNecessarios;
    
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
              child: Icon(Icons.card_giftcard, color: cor, size: 32),
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
                  Row(
                    children: [
                      Text(
                        '$pontosNecessarios pontos',
                        style: TextStyle(
                          fontSize: 14,
                          color: disponivel ? cor : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!disponivel) ...[
                        const SizedBox(width: 8),
                        Text(
                          '(faltam ${pontosNecessarios - pontosUsuario})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: disponivel 
                ? () {
                    // Implementar lógica de resgate
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Resgatando: $titulo'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } 
                : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: disponivel ? Colors.blue : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(disponivel ? 'Resgatar' : 'Bloqueado'),
            ),
          ],
        ),
      ),
    );
  }
}
