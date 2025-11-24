import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../models/user_model.dart';

class GamificacaoTab extends StatefulWidget {
  const GamificacaoTab({super.key});

  @override
  State<GamificacaoTab> createState() => _GamificacaoTabState();
}

class _GamificacaoTabState extends State<GamificacaoTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  int? _previousPoints;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _checkPointsChange(int currentPoints) {
    if (_previousPoints != null && currentPoints > _previousPoints!) {
      // Pontos aumentaram! Anima
      _animationController.forward().then((_) {
        _animationController.reverse();
      });
      
      // Mostra snackbar celebrando
      final pointsGained = currentPoints - _previousPoints!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber),
              const SizedBox(width: 12),
              Text('+$pointsGained pontos ganhos!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _previousPoints = currentPoints;
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final user = authViewModel.currentUser;

    // Verifica se pontos mudaram
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPointsChange(user.points);
      });
    }

    final userAchievementIds = user?.achievements.map((a) => a.id).toSet() ?? {};

    return RefreshIndicator(
      onRefresh: () async {
        await authViewModel.refreshUser();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card principal de pontos com animação
            ScaleTransition(
              scale: _scaleAnimation,
              child: Card(
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
                      TweenAnimationBuilder<int>(
                        tween: IntTween(
                          begin: _previousPoints ?? user?.points ?? 0,
                          end: user?.points ?? 0,
                        ),
                        duration: const Duration(milliseconds: 800),
                        builder: (context, value, child) {
                          return Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        },
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
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0,
                              end: _calculateProgress(user?.points ?? 0, user?.level ?? 1),
                            ),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            builder: (context, value, child) {
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white30,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                                minHeight: 8,
                              );
                            },
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Conquistas',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                Text(
                  '${user?.achievements.length ?? 0}/${Achievement.all.length}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
                childAspectRatio: 0.75, // Aumentado para dar mais altura
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
            const SizedBox(height: 24),
            
            // Botão de atualizar
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await authViewModel.refreshUser();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dados atualizados!'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Atualizar Dados'),
              ),
            ),
          ],
        ),
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
    return (nextLevelPoints - points).clamp(0, double.infinity).toInt();
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(emoji, style: const TextStyle(fontSize: 48), textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  descricao,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: desbloqueada ? Colors.green[50] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: desbloqueada ? Colors.green : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        desbloqueada ? Icons.check_circle : Icons.lock,
                        color: desbloqueada ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          desbloqueada ? 'Desbloqueada!' : '$requiredPoints pontos necessários',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: desbloqueada ? Colors.green : Colors.grey[700],
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ],
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: desbloqueada ? Colors.white : Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      emoji,
                      style: TextStyle(
                        fontSize: 32,
                        color: desbloqueada ? null : Colors.grey,
                      ),
                    ),
                    if (!desbloqueada)
                      Icon(
                        Icons.lock,
                        color: Colors.grey[600],
                        size: 18,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: desbloqueada ? Colors.black : Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!desbloqueada) ...[
                const SizedBox(height: 2),
                Text(
                  '${requiredPoints}pts',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey[500],
                  ),
                ),
              ],
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
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.card_giftcard, color: cor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '$pontosNecessarios pts',
                        style: TextStyle(
                          fontSize: 12,
                          color: disponivel ? cor : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!disponivel) ...[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '(faltam ${pontosNecessarios - pontosUsuario})',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(70, 36),
              ),
              child: Text(
                disponivel ? 'Resgatar' : 'Bloqueado',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}