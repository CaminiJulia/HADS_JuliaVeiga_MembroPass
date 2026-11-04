import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/tema/contraste.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../domain/organizacao.dart';
import 'previa_carteirinha.dart';

/// RF17: modelo, fundo, cores e logo da carteirinha, com prévia e verificação
/// de contraste. O que for salvo vale para as carteirinhas de todos os membros.
class TelaIdentidade extends StatefulWidget {
  const TelaIdentidade({super.key});

  /// Sugestões de cor, todas com contraste suficiente para texto branco.
  static const sugestoes = [
    Color(0xFF2B2FB8),
    Color(0xFF14163A),
    Color(0xFF0B6E4F),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFAD1457),
    Color(0xFFC62828),
    Color(0xFFB34700),
    Color(0xFF37474F),
  ];

  static const tamanhoMaximoLogo = 512 * 1024;

  @override
  State<TelaIdentidade> createState() => _TelaIdentidadeState();
}

class _TelaIdentidadeState extends State<TelaIdentidade> {
  final _hex = TextEditingController();
  Organizacao? _organizacao;
  String? _erro;
  bool _salvando = false;

  Color _cor = Cores.marca;
  Color? _corSecundaria;
  var _estilo = EstiloFundo.degrade;
  var _modelo = ModeloCarteirinha.classico;
  Uint8List? _logo;
  String? _logoTipo;
  bool _logoAlterado = false;

  OrganizacaoRepositorio get _repositorio => context.read<OrganizacaoRepositorio>();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final org = await _repositorio.buscar();
      if (!mounted) return;
      setState(() {
        _organizacao = org;
        _cor = Contraste.lerHex(org.corPrincipal ?? '') ?? Cores.marca;
        _corSecundaria = Contraste.lerHex(org.corSecundaria ?? '');
        _estilo = org.estiloFundo;
        _modelo = org.modelo;
        _hex.text = Contraste.paraHex(_cor);
        _logo = org.logo;
        _logoTipo = org.logoTipo;
        _logoAlterado = false;
      });
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  void _escolherCor(Color cor) => setState(() {
    _cor = cor;
    _hex.text = Contraste.paraHex(cor);
  });

  Future<void> _escolherLogo() async {
    final arquivo = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    if (bytes.length > TelaIdentidade.tamanhoMaximoLogo) {
      avisar(context, 'O logo pode ter no máximo 512 KB.');
      return;
    }
    setState(() {
      _logo = bytes;
      _logoTipo = arquivo.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      _logoAlterado = true;
    });
  }

  void _removerLogo() => setState(() {
    _logo = null;
    _logoTipo = null;
    _logoAlterado = true;
  });

  /// A segunda cor só conta no degradê.
  Color? get _segundaEmUso => _estilo == EstiloFundo.degrade ? _corSecundaria : null;

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final segunda = _segundaEmUso;
      final org = await _repositorio.salvarIdentidade(
        DadosIdentidade(
          corPrincipal: Contraste.paraHex(_cor),
          corSecundaria: segunda == null ? null : Contraste.paraHex(segunda),
          estiloFundo: _estilo,
          modelo: _modelo,
          manterLogo: !_logoAlterado,
          logo: _logo,
          logoTipo: _logoTipo,
        ),
      );
      if (!mounted) return;
      setState(() {
        _organizacao = org;
        _logoAlterado = false;
      });
      avisar(context, 'Identidade visual salva. Todas as carteirinhas já usam a nova marca.');
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final org = _organizacao;
    final segunda = _segundaEmUso;
    final legivel = Contraste.legivelComBranco(_cor) && (segunda == null || Contraste.legivelComBranco(segunda));

