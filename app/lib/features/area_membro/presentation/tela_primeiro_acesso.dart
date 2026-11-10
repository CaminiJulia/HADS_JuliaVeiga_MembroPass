import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../perfil/domain/perfil.dart';
import '../../perfil/presentation/avatar_perfil.dart';
import '../domain/carteirinha_membro.dart';

/// Primeiro acesso do membro: antes de ver a carteirinha, ele confere o nome,
/// preenche celular, nascimento e endereço, escolhe a foto e declara que as
/// informações são verdadeiras.
class TelaPrimeiroAcesso extends StatefulWidget {
  const TelaPrimeiroAcesso({
    super.key,
    required this.cadastro,
    required this.aoConcluir,
    required this.aoSair,
    this.aoAdiar,
  });

  final CadastroMembro cadastro;
  final ValueChanged<CadastroMembro> aoConcluir;
  final VoidCallback aoSair;

  /// Pula o formulário por agora; `null` quando o cadastro é obrigatório.
  final VoidCallback? aoAdiar;

  /// Por enquanto o cadastro é opcional (facilita os testes): aparece o botão
  /// "Preencher depois". Com `true`, a carteirinha só abre após o cadastro.
  static const obrigatorio = false;

  static const tamanhoMaximoFoto = 512 * 1024;

  static const ufs = [
    'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS', 'MG', 'PA', //
    'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC', 'SP', 'SE', 'TO',
  ];

  @override
  State<TelaPrimeiroAcesso> createState() => _TelaPrimeiroAcessoState();
}

