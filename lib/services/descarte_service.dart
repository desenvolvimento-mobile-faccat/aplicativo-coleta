import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/descarte_model.dart';
import '../models/user_model.dart';
import '../helpers/achievement_helper.dart';

class DescarteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AchievementHelper _achievementHelper = AchievementHelper();

  /// Registra um novo descarte e atualiza os pontos do usuário
  Future<String> registrarDescarte({
    required String tipo,
    required double peso,
    required int pontos,
    String? observacoes,
    String? imagemUrl,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      // Busca dados do usuário
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('Dados do usuário não encontrados');
      }

      final userData = userDoc.data()!;
      final userName = userData['name'] ?? 'Usuário';

      // Cria o descarte
      final descarte = Descarte(
        id: '',
        userId: currentUser.uid,
        userName: userName,
        tipo: tipo,
        peso: peso,
        pontos: pontos,
        observacoes: observacoes,
        imagemUrl: imagemUrl,
        latitude: latitude,
        longitude: longitude,
        status: 'pendente',
        dataRegistro: DateTime.now(),
      );

      // Usa uma transação para garantir consistência
      String descarteId = '';
      
      await _firestore.runTransaction((transaction) async {
        // ✅ PASSO 1: Todas as LEITURAS primeiro
        final userRef = _firestore.collection('users').doc(currentUser.uid);
        final userSnapshot = await transaction.get(userRef);
        
        if (!userSnapshot.exists) {
          throw Exception('Usuário não encontrado');
        }

        final currentPoints = userSnapshot.data()?['points'] ?? 0;
        final currentCollections = userSnapshot.data()?['totalCollections'] ?? 0;
        final newPoints = currentPoints + pontos;
        final newLevel = AppUser.calculateLevel(newPoints);
        final newLevelTitle = AppUser.getLevelTitle(newLevel);

        // ✅ PASSO 2: Agora fazemos as ESCRITAS
        
        // Cria o descarte
        final descarteRef = _firestore.collection('descartes').doc();
        descarteId = descarteRef.id;
        transaction.set(descarteRef, descarte.toFirestore());

        // Atualiza os pontos do usuário
        transaction.update(userRef, {
          'points': newPoints,
          'level': newLevel,
          'levelTitle': newLevelTitle,
          'totalCollections': currentCollections + 1,
          'lastCollectionDate': DateTime.now().toIso8601String(),
        });
      });

      // ✅ CORREÇÃO: Verifica e desbloqueia conquistas após o descarte
      await _checkAchievements(currentUser.uid);

      return descarteId;
    } catch (e) {
      throw Exception('Erro ao registrar descarte: $e');
    }
  }

  /// Verifica e atualiza conquistas após registrar descarte
  Future<List<Achievement>> _checkAchievements(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return [];

      final user = AppUser.fromMap(userDoc.data()!);
      return await _achievementHelper.checkAfterDescarte(user: user);
    } catch (e) {
      print('❌ Erro ao verificar conquistas: $e');
      return [];
    }
  }

  /// Busca todos os descartes do usuário atual
  Stream<List<Descarte>> getDescartesDoUsuario() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('descartes')
        .where('userId', isEqualTo: userId)
        .orderBy('dataRegistro', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Descarte.fromFirestore(doc))
            .toList());
  }

  /// Busca todos os descartes (para admins)
  Stream<List<Descarte>> getTodosDescartes() {
    return _firestore
        .collection('descartes')
        .orderBy('dataRegistro', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Descarte.fromFirestore(doc))
            .toList());
  }

  /// Busca descartes pendentes de verificação (para admins)
  Stream<List<Descarte>> getDescartesPendentes() {
    return _firestore
        .collection('descartes')
        .where('status', isEqualTo: 'pendente')
        .orderBy('dataRegistro', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Descarte.fromFirestore(doc))
            .toList());
  }

  /// Verifica um descarte (apenas admins)
  Future<void> verificarDescarte(String descarteId, bool aprovado) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      await _firestore.collection('descartes').doc(descarteId).update({
        'status': aprovado ? 'verificado' : 'rejeitado',
        'dataVerificacao': DateTime.now().toIso8601String(),
        'verificadoPor': currentUser.uid,
      });

      // Se rejeitado, reverte os pontos
      if (!aprovado) {
        final descarteDoc = await _firestore
            .collection('descartes')
            .doc(descarteId)
            .get();

        if (descarteDoc.exists) {
          final descarte = Descarte.fromFirestore(descarteDoc);
          await _reverterPontos(descarte.userId, descarte.pontos);
        }
      }
    } catch (e) {
      throw Exception('Erro ao verificar descarte: $e');
    }
  }

  /// Reverte pontos do usuário (usado quando descarte é rejeitado)
  Future<void> _reverterPontos(String userId, int pontos) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // ✅ LEITURA primeiro
        final userRef = _firestore.collection('users').doc(userId);
        final userSnapshot = await transaction.get(userRef);

        if (!userSnapshot.exists) {
          throw Exception('Usuário não encontrado');
        }

        final currentPoints = userSnapshot.data()?['points'] ?? 0;
        final currentCollections = userSnapshot.data()?['totalCollections'] ?? 0;
        final newPoints = (currentPoints - pontos).clamp(0, double.infinity).toInt();
        final newLevel = AppUser.calculateLevel(newPoints);
        final newLevelTitle = AppUser.getLevelTitle(newLevel);

        // ✅ ESCRITA depois
        transaction.update(userRef, {
          'points': newPoints,
          'level': newLevel,
          'levelTitle': newLevelTitle,
          'totalCollections': (currentCollections - 1).clamp(0, double.infinity),
        });
      });
    } catch (e) {
      throw Exception('Erro ao reverter pontos: $e');
    }
  }

  /// Busca estatísticas de descartes do usuário
  Future<Map<String, dynamic>> getEstatisticasUsuario() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('Usuário não autenticado');
      }

      final snapshot = await _firestore
          .collection('descartes')
          .where('userId', isEqualTo: userId)
          .get();

      double pesoTotal = 0;
      int pontosTotal = 0;
      Map<String, int> descartesPorTipo = {};

      for (var doc in snapshot.docs) {
        final descarte = Descarte.fromFirestore(doc);
        pesoTotal += descarte.peso;
        pontosTotal += descarte.pontos;
        
        descartesPorTipo[descarte.tipo] = 
            (descartesPorTipo[descarte.tipo] ?? 0) + 1;
      }

      return {
        'totalDescartes': snapshot.docs.length,
        'pesoTotal': pesoTotal,
        'pontosTotal': pontosTotal,
        'descartesPorTipo': descartesPorTipo,
      };
    } catch (e) {
      throw Exception('Erro ao buscar estatísticas: $e');
    }
  }

  /// Deleta um descarte (apenas o próprio usuário ou admin)
  Future<void> deletarDescarte(String descarteId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }

      final descarteDoc = await _firestore
          .collection('descartes')
          .doc(descarteId)
          .get();

      if (!descarteDoc.exists) {
        throw Exception('Descarte não encontrado');
      }

      final descarte = Descarte.fromFirestore(descarteDoc);

      // Verifica se é o dono do descarte
      if (descarte.userId != currentUser.uid) {
        throw Exception('Sem permissão para deletar este descarte');
      }

      // Reverte pontos se o descarte estava verificado
      if (descarte.status == 'verificado') {
        await _reverterPontos(descarte.userId, descarte.pontos);
      }

      // Deleta o descarte
      await _firestore.collection('descartes').doc(descarteId).delete();
    } catch (e) {
      throw Exception('Erro ao deletar descarte: $e');
    }
  }
}