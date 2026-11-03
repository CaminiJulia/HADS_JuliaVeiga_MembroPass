import 'dart:convert';
import 'dart:typed_data';

/// Organização e sua identidade visual, aplicada a todas as carteirinhas (RF17).
class Organizacao {
  const Organizacao({required this.id, required this.nome, this.corPrincipal, this.logo, this.logoTipo});

  factory Organizacao.deJson(Map<String, dynamic> json) {
    final logo = json['logo'] as String?;
    return Organizacao(
      id: json['id'] as String,
      nome: json['nome'] as String,
      corPrincipal: json['corPrincipal'] as String?,
      logo: logo == null ? null : base64Decode(logo),
      logoTipo: json['logoTipo'] as String?,
    );
  }

  final String id;
  final String nome;

  /// "#RRGGBB"; `null` usa a cor padrão da plataforma.
  final String? corPrincipal;
  final Uint8List? logo;

  /// "image/png" ou "image/jpeg".
  final String? logoTipo;
}

/// Alteração da identidade visual. Logo: [manterLogo] deixa o atual; senão,
/// [logo] é o novo (ou `null` para remover).
class DadosIdentidade {
  const DadosIdentidade({required this.corPrincipal, this.manterLogo = true, this.logo, this.logoTipo});

  final String? corPrincipal;
  final bool manterLogo;
  final Uint8List? logo;
  final String? logoTipo;

  Map<String, Object?> paraJson() => {
        'corPrincipal': corPrincipal,
        if (!manterLogo) ...{
          'logo': logo == null ? null : base64Encode(logo!),
          'logoTipo': logo == null ? null : logoTipo,
        },
      };
}

abstract interface class OrganizacaoRepositorio {
  Future<Organizacao> buscar();
  Future<Organizacao> salvarIdentidade(DadosIdentidade dados);
}
