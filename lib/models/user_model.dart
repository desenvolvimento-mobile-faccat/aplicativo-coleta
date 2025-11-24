import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String name;
  final String email;
  final String phone;
  final String city;
  final String uf;
  final String role;
  final DateTime? createdAt;

  // Sistema de Gamificação
  final int points;
  final int level;
  final String levelTitle;
  final int totalCollections;
  final List<Achievement> achievements;
  final DateTime? lastCollectionDate;

  AppUser({
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    required this.uf,
    this.role = 'member',
    this.createdAt,
    this.points = 0,
    this.level = 1,
    this.levelTitle = 'Iniciante',
    this.totalCollections = 0,
    this.achievements = const [],
    this.lastCollectionDate,
  });

  // Método para uso local - retorna achievements completos
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'uf': uf,
      'role': role,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'points': points,
      'level': level,
      'levelTitle': levelTitle,
      'totalCollections': totalCollections,
      // Retorna os achievements completos para uso local
      'achievements': achievements.map((a) => {
        'id': a.id,
        'title': a.title,
        'emoji': a.emoji,
        'description': a.description,
        'requiredPoints': a.requiredPoints,
      }).toList(),
      'lastCollectionDate': lastCollectionDate != null
          ? Timestamp.fromDate(lastCollectionDate!)
          : null,
    };
  }

  // Método específico para salvar no Firestore - salva apenas IDs
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'city': city,
      'uf': uf,
      'role': role,
      'createdAt': createdAt != null
          ? createdAt!.toIso8601String()
          : DateTime.now().toIso8601String(),
      'points': points,
      'level': level,
      'levelTitle': levelTitle,
      'totalCollections': totalCollections,
      // Salva apenas os IDs no Firestore
      'achievements': achievements.map((a) => a.id).toList(),
      'lastCollectionDate': lastCollectionDate?.toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final int points = map['points'] ?? 0;
    final int calculatedLevel = AppUser.calculateLevel(points);
    final String calculatedTitle = AppUser.getLevelTitle(calculatedLevel);

    // Verifica se achievements são objetos completos ou apenas IDs
    final List<dynamic> rawAchievements = map['achievements'] ?? [];
    List<Achievement> resolvedAchievements = [];
    
    if (rawAchievements.isNotEmpty) {
      // Se o primeiro item é um Map, então temos objetos completos
      if (rawAchievements.first is Map<String, dynamic>) {
        resolvedAchievements = rawAchievements
            .map((a) => Achievement(
                  id: a['id'],
                  title: a['title'],
                  emoji: a['emoji'],
                  description: a['description'],
                  requiredPoints: a['requiredPoints'],
                ))
            .toList();
      } else {
        // Se não, são IDs (strings) que precisamos resolver
        resolvedAchievements = rawAchievements
            .map((id) => Achievement.getById(id.toString()))
            .whereType<Achievement>()
            .toList();
      }
    }

    // Parse das datas
    DateTime? parsedCreatedAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedCreatedAt = DateTime.parse(map['createdAt']);
      }
    }

    DateTime? parsedLastCollection;
    if (map['lastCollectionDate'] != null) {
      if (map['lastCollectionDate'] is Timestamp) {
        parsedLastCollection = (map['lastCollectionDate'] as Timestamp).toDate();
      } else if (map['lastCollectionDate'] is String) {
        parsedLastCollection = DateTime.parse(map['lastCollectionDate']);
      }
    }

    return AppUser(
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      city: map['city'] ?? '',
      uf: map['uf'] ?? '',
      role: map['role'] ?? 'member',
      createdAt: parsedCreatedAt,
      points: points,
      level: calculatedLevel,
      levelTitle: calculatedTitle,
      totalCollections: map['totalCollections'] ?? 0,
      achievements: resolvedAchievements,
      lastCollectionDate: parsedLastCollection,
    );
  }

  static int calculateLevel(int points) {
    if (points < 100) return 1;
    if (points < 300) return 2;
    if (points < 600) return 3;
    if (points < 1000) return 4;
    if (points < 1500) return 5;
    return 6;
  }

  static String getLevelTitle(int level) {
    switch (level) {
      case 1:
        return 'Iniciante';
      case 2:
        return 'Coletor';
      case 3:
        return 'Reciclador';
      case 4:
        return 'Eco Guerreiro';
      case 5:
        return 'Guardião Ambiental';
      case 6:
        return 'Mestre da Sustentabilidade';
      default:
        return 'Iniciante';
    }
  }

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? city,
    String? uf,
    String? role,
    DateTime? createdAt,
    int? points,
    int? level,
    String? levelTitle,
    int? totalCollections,
    List<Achievement>? achievements,
    DateTime? lastCollectionDate,
  }) {
    return AppUser(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      uf: uf ?? this.uf,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      points: points ?? this.points,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      totalCollections: totalCollections ?? this.totalCollections,
      achievements: achievements ?? this.achievements,
      lastCollectionDate: lastCollectionDate ?? this.lastCollectionDate,
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String emoji;
  final String description;
  final int requiredPoints;

  const Achievement({
    required this.id,
    required this.title,
    required this.emoji,
    required this.description,
    required this.requiredPoints,
  });

  static const List<Achievement> all = [
    Achievement(
      id: 'first_collection',
      title: 'Primeira Coleta',
      emoji: '🌱',
      description: 'Realize sua primeira coleta!',
      requiredPoints: 0,
    ),
    Achievement(
      id: 'ten_collections',
      title: '10 Coletas',
      emoji: '♻️',
      description: 'Realize 10 coletas sustentáveis.',
      requiredPoints: 100,
    ),
    Achievement(
      id: 'eco_explorer',
      title: 'Explorador Ecológico',
      emoji: '🌍',
      description: 'Participe de um evento ambiental.',
      requiredPoints: 300,
    ),
  ];

  static Achievement? getById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}