import 'dart:convert';
import 'dart:typed_data';

/// Como o fundo da carteirinha é pintado.
enum EstiloFundo {
  degrade('Degradê'),
  solido('Cor sólida'),
  padrao('Com padrão');

  const EstiloFundo(this.rotulo);

  final String rotulo;

  String get paraApi => switch (this) {
    degrade => 'DEGRADE',
    solido => 'SOLIDO',
    padrao => 'PADRAO',
  };

  static EstiloFundo daApi(String? valor) => switch (valor) {
    'SOLIDO' => solido,
    'PADRAO' => padrao,
    _ => degrade,
  };
}

/// Disposição das informações na carteirinha.
enum ModeloCarteirinha {
  classico('Clássico', 'Foto redonda, QR embaixo'),
  moderno('Moderno', 'Foto ao lado, QR bem grande'),
  minimalista('Minimalista', 'Centralizado e enxuto');

  const ModeloCarteirinha(this.rotulo, this.descricao);

  final String rotulo;
  final String descricao;

  String get paraApi => name.toUpperCase();

  static ModeloCarteirinha daApi(String? valor) => switch (valor) {
    'MODERNO' => moderno,
    'MINIMALISTA' => minimalista,
    _ => classico,
  };
}

/// Organização e sua identidade visual, aplicada a todas as carteirinhas (RF17).
class Organizacao {
  const Organizacao({
    required this.id,
    required this.nome,
    this.corPrincipal,
    this.corSecundaria,
    this.estiloFundo = EstiloFundo.degrade,
    this.modelo = ModeloCarteirinha.classico,
    this.logo,
    this.logoTipo,
  });

  factory Organizacao.deJson(Map<String, dynamic> json) {
    final logo = json['logo'] as String?;
    return Organizacao(
      id: json['id'] as String,
      nome: json['nome'] as String,
      corPrincipal: json['corPrincipal'] as String?,
      corSecundaria: json['corSecundaria'] as String?,
      estiloFundo: EstiloFundo.daApi(json['estiloFundo'] as String?),
      modelo: ModeloCarteirinha.daApi(json['modeloCarteirinha'] as String?),
      logo: logo == null ? null : base64Decode(logo),
      logoTipo: json['logoTipo'] as String?,
    );
  }

  final String id;
  final String nome;

  /// "#RRGGBB"; `null` usa a cor padrão da plataforma.
  final String? corPrincipal;

  /// Segunda cor do degradê; `null` usa uma versão escura da principal.
  final String? corSecundaria;
  final EstiloFundo estiloFundo;
  final ModeloCarteirinha modelo;
  final Uint8List? logo;

  /// "image/png" ou "image/jpeg".
  final String? logoTipo;
}

/// Alteração da identidade visual. Logo: [manterLogo] deixa o atual; senão,
/// [logo] é o novo (ou `null` para remover).
class DadosIdentidade {
  const DadosIdentidade({
    required this.corPrincipal,
    this.corSecundaria,
    this.estiloFundo = EstiloFundo.degrade,
    this.modelo = ModeloCarteirinha.classico,
    this.manterLogo = true,
    this.logo,
    this.logoTipo,
  });

  final String? corPrincipal;
  final String? corSecundaria;
  final EstiloFundo estiloFundo;
  final ModeloCarteirinha modelo;
  final bool manterLogo;
  final Uint8List? logo;
  final String? logoTipo;

  Map<String, Object?> paraJson() => {
    'corPrincipal': corPrincipal,
    'corSecundaria': corSecundaria,
    'estiloFundo': estiloFundo.paraApi,
    'modeloCarteirinha': modelo.paraApi,
    if (!manterLogo) ...{'logo': logo == null ? null : base64Encode(logo!), 'logoTipo': logo == null ? null : logoTipo},
  };
}

abstract interface class OrganizacaoRepositorio {
  Future<Organizacao> buscar();
  Future<Organizacao> salvarIdentidade(DadosIdentidade dados);
}
