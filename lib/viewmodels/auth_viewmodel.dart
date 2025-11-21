import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  String? _errorMessage;
  AppUser? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppUser? get currentUser => _currentUser;

  // Nova propriedade para verificar se é admin
  bool get isAdmin {
    if (_currentUser == null) return false;
    
    // Verifica se o usuário tem role de admin
    if (_currentUser!.role == 'admin') return true;
    
    // Verifica por email específico (para desenvolvimento/backup)
    final userEmail = _currentUser!.email.toLowerCase();
    final adminEmails = [
      'admin@tercafeira.com',
      'administrador@tercafeira.com',
      'admin@coletocerta.com',
    ];
    
    return adminEmails.contains(userEmail) || userEmail.contains('admin');
  }

  Future<User?> login(String email, String password) async {
    try {
      _setLoading(true);
      final user = await _authService.signIn(email, password);
      if (user != null) {
        await _loadUserProfile(user.uid);
      }
      return user;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<User?> register(String email, String password, AppUser userData) async {
    try {
      _setLoading(true);
      final user = await _authService.signUp(email, password);
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set(userData.toFirestore());
        await _loadUserProfile(user.uid);
      }
      return user;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromMap(doc.data()!);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao carregar perfil: $e';
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao sair: $e';
      notifyListeners();
    }
  }

  Future<void> updateUser(AppUser updatedUser) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await _firestore.collection('users').doc(uid).update(updatedUser.toFirestore());
      _currentUser = updatedUser;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Erro ao atualizar usuário: $e';
      notifyListeners();
    }
  }

  // Método para promover usuário a admin
  Future<void> promoteToAdmin(String email) async {
    try {
      await _firestore.collection('users').doc(email).update({
        'role': 'admin',
      });
      
      // Se for o usuário atual, atualiza localmente
      if (_currentUser?.email == email ) {
        _currentUser = _currentUser?.copyWith(
          role: 'admin',
        );
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Erro ao promover usuário: $e';
      notifyListeners();
    }
  }

  // Método para verificar permissões específicas
  bool hasPermission(String permission) {
    if (!isAdmin) return false;
    
    // Aqui você pode adicionar lógica mais complexa de permissões
    switch (permission) {
      case 'manage_points':
      case 'manage_users':
      case 'view_reports':
      case 'register_collection_points':
        return isAdmin;
      default:
        return false;
    }
  }

  Future<void> addCollection() async {
    try {
      if (_currentUser == null) return;
      
      final now = DateTime.now();
      
      final earnedPoints = _calculateCollectionPoints(
        lastCollectionDate: _currentUser!.lastCollectionDate,
        currentDate: now,
      );
      
      int newPoints = _currentUser!.points + earnedPoints;
      int newLevel = AppUser.calculateLevel(newPoints);
      String newLevelTitle = AppUser.getLevelTitle(newLevel);
      int newTotalCollections = _currentUser!.totalCollections + 1;
      
      List<Achievement> newAchievements = _checkAchievements(
        totalCollections: newTotalCollections,
        currentAchievements: _currentUser!.achievements,
      );
      
      final updatedUser = _currentUser!.copyWith(
        points: newPoints,
        level: newLevel,
        levelTitle: newLevelTitle,
        totalCollections: newTotalCollections,
        achievements: [
          ..._currentUser!.achievements,
          ...newAchievements, 
        ],
        lastCollectionDate: now,
      );
      
      await updateUser(updatedUser);
    } catch (e) {
      _errorMessage = 'Erro ao atualizar gamificação: $e';
      notifyListeners();
    }
  }

  // Métodos privados de gamificação
  int _calculateCollectionPoints({
    DateTime? lastCollectionDate,
    required DateTime currentDate,
  }) {
    if (lastCollectionDate == null) {
      return 10; // Primeira coleta
    }
    
    final daysSinceLastCollection = 
        currentDate.difference(lastCollectionDate).inDays;
    
    if (daysSinceLastCollection == 0) {
      return 5; // Coleta no mesmo dia
    } else if (daysSinceLastCollection == 1) {
      return 15; // Coleta diária consecutiva (bônus)
    } else {
      return 10; // Coleta padrão
    }
  }
  
  List<Achievement> _checkAchievements({
    required int totalCollections,
    required List<Achievement> currentAchievements,
  }) {
    List<Achievement> newAchievements = [];
    
    // IDs dos achievements atuais
    Set<String> currentAchievementIds = 
        currentAchievements.map((a) => a.id).toSet();
    
    // Verifica cada achievement disponível
    for (Achievement achievement in Achievement.all) {
      // Se já tem o achievement, pula
      if (currentAchievementIds.contains(achievement.id)) {
        continue;
      }
      
      // Verifica se conquistou baseado no número de coletas
      bool earned = false;
      
      switch (achievement.id) {
        case 'first_collection':
          earned = totalCollections >= 1;
          break;
        case 'ten_collections':
          earned = totalCollections >= 10;
          break;
        case 'fifty_collections':
          earned = totalCollections >= 50;
          break;
        case 'eco_explorer':
          // Este seria conquistado por participação em eventos
          // Por enquanto, baseado em coletas
          earned = totalCollections >= 30;
          break;
      }
      
      if (earned) {
        newAchievements.add(achievement);
      }
    }
    
    return newAchievements;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Método auxiliar para limpar mensagens de erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}