class _TelaPrimeiroAcessoState extends State<TelaPrimeiroAcesso> {
  final _formulario = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.cadastro.nome);
  late final _telefone = TextEditingController(text: widget.cadastro.telefone ?? '');
  late final _nascimento = TextEditingController(
    text: widget.cadastro.dataNascimento == null ? '' : Datas.formatar(widget.cadastro.dataNascimento!),
  );
  late final _cep = TextEditingController(text: widget.cadastro.endereco?.cep ?? '');
  late final _logradouro = TextEditingController(text: widget.cadastro.endereco?.logradouro ?? '');
  late final _numero = TextEditingController(text: widget.cadastro.endereco?.numero ?? '');
  late final _complemento = TextEditingController(text: widget.cadastro.endereco?.complemento ?? '');
  late final _bairro = TextEditingController(text: widget.cadastro.endereco?.bairro ?? '');
  late final _cidade = TextEditingController(text: widget.cadastro.endereco?.cidade ?? '');
  late String? _uf = widget.cadastro.endereco?.uf;

  late Uint8List? _foto = widget.cadastro.foto;
  String? _fotoTipo;
  bool _fotoNova = false;

  bool _declarou = false;
  bool _tentouEnviar = false;
  bool _enviando = false;

  List<TextEditingController> get _campos => [
    _nome,
    _telefone,
    _nascimento,
    _cep,
    _logradouro,
    _numero,
    _complemento,
    _bairro,
    _cidade,
  ];

  @override
  void dispose() {
    for (final c in _campos) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _escolherFoto() async {
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
    if (origem == null) return;
    final arquivo = await ImagePicker().pickImage(
      source: origem,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    if (bytes.length > TelaPrimeiroAcesso.tamanhoMaximoFoto) {
      avisar(context, 'A foto pode ter no máximo 512 KB.');
      return;
    }
    setState(() {
      _foto = bytes;
      _fotoTipo = arquivo.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      _fotoNova = true;
    });
  }

  /// "25/12/1990" → DateTime, ou `null` se não for uma data de nascimento possível.
  static DateTime? _lerNascimento(String texto) {
    final partes = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(texto.trim());
    if (partes == null) return null;
    final dia = int.parse(partes[1]!);
    final mes = int.parse(partes[2]!);
    final ano = int.parse(partes[3]!);
    final data = DateTime(ano, mes, dia);
    // DateTime corrige 31/02 para março; aqui isso é data inválida.
    if (data.day != dia || data.month != mes) return null;
    if (ano < 1900 || !data.isBefore(Datas.hoje())) return null;
    return data;
  }

  Future<void> _concluir() async {
    setState(() => _tentouEnviar = true);
    final valido = _formulario.currentState!.validate();
    if (!valido || _foto == null) {
      avisar(
        context,
        _foto == null && valido ? 'Escolha uma foto para a carteirinha.' : 'Confira os campos destacados.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    try {
      String? opcional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
      final cadastro = await context.read<AreaMembroRepositorio>().completarCadastro(
        DadosCadastroMembro(
          nome: _nome.text.trim(),
          telefone: _telefone.text.trim(),
          dataNascimento: _lerNascimento(_nascimento.text)!,
          endereco: EnderecoMembro(
            cep: _cep.text.trim(),
            logradouro: _logradouro.text.trim(),
            numero: _numero.text.trim(),
            complemento: opcional(_complemento),
            bairro: _bairro.text.trim(),
            cidade: _cidade.text.trim(),
            uf: _uf!,
          ),
          foto: _fotoNova ? _foto : null,
          fotoTipo: _fotoNova ? _fotoTipo : null,
        ),
      );
      if (!mounted) return;
      avisar(context, 'Cadastro concluído. Esta é a sua carteirinha!');
      widget.aoConcluir(cadastro);
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete seu cadastro'),
        automaticallyImplyLeading: false,
        actions: [IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: widget.aoSair)],
      ),
      // Botão fixo no rodapé: continua visível com o teclado aberto.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                key: const Key('botao-concluir-cadastro'),
                onPressed: _enviando || !_declarou ? null : _concluir,
                child: _enviando ? const CarregandoBotao() : const Text('Concluir cadastro'),
              ),
              if (widget.aoAdiar != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  key: const Key('botao-preencher-depois'),
                  onPressed: _enviando ? null : widget.aoAdiar,
                  child: const Text('Preencher depois'),
                ),
              ],
            ],
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formulario,
            autovalidateMode: _tentouEnviar ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: _conteudo(context)),
          ),
        ),
      ),
    );
  }

  List<Widget> _conteudo(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final primeiroNome = widget.cadastro.nome.trim().split(RegExp(r'\s+')).first;
    final iniciais = Perfil(
      id: '',
      nome: _nome.text.trim().isEmpty ? '?' : _nome.text,
      email: '',
      organizacaoNome: '',
    ).iniciais;
    final semFoto = _tentouEnviar && _foto == null;

    return [
      Text('Olá, $primeiroNome!', style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(
        'Antes de usar a carteirinha, confira e complete seus dados. É rápido e só precisa ser feito uma vez.',
        style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario, height: 1.4),
      ),
      const SizedBox(height: 16),
      const _AvisoVeracidade(),

      const _TituloSecao('Foto da carteirinha'),
      Center(
        child: Semantics(
          button: true,
          label: _foto == null ? 'Adicionar foto' : 'Trocar foto',
          excludeSemantics: true,
          child: InkWell(
            key: const Key('foto-primeiro-acesso'),
            onTap: _enviando ? null : _escolherFoto,
            customBorder: const CircleBorder(),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: semFoto ? Cores.erro : Cores.primaria.withValues(alpha: 0.5), width: 2),
                  ),
                  child: AvatarPerfil(iniciais: iniciais, foto: _foto, tamanho: 112),
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
        ),
      ),
      const SizedBox(height: 10),
      Text(
        semFoto
            ? 'Escolha uma foto para a carteirinha.'
            : 'Foto recente, de frente, com o rosto visível (sem boné ou óculos escuros).',
        textAlign: TextAlign.center,
        style: texto.bodySmall?.copyWith(color: semFoto ? Cores.erro : Cores.textoSecundario),
      ),

      const _TituloSecao('Dados pessoais'),
      TextFormField(
        key: const Key('campo-nome-cadastro'),
        controller: _nome,
        enabled: !_enviando,
        onChanged: (_) => setState(() {}),
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        maxLength: 150,
        decoration: const InputDecoration(
          labelText: 'Nome completo',
          prefixIcon: Icon(Icons.person_outline),
          helperText: 'Confira se está igual ao seu documento.',
          counterText: '',
        ),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Informe seu nome.' : null,
      ),
      const SizedBox(height: 14),
      TextFormField(
        initialValue: widget.cadastro.email,
        enabled: false,
        decoration: const InputDecoration(
          labelText: 'E-mail de acesso',
          prefixIcon: Icon(Icons.mail_outline),
          suffixIcon: Icon(Icons.lock_outline, size: 18),
        ),
      ),
      const SizedBox(height: 14),
      TextFormField(
        key: const Key('campo-celular-cadastro'),
        controller: _telefone,
        enabled: !_enviando,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        inputFormatters: [_Mascara.celular],
        decoration: const InputDecoration(
          labelText: 'Celular com DDD',
          hintText: '(54) 99999-0000',
          prefixIcon: Icon(Icons.smartphone_outlined),
        ),
        validator: (v) {
          final digitos = (v ?? '').replaceAll(RegExp(r'\D'), '').length;
          return digitos == 10 || digitos == 11 ? null : 'Informe um celular válido, com DDD.';
        },
      ),
      const SizedBox(height: 14),
      TextFormField(
        key: const Key('campo-nascimento-cadastro'),
        controller: _nascimento,
        enabled: !_enviando,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [_Mascara.data],
        decoration: const InputDecoration(
          labelText: 'Data de nascimento',
          hintText: 'DD/MM/AAAA',
          prefixIcon: Icon(Icons.cake_outlined),
        ),
        validator: (v) => _lerNascimento(v ?? '') == null ? 'Informe uma data válida (DD/MM/AAAA).' : null,
      ),

      const _TituloSecao('Endereço'),
      TextFormField(
        key: const Key('campo-cep-cadastro'),
        controller: _cep,
        enabled: !_enviando,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [_Mascara.cep],
        decoration: const InputDecoration(
          labelText: 'CEP',
          hintText: '99999-999',
          prefixIcon: Icon(Icons.markunread_mailbox_outlined),
        ),
        validator: (v) => RegExp(r'^\d{5}-\d{3}$').hasMatch((v ?? '').trim()) ? null : 'Informe um CEP válido.',
      ),
      const SizedBox(height: 14),
      _campoTexto(
        const Key('campo-rua-cadastro'),
        _logradouro,
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
            child: _campoTexto(
              const Key('campo-numero-cadastro'),
              _numero,
              'Número',
              10,
              'Informe o número.',
              teclado: TextInputType.streetAddress,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _campoTexto(
              const Key('campo-complemento-cadastro'),
              _complemento,
              'Complemento (opcional)',
              80,
              null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _campoTexto(const Key('campo-bairro-cadastro'), _bairro, 'Bairro', 80, 'Informe o bairro.'),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _campoTexto(const Key('campo-cidade-cadastro'), _cidade, 'Cidade', 80, 'Informe a cidade.')),
          const SizedBox(width: 12),
          SizedBox(
            width: 104,
            child: DropdownButtonFormField<String>(
              key: const Key('campo-uf-cadastro'),
              initialValue: _uf,
              isExpanded: true,
              menuMaxHeight: 320,
              decoration: const InputDecoration(labelText: 'UF'),
              items: [for (final uf in TelaPrimeiroAcesso.ufs) DropdownMenuItem(value: uf, child: Text(uf))],
              onChanged: _enviando ? null : (uf) => setState(() => _uf = uf),
              validator: (v) => v == null ? 'Escolha' : null,
            ),
          ),
        ],
      ),

      const SizedBox(height: 24),
      Container(
        decoration: BoxDecoration(
          color: Cores.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _declarou ? Cores.primaria.withValues(alpha: 0.6) : Cores.borda),
        ),
        child: CheckboxListTile(
          key: const Key('declaracao-veracidade'),
          value: _declarou,
          onChanged: _enviando ? null : (v) => setState(() => _declarou = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Declaro que as informações acima são verdadeiras e estou ciente de que dados falsos podem levar à minha expulsão.',
            style: texto.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ),
    ];
  }

  Widget _campoTexto(
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
      enabled: !_enviando,
      keyboardType: teclado,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      maxLength: maximo,
      decoration: InputDecoration(labelText: rotulo, prefixIcon: icone == null ? null : Icon(icone), counterText: ''),
      validator: erroVazio == null ? null : (v) => (v ?? '').trim().isEmpty ? erroVazio : null,
    );
  }
}

