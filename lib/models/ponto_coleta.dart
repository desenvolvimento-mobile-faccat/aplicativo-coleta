class PontoColeta {
  final String id;
  final String nome;
  final String endereco;
  final double latitude;
  final double longitude;
  final List<String> tiposAceitos; // ['Plástico', 'Papel', 'Vidro', etc]
  final String? telefone;
  final String? horarioFuncionamento;
  final String? observacoes;
  final DateTime dataCriacao;
  final bool ativo;

  PontoColeta({
    required this.id,
    required this.nome,
    required this.endereco,
    required this.latitude,
    required this.longitude,
    required this.tiposAceitos,
    this.telefone,
    this.horarioFuncionamento,
    this.observacoes,
    required this.dataCriacao,
    this.ativo = true,
  });

  // Converter para Map (para salvar no Firebase/banco)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'endereco': endereco,
      'latitude': latitude,
      'longitude': longitude,
      'tiposAceitos': tiposAceitos,
      'telefone': telefone,
      'horarioFuncionamento': horarioFuncionamento,
      'observacoes': observacoes,
      'dataCriacao': dataCriacao.toIso8601String(),
      'ativo': ativo,
    };
  }

  // Criar a partir de Map (para ler do Firebase/banco)
  factory PontoColeta.fromMap(Map<String, dynamic> map) {
    return PontoColeta(
      id: map['id'] ?? '',
      nome: map['nome'] ?? '',
      endereco: map['endereco'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      tiposAceitos: List<String>.from(map['tiposAceitos'] ?? []),
      telefone: map['telefone'],
      horarioFuncionamento: map['horarioFuncionamento'],
      observacoes: map['observacoes'],
      dataCriacao: DateTime.parse(map['dataCriacao'] ?? DateTime.now().toIso8601String()),
      ativo: map['ativo'] ?? true,
    );
  }

  // Copiar com modificações
  PontoColeta copyWith({
    String? id,
    String? nome,
    String? endereco,
    double? latitude,
    double? longitude,
    List<String>? tiposAceitos,
    String? telefone,
    String? horarioFuncionamento,
    String? observacoes,
    DateTime? dataCriacao,
    bool? ativo,
  }) {
    return PontoColeta(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      endereco: endereco ?? this.endereco,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      tiposAceitos: tiposAceitos ?? this.tiposAceitos,
      telefone: telefone ?? this.telefone,
      horarioFuncionamento: horarioFuncionamento ?? this.horarioFuncionamento,
      observacoes: observacoes ?? this.observacoes,
      dataCriacao: dataCriacao ?? this.dataCriacao,
      ativo: ativo ?? this.ativo,
    );
  }

  // Verificar se aceita determinado tipo de lixo
  bool aceitaTipo(String tipo) {
    return tiposAceitos.contains(tipo);
  }

  // Obter cor do marcador baseado nos tipos aceitos
  String getCorMarcador() {
    if (tiposAceitos.length >= 5) {
      return 'verde'; // Aceita vários tipos
    } else if (tiposAceitos.length >= 3) {
      return 'azul'; // Aceita alguns tipos
    } else {
      return 'laranja'; // Aceita poucos tipos
    }
  }
}