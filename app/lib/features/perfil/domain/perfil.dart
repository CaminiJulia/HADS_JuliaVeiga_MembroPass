import 'dart:convert';
import 'dart:typed_data';

/// Dados da conta de quem está logado, mostrados na aba "Meu perfil".
class Perfil {
  const Perfil({
    required this.id,
    required this.nome,
    required this.email,
    required this.organizacaoNome,
    this.telefone,
    this.cargo,
    this.foto,
    this.fotoTipo,
  });

  factory Perfil.deJson(Map<String, dynamic> json) {
    final foto = json['foto'] as String?;
    return Perfil(
      id: json['id'] as String,
      nome: json['nome'] as String,
      email: json['email'] as String,
      organizacaoNome: json['organizacaoNome'] as String,
      telefone: json['telefone'] as String?,
      cargo: json['cargo'] as String?,
      foto: foto == null ? null : base64Decode(foto),
      fotoTipo: json['fotoTipo'] as String?,
    );
  }

  final String id;
  final String nome;

  /// E-mail de login: aparece no perfil, mas não é editado por ele.
  final String email;
  final String organizacaoNome;
  final String? telefone;
  final String? cargo;
  final Uint8List? foto;

  /// "image/png" ou "image/jpeg".
  final String? fotoTipo;

  /// Até duas iniciais do nome, para o avatar sem foto.
  String get iniciais {
    final partes = nome.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (partes.isEmpty) return '?';
    final primeira = partes.first[0];
    final ultima = partes.length > 1 ? partes.last[0] : '';
    return (primeira + ultima).toUpperCase();
  }
}

/// Alteração do perfil. Foto: [manterFoto] deixa a atual; senão, [foto] é a
/// nova (ou `null` para remover).
class DadosPerfil {
  const DadosPerfil({required this.nome, this.telefone, this.cargo, this.manterFoto = true, this.foto, this.fotoTipo});

  final String nome;
  final String? telefone;
  final String? cargo;
  final bool manterFoto;
  final Uint8List? foto;
  final String? fotoTipo;

  Map<String, Object?> paraJson() => {
    'nome': nome,
    'telefone': telefone,
    'cargo': cargo,
    if (!manterFoto) ...{'foto': foto == null ? null : base64Encode(foto!), 'fotoTipo': foto == null ? null : fotoTipo},
  };
}

abstract interface class PerfilRepositorio {
  Future<Perfil> buscar();
  Future<Perfil> salvar(DadosPerfil dados);

  /// Lança erro com a mensagem da API se a senha atual não conferir.
  Future<void> trocarSenha({required String senhaAtual, required String novaSenha});
}