    return Scaffold(
      appBar: AppBar(title: const Text('Identidade visual')),
      bottomNavigationBar: org == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: FilledButton(
                  key: const Key('botao-salvar-identidade'),
                  onPressed: _salvando || !legivel ? null : _salvar,
                  child: _salvando ? const CarregandoBotao() : const Text('Salvar e aplicar a todas as carteirinhas'),
                ),
              ),
            ),
      body: _erro != null
          ? AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar)
          : org == null
          ? const Center(child: CircularProgressIndicator())
          : _conteudo(org),
    );
  }

  Widget _conteudo(Organizacao org) {
    final texto = Theme.of(context).textTheme;
    final segunda = _segundaEmUso;

    Widget previa(ModeloCarteirinha modelo, {bool esboco = false}) => PreviaCarteirinha(
      cor: _cor,
      corSecundaria: segunda,
      estilo: _estilo,
      modelo: modelo,
      nomeOrganizacao: org.nome,
      logo: _logo,
      esboco: esboco,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const _TituloSecao('Prévia da carteirinha', topo: 0),
            previa(_modelo),
            const SizedBox(height: 10),
            Text(
              'É assim que os membros veem a carteirinha no app.',
              textAlign: TextAlign.center,
              style: texto.bodySmall,
            ),
            const _TituloSecao('Modelo'),
            Row(
              children: [
                for (final (i, m) in ModeloCarteirinha.values.indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _OpcaoModelo(
                      modelo: m,
                      selecionado: m == _modelo,
                      miniatura: previa(m, esboco: true),
                      aoTocar: () => setState(() => _modelo = m),
                    ),
                  ),
                ],
              ],
            ),
            const _TituloSecao('Fundo'),
            SegmentedButton<EstiloFundo>(
              segments: const [
                ButtonSegment(value: EstiloFundo.degrade, icon: Icon(Icons.gradient), label: Text('Degradê')),
                ButtonSegment(value: EstiloFundo.solido, icon: Icon(Icons.square_rounded), label: Text('Sólida')),
                ButtonSegment(value: EstiloFundo.padrao, icon: Icon(Icons.grid_view_rounded), label: Text('Padrão')),
              ],
              selected: {_estilo},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _estilo = s.first),
            ),
            if (_estilo == EstiloFundo.degrade) ...[
              const SizedBox(height: 16),
              Text('Segunda cor do degradê', style: texto.titleSmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _AmostraCor(
                    rotulo: 'Segunda cor automática',
                    cor: Color.lerp(_cor, Colors.black, 0.35)!,
                    automatica: true,
                    selecionada: _corSecundaria == null,
                    aoTocar: () => setState(() => _corSecundaria = null),
                  ),
                  for (final cor in TelaIdentidade.sugestoes)
                    _AmostraCor(
                      rotulo: 'Segunda cor ${Contraste.paraHex(cor)}',
                      cor: cor,
                      selecionada: cor.toARGB32() == _corSecundaria?.toARGB32(),
                      aoTocar: () => setState(() => _corSecundaria = cor),
                    ),
                ],
              ),
            ],
            const _TituloSecao('Cor principal'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final cor in TelaIdentidade.sugestoes)
                  _AmostraCor(
                    rotulo: 'Cor ${Contraste.paraHex(cor)}',
                    cor: cor,
                    selecionada: cor.toARGB32() == _cor.toARGB32(),
                    aoTocar: () => _escolherCor(cor),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('campo-cor-hex'),
              controller: _hex,
              enabled: !_salvando,
              maxLength: 7,
              decoration: const InputDecoration(
                labelText: 'Ou digite a cor (hexadecimal)',
                hintText: '#2B2FB8',
                prefixIcon: Icon(Icons.tag),
                counterText: '',
              ),
              onChanged: (v) {
                final cor = Contraste.lerHex(v);
                if (cor != null) setState(() => _cor = cor);
              },
            ),
            const SizedBox(height: 12),
            _IndicadorContraste(principal: _cor, segunda: segunda),
            const _TituloSecao('Logo'),
            CartaoItem(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: _logo == null
                          ? Icon(Icons.shield_outlined, color: _cor)
                          : Image.memory(_logo!, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Logo da organização', style: texto.titleSmall),
                          Text('PNG ou JPEG, quadrado e com fundo transparente.', style: texto.bodySmall),
                        ],
                      ),
                    ),
                    if (_logo != null)
                      IconButton(
                        tooltip: 'Remover logo',
                        onPressed: _salvando ? null : _removerLogo,
                        color: Cores.erro,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    OutlinedButton(
                      onPressed: _salvando ? null : _escolherLogo,
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                      child: Text(_logo == null ? 'Escolher' : 'Trocar'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Miniatura de um modelo, com nome e descrição.
class _OpcaoModelo extends StatelessWidget {
  const _OpcaoModelo({required this.modelo, required this.selecionado, required this.miniatura, required this.aoTocar});

  final ModeloCarteirinha modelo;
  final bool selecionado;
  final Widget miniatura;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selecionado,
      label: 'Modelo ${modelo.rotulo}',
      excludeSemantics: true,
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: selecionado ? Cores.primaria.withValues(alpha: 0.12) : Cores.superficie,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selecionado ? Cores.primaria : Cores.borda, width: selecionado ? 2 : 1),
          ),
          child: Column(
            children: [
              miniatura,
              const SizedBox(height: 8),
              Text(modelo.rotulo, style: texto.labelLarge?.copyWith(color: selecionado ? Cores.primaria : Cores.tinta)),
              Text(
                modelo.descricao,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: texto.labelSmall?.copyWith(color: Cores.textoSecundario),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmostraCor extends StatelessWidget {
  const _AmostraCor({
    required this.rotulo,
    required this.cor,
    required this.selecionada,
    required this.aoTocar,
    this.automatica = false,
  });

  final String rotulo;
  final Color cor;
  final bool selecionada;
  final VoidCallback aoTocar;

  /// A amostra "automática" mostra um ícone em vez de uma cor fixa.
  final bool automatica;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionada,
      label: rotulo,
      excludeSemantics: true,
      child: InkWell(
        onTap: aoTocar,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: cor,
            shape: BoxShape.circle,
            // Borda sempre visível: cores escuras não somem no fundo escuro.
            border: Border.all(color: selecionada ? Cores.tinta : Cores.borda, width: selecionada ? 3 : 1),
          ),
          child: selecionada
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : automatica
              ? const Icon(Icons.auto_awesome, color: Colors.white70, size: 16)
              : null,
        ),
      ),
    );
  }
}

/// Contraste do texto branco com a cor principal (e com a segunda, no degradê).
class _IndicadorContraste extends StatelessWidget {
  const _IndicadorContraste({required this.principal, required this.segunda});

  final Color principal;
  final Color? segunda;

  @override
  Widget build(BuildContext context) {
    String valor(Color c) => Contraste.comBranco(c).toStringAsFixed(1).replaceAll('.', ',');
    final principalOk = Contraste.legivelComBranco(principal);
    final segundaOk = segunda == null || Contraste.legivelComBranco(segunda!);
    final legivel = principalOk && segundaOk;
    final mensagem = !principalOk
        ? 'Contraste ${valor(principal)}:1. Cor clara demais: o texto branco da carteirinha '
              'fica difícil de ler (mínimo 4,5:1).'
        : !segundaOk
        ? 'Contraste ${valor(segunda!)}:1. Segunda cor clara demais: o texto branco fica '
              'difícil de ler (mínimo 4,5:1).'
        : 'Contraste ${valor(principal)}:1 com o texto branco. Boa leitura.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: legivel ? Cores.sucessoFundo : Cores.erroFundo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(legivel ? Icons.check_circle_outline : Icons.error_outline, color: legivel ? Cores.sucesso : Cores.erro),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              key: const Key('texto-contraste'),
              style: TextStyle(color: legivel ? Cores.sucesso : Cores.erro, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de seção em caixa alta.
class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto, {this.topo = 28});

  final String texto;
  final double topo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, topo, 4, 10),
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
