// Modelos do usuário autenticado, como a API devolve em /auth/login e /auth/eu.

enum Papel {
  administrador,
  operador,
  membro;

  static Papel deTexto(String valor) =>
      Papel.values.firstWhere((p) => p.name == valor, orElse: () => throw FormatException('Papel desconhecido: $valor'));
}

class Organizacao {
  const Organizacao({
    required this.id,
    required this.nome,
    required this.status,
    this.logoUrl,
    this.corPrincipal,
  });

  final String id;
  final String nome;
  final String status;
  final String? logoUrl;
  final String? corPrincipal;

  bool get habilitada => status == 'HABILITADA';

  factory Organizacao.deJson(Map<String, dynamic> json) => Organizacao(
        id: json['id'] as String,
        nome: json['nome'] as String,
        status: json['status'] as String,
        logoUrl: json['logoUrl'] as String?,
        corPrincipal: json['corPrincipal'] as String?,
      );
}

class Usuario {
  const Usuario({
    required this.id,
    required this.papel,
    required this.nome,
    required this.email,
    required this.organizacao,
  });

  final String id;
  final Papel papel;
  final String nome;
  final String email;
  final Organizacao organizacao;

  factory Usuario.deJson(Map<String, dynamic> json) => Usuario(
        id: json['id'] as String,
        papel: Papel.deTexto(json['papel'] as String),
        nome: json['nome'] as String,
        email: json['email'] as String,
        organizacao: Organizacao.deJson(json['organizacao'] as Map<String, dynamic>),
      );
}
