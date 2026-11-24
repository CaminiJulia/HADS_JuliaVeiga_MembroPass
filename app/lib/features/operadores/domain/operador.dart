import 'dart:convert';
import 'dart:typed_data';

/// Operador da organização, como o administrador vê no cadastro.
class Operador {
  const Operador({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    this.ativo = true,
    this.foto,
    this.checkinsHoje = 0,
    this.ultimoCheckin,
  });

  factory Operador.deJson(Map<String, dynamic> json) => Operador(
    id: json['id'] as String,
    nome: json['nome'] as String,
    email: json['email'] as String,
    telefone: json['telefone'] as String?,
    ativo: json['status'] == 'ATIVO',
    foto: json['foto'] == null ? null : base64Decode(json['foto'] as String),
    checkinsHoje: json['checkinsHoje'] as int? ?? 0,
    ultimoCheckin: json['ultimoCheckin'] == null ? null : DateTime.parse(json['ultimoCheckin'] as String).toLocal(),
  );

  final String id;
  final String nome;

  /// E-mail de login.
  final String email;
  final String? telefone;

  /// Inativo não consegue entrar no app.
  final bool ativo;

  /// Foto que o próprio operador colocou em "Meu perfil".
  final Uint8List? foto;

  /// Leituras de QR Code (ou número) que ele fez hoje.
  final int checkinsHoje;

  /// Última leitura que ele fez, em qualquer dia.
  final DateTime? ultimoCheckin;

  /// Até duas iniciais do nome, para o avatar sem foto.
  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    return (partes.first[0] + (partes.length > 1 ? partes.last[0] : '')).toUpperCase();
  }

  Operador copiarCom({required bool ativo}) => Operador(
    id: id,
    nome: nome,
    email: email,
    telefone: telefone,
    ativo: ativo,
    foto: foto,
    checkinsHoje: checkinsHoje,
    ultimoCheckin: ultimoCheckin,
  );
}

/// Dados do formulário de cadastrar ou editar um operador.
class DadosOperador {
  const DadosOperador({required this.nome, required this.email, this.telefone});

  final String nome;
  final String email;
  final String? telefone;

  Map<String, Object?> paraJson() => {'nome': nome, 'email': email, 'telefone': telefone};
}

/// Operador recém-cadastrado, com a senha provisória para repassar.
class OperadorCriado {
  const OperadorCriado(this.operador, this.senhaProvisoria, {this.emailEnviado = false});

  final Operador operador;
  final String senhaProvisoria;

  /// A API conseguiu mandar a senha para o e-mail do operador.
  final bool emailEnviado;
}

/// Senha provisória gerada de novo para um operador.
typedef SenhaGerada = ({String senha, bool emailEnviado});

/// Cadastro dos operadores pelo administrador.
/// Em caso de erro, lança `ErroApi` com a mensagem pronta para exibir.
abstract interface class OperadoresRepositorio {
  Future<List<Operador>> listar();
  Future<OperadorCriado> criar(DadosOperador dados);
  Future<Operador> editar(String id, DadosOperador dados);
  Future<Operador> alterarStatus(String id, {required bool ativo});

  /// Gera outra senha provisória (o operador esqueceu a dele).
  Future<SenhaGerada> novaSenha(String id);
}
