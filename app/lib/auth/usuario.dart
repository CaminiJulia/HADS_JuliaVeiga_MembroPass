/// Os três papéis de acesso do MembroPass (DVP, RF02).
/// Cada papel tem cadastro próprio; o e-mail identifica a qual deles a pessoa pertence (RF01).
enum Papel {
  administrador('Administrador da organização'),
  operador('Operador'),
  membro('Membro');

  const Papel(this.descricao);

  final String descricao;
}

class Usuario {
  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.papel,
    required this.organizacaoId,
  });

  final int id;
  final String nome;
  final String email;
  final Papel papel;
  final int organizacaoId;
}
