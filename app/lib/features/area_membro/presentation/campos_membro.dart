import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../perfil/domain/perfil.dart';
import '../../perfil/presentation/avatar_perfil.dart';
import '../domain/carteirinha_membro.dart';

/// Peças compartilhadas pelo primeiro acesso e pela aba "Meu perfil" do membro:
/// foto, celular, endereço e as máscaras dos campos.

const tamanhoMaximoFotoMembro = 512 * 1024;

const ufs = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', //
  'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
];

/// Foto escolhida pelo membro, já dentro do limite de tamanho.
typedef FotoEscolhida = ({Uint8List bytes, String tipo});

/// Pergunta se é câmera ou galeria, abre o seletor e confere o tamanho.
/// Devolve `null` se o membro desistiu ou a foto passou do limite.
Future<FotoEscolhida?> escolherFotoMembro(BuildContext context) async {
  final origem = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tirar foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Escolher da galeria'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (origem == null) return null;
  final arquivo = await ImagePicker().pickImage(
    source: origem,
    maxWidth: 600,
    maxHeight: 600,
    imageQuality: 85,
    preferredCameraDevice: CameraDevice.front,
  );
  if (arquivo == null) return null;
  final bytes = await arquivo.readAsBytes();
  if (bytes.length > tamanhoMaximoFotoMembro) {
    if (context.mounted) avisar(context, 'A foto pode ter no máximo 512 KB.');
    return null;
  }
  return (bytes: bytes, tipo: arquivo.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg');
}

/// Foto redonda com o selo de câmera; tocar troca a foto.
class FotoMembroEditavel extends StatelessWidget {
  const FotoMembroEditavel({super.key, required this.nome, required this.foto, this.aoTocar, this.erro = false});

  final String nome;
  final Uint8List? foto;
  final VoidCallback? aoTocar;

  /// Contorno vermelho quando a foto é obrigatória e falta.
  final bool erro;

  @override
  Widget build(BuildContext context) {
    final iniciais = Perfil(id: '', nome: nome.trim().isEmpty ? '?' : nome, email: '', organizacaoNome: '').iniciais;
    return Semantics(
      button: true,
      label: foto == null ? 'Adicionar foto' : 'Trocar foto',
      excludeSemantics: true,
      child: InkWell(
        onTap: aoTocar,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: erro ? Cores.erro : Cores.primaria.withValues(alpha: 0.5), width: 2),
              ),
              child: AvatarPerfil(iniciais: iniciais, foto: foto, tamanho: 112),
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Cores.primaria,
                  shape: BoxShape.circle,
                  border: Border.all(color: Cores.fundo, width: 3),
                ),
                child: const Icon(Icons.photo_camera, size: 18, color: Cores.noPrimaria),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Título de seção em caixa alta.
class TituloSecaoMembro extends StatelessWidget {
  const TituloSecaoMembro(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 28, 4, 10),
      child: Text(
        texto.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Cores.textoSecundario,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Campo de celular com DDD, com máscara.
class CampoCelular extends StatelessWidget {
  const CampoCelular({super.key, required this.controle, this.habilitado = true, this.chave});

  final TextEditingController controle;
  final bool habilitado;
  final Key? chave;

  static String? validar(String? v) {
    final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '').length;
    return digitos == 10 || digitos == 11 ? null : 'Informe um celular válido, com DDD.';
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: chave,
      controller: controle,
      enabled: habilitado,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [Mascara.celular],
      decoration: const InputDecoration(
        labelText: 'Celular com DDD',
        hintText: '(54) 99999-0000',
        prefixIcon: Icon(Icons.smartphone_outlined),
      ),
      validator: validar,
    );
  }
}

/// Os campos do endereço, com seus controles. Quem usa chama [dispose].
class ControlesEndereco {
  ControlesEndereco([EnderecoMembro? e])
    : cep = TextEditingController(text: e?.cep ?? ''),
      logradouro = TextEditingController(text: e?.logradouro ?? ''),
      numero = TextEditingController(text: e?.numero ?? ''),
      complemento = TextEditingController(text: e?.complemento ?? ''),
      bairro = TextEditingController(text: e?.bairro ?? ''),
      cidade = TextEditingController(text: e?.cidade ?? ''),
      uf = e?.uf;

  final TextEditingController cep;
  final TextEditingController logradouro;
  final TextEditingController numero;
  final TextEditingController complemento;
  final TextEditingController bairro;
  final TextEditingController cidade;
  String? uf;

  List<TextEditingController> get campos => [cep, logradouro, numero, complemento, bairro, cidade];

  /// O endereço preenchido; chame só depois de o formulário validar.
  EnderecoMembro paraEndereco() => EnderecoMembro(
    cep: cep.text.trim(),
    logradouro: logradouro.text.trim(),
    numero: numero.text.trim(),
    complemento: complemento.text.trim().isEmpty ? null : complemento.text.trim(),
    bairro: bairro.text.trim(),
    cidade: cidade.text.trim(),
    uf: uf!,
  );

  /// Algo diferente de [salvo]?
  bool diferenteDe(EnderecoMembro? salvo) =>
      cep.text.trim() != (salvo?.cep ?? '') ||
      logradouro.text.trim() != (salvo?.logradouro ?? '') ||
      numero.text.trim() != (salvo?.numero ?? '') ||
      complemento.text.trim() != (salvo?.complemento ?? '') ||
      bairro.text.trim() != (salvo?.bairro ?? '') ||
      cidade.text.trim() != (salvo?.cidade ?? '') ||
      uf != salvo?.uf;

  void dispose() {
    for (final c in campos) {
      c.dispose();
    }
  }
}

/// CEP, rua, número, complemento, bairro, cidade e UF.
class CamposEndereco extends StatelessWidget {
  const CamposEndereco({super.key, required this.controles, required this.aoMudarUf, this.habilitado = true});

  final ControlesEndereco controles;
  final ValueChanged<String?> aoMudarUf;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final c = controles;
    return Column(
      children: [
        TextFormField(
          key: const Key('campo-cep-cadastro'),
          controller: c.cep,
          enabled: habilitado,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [Mascara.cep],
          decoration: const InputDecoration(
            labelText: 'CEP',
            hintText: '99999-999',
            prefixIcon: Icon(Icons.markunread_mailbox_outlined),
          ),
          validator: (v) => RegExp(r'^\d{5}-\d{3}$').hasMatch((v ?? '').trim()) ? null : 'Informe um CEP válido.',
        ),
        const SizedBox(height: 14),
        _texto(
          const Key('campo-rua-cadastro'),
          c.logradouro,
          'Rua ou avenida',
          150,
          'Informe a rua.',
          icone: Icons.signpost_outlined,
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: _texto(
                const Key('campo-numero-cadastro'),
                c.numero,
                'Número',
                10,
                'Informe o número.',
                teclado: TextInputType.streetAddress,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _texto(const Key('campo-complemento-cadastro'), c.complemento, 'Complemento (opcional)', 80, null),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _texto(const Key('campo-bairro-cadastro'), c.bairro, 'Bairro', 80, 'Informe o bairro.'),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _texto(const Key('campo-cidade-cadastro'), c.cidade, 'Cidade', 80, 'Informe a cidade.')),
            const SizedBox(width: 12),
            SizedBox(
              width: 104,
              child: DropdownButtonFormField<String>(
                key: const Key('campo-uf-cadastro'),
                initialValue: c.uf,
                isExpanded: true,
                menuMaxHeight: 320,
                decoration: const InputDecoration(labelText: 'UF'),
                items: [for (final uf in ufs) DropdownMenuItem(value: uf, child: Text(uf))],
                onChanged: habilitado ? aoMudarUf : null,
                validator: (v) => v == null ? 'Escolha' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _texto(
    Key chave,
    TextEditingController controle,
    String rotulo,
    int maximo,
    String? erroVazio, {
    IconData? icone,
    TextInputType? teclado,
  }) {
    return TextFormField(
      key: chave,
      controller: controle,
      enabled: habilitado,
      keyboardType: teclado,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      maxLength: maximo,
      decoration: InputDecoration(labelText: rotulo, prefixIcon: icone == null ? null : Icon(icone), counterText: ''),
      validator: erroVazio == null ? null : (v) => (v ?? '').trim().isEmpty ? erroVazio : null,
    );
  }
}

/// Máscaras simples: aceitam só dígitos e encaixam a pontuação enquanto o membro digita.
class Mascara extends TextInputFormatter {
  const Mascara(this.formatar, this.maximoDigitos);

  final String Function(String digitos) formatar;
  final int maximoDigitos;

  /// (54) 99999-0000 ou (54) 3333-0000
  static final celular = Mascara((d) {
    if (d.isEmpty) return '';
    if (d.length <= 2) return '($d';
    final meio = d.length == 11 ? 7 : 6;
    if (d.length <= meio) return '(${d.substring(0, 2)}) ${d.substring(2)}';
    return '(${d.substring(0, 2)}) ${d.substring(2, meio)}-${d.substring(meio)}';
  }, 11);

  static final cep = Mascara((d) => d.length <= 5 ? d : '${d.substring(0, 5)}-${d.substring(5)}', 8);

  static final data = Mascara((d) {
    if (d.length <= 2) return d;
    if (d.length <= 4) return '${d.substring(0, 2)}/${d.substring(2)}';
    return '${d.substring(0, 2)}/${d.substring(2, 4)}/${d.substring(4)}';
  }, 8);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue antes, TextEditingValue depois) {
    var digitos = depois.text.replaceAll(RegExp(r'\D'), '');
    if (digitos.length > maximoDigitos) digitos = digitos.substring(0, maximoDigitos);
    final texto = formatar(digitos);
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}
