import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/tema/contraste.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../domain/organizacao.dart';
import 'previa_carteirinha.dart';

/// RF17: logo e cor da carteirinha, com verificação de contraste e prévia.
/// O que for salvo vale para as carteirinhas de todos os membros.
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

  Future<void> _salvar() async {
    setState(() => _salvando = true);
    try {
      final org = await _repositorio.salvarIdentidade(DadosIdentidade(
        corPrincipal: Contraste.paraHex(_cor),
        manterLogo: !_logoAlterado,
        logo: _logo,
        logoTipo: _logoTipo,
      ));
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
    return Scaffold(
      appBar: AppBar(title: const Text('Identidade visual')),
      body: _erro != null
          ? AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar)
          : org == null
              ? const Center(child: CircularProgressIndicator())
              : _conteudo(org),
    );
  }

  Widget _conteudo(Organizacao org) {
    final texto = Theme.of(context).textTheme;
    final titulo = texto.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta);
    final contraste = Contraste.comBranco(_cor);
    final legivel = contraste >= Contraste.minimo;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Prévia da carteirinha', style: titulo),
        const SizedBox(height: 12),
        PreviaCarteirinha(cor: _cor, nomeOrganizacao: org.nome, logo: _logo),
        const SizedBox(height: 28),
        Text('Logo', style: titulo),
        const SizedBox(height: 4),
        Text(
          'PNG ou JPEG, de preferência quadrado e com fundo transparente.',
          style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: _salvando ? null : _escolherLogo,
              icon: const Icon(Icons.image_outlined),
              label: Text(_logo == null ? 'Escolher logo' : 'Trocar logo'),
            ),
            if (_logo != null)
              TextButton.icon(
                onPressed: _salvando ? null : _removerLogo,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remover'),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Cor principal', style: titulo),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final cor in TelaIdentidade.sugestoes)
              _AmostraCor(cor: cor, selecionada: cor.toARGB32() == _cor.toARGB32(), aoTocar: () => _escolherCor(cor)),
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
        _IndicadorContraste(contraste: contraste, legivel: legivel),
        const SizedBox(height: 28),
        FilledButton(
          key: const Key('botao-salvar-identidade'),
          onPressed: _salvando || !legivel ? null : _salvar,
          child: _salvando ? const CarregandoBotao() : const Text('Salvar e aplicar a todas as carteirinhas'),
        ),
      ],
    );
  }
}

class _AmostraCor extends StatelessWidget {
  const _AmostraCor({required this.cor, required this.selecionada, required this.aoTocar});

  final Color cor;
  final bool selecionada;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selecionada,
      label: 'Cor ${Contraste.paraHex(cor)}',
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
          child: selecionada ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
        ),
      ),
    );
  }
}

class _IndicadorContraste extends StatelessWidget {
  const _IndicadorContraste({required this.contraste, required this.legivel});

  final double contraste;
  final bool legivel;

  @override
  Widget build(BuildContext context) {
    final valor = contraste.toStringAsFixed(1).replaceAll('.', ',');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: legivel ? Cores.sucessoFundo : Cores.erroFundo,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(legivel ? Icons.check_circle_outline : Icons.error_outline,
              color: legivel ? Cores.sucesso : Cores.erro),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              legivel
                  ? 'Contraste $valor:1 com o texto branco. Boa leitura.'
                  : 'Contraste $valor:1. Cor clara demais: o texto branco da carteirinha '
                      'fica difícil de ler (mínimo 4,5:1).',
              key: const Key('texto-contraste'),
              style: TextStyle(color: legivel ? Cores.sucesso : Cores.erro, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
