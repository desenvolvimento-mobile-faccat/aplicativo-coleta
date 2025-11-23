import 'package:cloud_firestore/cloud_firestore.dart';

class Descarte {
  final String id;
  final String userId;
  final String userName;
  final String tipo; // 'Orgânico', 'Plástico', etc.
  final double peso; // em kg
  final int pontos;
  final String? observacoes;
  final String? imagemUrl; // URL da imagem (se implementar futuramente)
  final double latitude;
  final double longitude;
  final String status; // 'pendente', 'verificado', 'rejeitado'
  final DateTime dataRegistro;
  final DateTime? dataVerificacao;
  final String? verificadoPor; // ID do admin que verificou

  Descarte({
    required this.id,
    required this.userId,
    required this.userName,
    required this.tipo,
    required this.peso,
    required this.pontos,
    this.observacoes,
    this.imagemUrl,
    required this.latitude,
    required this.longitude,
    this.status = 'pendente',
    required this.dataRegistro,
    this.dataVerificacao,
    this.verificadoPor,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'tipo': tipo,
      'peso': peso,
      'pontos': pontos,
      'observacoes': observacoes,
      'imagemUrl': imagemUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'dataRegistro': dataRegistro.toIso8601String(),
      'dataVerificacao': dataVerificacao?.toIso8601String(),
      'verificadoPor': verificadoPor,
    };
  }

  factory Descarte.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Descarte(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      tipo: data['tipo'] ?? '',
      peso: (data['peso'] ?? 0).toDouble(),
      pontos: data['pontos'] ?? 0,
      observacoes: data['observacoes'],
      imagemUrl: data['imagemUrl'],
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      status: data['status'] ?? 'pendente',
      dataRegistro: DateTime.parse(
        data['dataRegistro'] ?? DateTime.now().toIso8601String()
      ),
      dataVerificacao: data['dataVerificacao'] != null
          ? DateTime.parse(data['dataVerificacao'])
          : null,
      verificadoPor: data['verificadoPor'],
    );
  }

  Descarte copyWith({
    String? id,
    String? userId,
    String? userName,
    String? tipo,
    double? peso,
    int? pontos,
    String? observacoes,
    String? imagemUrl,
    double? latitude,
    double? longitude,
    String? status,
    DateTime? dataRegistro,
    DateTime? dataVerificacao,
    String? verificadoPor,
  }) {
    return Descarte(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      tipo: tipo ?? this.tipo,
      peso: peso ?? this.peso,
      pontos: pontos ?? this.pontos,
      observacoes: observacoes ?? this.observacoes,
      imagemUrl: imagemUrl ?? this.imagemUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      dataRegistro: dataRegistro ?? this.dataRegistro,
      dataVerificacao: dataVerificacao ?? this.dataVerificacao,
      verificadoPor: verificadoPor ?? this.verificadoPor,
    );
  }

  // Método auxiliar para formatar data
  String get dataFormatada {
    return '${dataRegistro.day.toString().padLeft(2, '0')}/'
        '${dataRegistro.month.toString().padLeft(2, '0')}/'
        '${dataRegistro.year}';
  }

  // Método auxiliar para obter cor do status
  String get statusColor {
    switch (status) {
      case 'verificado':
        return 'verde';
      case 'rejeitado':
        return 'vermelho';
      default:
        return 'laranja';
    }
  }
}