/// Aviso em destaque: os dados precisam ser verdadeiros, sob risco de expulsão.
class _AvisoVeracidade extends StatelessWidget {
  const _AvisoVeracidade();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      key: const Key('aviso-veracidade'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.alertaFundo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.alerta.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Cores.alerta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'As informações devem ser verdadeiras',
                  style: texto.titleSmall?.copyWith(color: Cores.alerta, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'A associação confere estes dados. Se alguma informação for falsa, '
                  'você corre o risco de ser expulso(a) e perder a carteirinha.',
                  style: texto.bodySmall?.copyWith(color: Cores.tinta, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de seção em caixa alta.
class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

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

/// Máscaras simples: aceitam só dígitos e encaixam a pontuação enquanto o membro digita.
class _Mascara extends TextInputFormatter {
  const _Mascara(this.formatar, this.maximoDigitos);

  final String Function(String digitos) formatar;
  final int maximoDigitos;

  /// (54) 99999-0000 ou (54) 3333-0000
  static final celular = _Mascara((d) {
    if (d.isEmpty) return '';
    if (d.length <= 2) return '($d';
    final meio = d.length == 11 ? 7 : 6;
    if (d.length <= meio) return '(${d.substring(0, 2)}) ${d.substring(2)}';
    return '(${d.substring(0, 2)}) ${d.substring(2, meio)}-${d.substring(meio)}';
  }, 11);

  static final cep = _Mascara((d) => d.length <= 5 ? d : '${d.substring(0, 5)}-${d.substring(5)}', 8);

  static final data = _Mascara((d) {
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
