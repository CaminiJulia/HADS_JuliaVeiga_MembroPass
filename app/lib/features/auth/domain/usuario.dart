import 'papel.dart';

class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.papel,
    required this.organizacaoId,
  });

  final String id;
  final String nome;
  final String email;
  final Papel papel;
  final String organizacaoId;
}
