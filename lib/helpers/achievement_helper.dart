import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AchievementHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verifica e desbloqueia conquistas baseado nas estatísticas do usuário
  Future<List<Achievement>> checkAndUnlockAchievements({
    required int totalCollections,
    required int totalPoints,
    required List<Achievement> currentAchievements,
  }) async {
    List<Achievement> newAchievements = [];
    
    // IDs dos achievements que o usuário já tem
    Set<String> currentAchievementIds = 
        currentAchievements.map((a) => a.id).toSet();
    
    // Verifica cada achievement disponível
    for (Achievement achievement in Achievement.all) {
      // Se já tem o achievement, pula
      if (currentAchievementIds.contains(achievement.id)) {
        continue;
      }
      
      // Verifica se conquistou baseado nas condições
      bool earned = false;
      
      switch (achievement.id) {
        case 'first_collection':
          // Desbloqueia na primeira coleta
          earned = totalCollections >= 1;
          break;
          
        case 'ten_collections':
          // Desbloqueia ao fazer 10 coletas
          earned = totalCollections >= 10;
          break;
          
        case 'eco_explorer':
          // Desbloqueia ao atingir 300 pontos
          earned = totalPoints >= 300;
          break;
      }
      
      if (earned) {
        newAchievements.add(achievement);
      }
    }
    
    return newAchievements;
  }

  /// Atualiza as conquistas do usuário no Firestore
  Future<void> updateUserAchievements(List<Achievement> allAchievements) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Salva apenas os IDs
      final achievementIds = allAchievements.map((a) => a.id).toList();

      await _firestore.collection('users').doc(userId).update({
        'achievements': achievementIds,
      });
    } catch (e) {
      print('❌ Erro ao atualizar conquistas: $e');
    }
  }

  /// Verifica conquistas após registrar descarte
  Future<List<Achievement>> checkAfterDescarte({
    required AppUser user,
  }) async {
    final newAchievements = await checkAndUnlockAchievements(
      totalCollections: user.totalCollections,
      totalPoints: user.points,
      currentAchievements: user.achievements,
    );

    if (newAchievements.isNotEmpty) {
      // Atualiza no Firestore
      final allAchievements = [...user.achievements, ...newAchievements];
      await updateUserAchievements(allAchievements);
    }

    return newAchievements;
  }
}