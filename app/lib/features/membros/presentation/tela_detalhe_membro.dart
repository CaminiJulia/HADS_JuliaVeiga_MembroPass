import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../domain/membro.dart';
import '../domain/membros_repositorio.dart';
import 'tela_formulario_membro.dart';
import 'widgets/visual_membro.dart';

/// Dados do membro, situação da carteirinha e ações do administrador.
class TelaDetalheMembro extends StatefulWidget {
  const TelaDetalheMembro({super.key, required this.membroId});

  final String membroId;

  @override
  State<TelaDetalheMembro> createState() => _TelaDetalheMembroState();
}

class _TelaDetalheMembroState extends State<TelaDetalheMembro> {
  Membro? _membro;
  String? _erro;
  bool _ocupado = false;

  MembrosRepositorio get _repositorio => context.read<MembrosRepositorio>();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final membro = await _repositorio.buscar(widget.membroId);
      if (mounted) setState(() => _membro = membro);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  /// Executa uma ação que devolve o membro atualizado, com aviso de sucesso.
  Future<void> _executar(Future<Membro> Function() acao, String sucesso) async {
    setState(() => _ocupado = true);
    try {
      final membro = await acao();
      if (!mounted) return;
      setState(() => _membro = membro);
      avisar(context, sucesso);
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _editar(Membro membro) async {
    final atualizado = await Navigator.of(context).push<Membro>(
      MaterialPageRoute(builder: (_) => TelaFormularioMembro(membro: membro)),
    );
    if (atualizado == null || !mounted) return;
    setState(() => _membro = atualizado);
    avisar(context, 'Dados de ${atualizado.nome} atualizados.');
  }

  Future<void> _alterarAtivo(Membro membro) async {
    if (membro.ativo &&
        !await confirmar(
          context,
          titulo: 'Desativar ${membro.nome}?',
          mensagem: 'A carteirinha deixa de valer e o membro não consegue mais entrar no app. '
              'Você pode reativar depois.',
          acao: 'Desativar',
        )) {
      return;
    }
    await _executar(
      () => _repositorio.alterarAtivo(membro.id, ativo: !membro.ativo),
      membro.ativo ? '${membro.nome} foi desativado.' : '${membro.nome} foi reativado.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final membro = _membro;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Membro'),
        actions: [
          if (membro != null)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _ocupado ? null : () => _editar(membro),
            ),
        ],
      ),
      body: _erro != null
          ? AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar)
          : membro == null
              ? const Center(child: CircularProgressIndicator())
              : _conteudo(membro),
    );
  }

  Widget _conteudo(Membro membro) {
    final texto = Theme.of(context).textTheme;
    final hoje = Datas.hoje();
    final situacao = membro.situacao(hoje);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            AvatarMembro(membro, raio: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membro.nome,
                    style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: Cores.tinta),
                  ),
                  const SizedBox(height: 6),
                  SeloSituacao(situacao),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _CartaoCarteirinha(membro: membro, hoje: hoje),
        const SizedBox(height: 20),
        _Linha(icone: Icons.mail_outline, rotulo: 'E-mail', valor: membro.email),
        _Linha(icone: Icons.phone_outlined, rotulo: 'Telefone', valor: membro.telefone ?? 'Não informado'),
        _Linha(icone: Icons.workspace_premium_outlined, rotulo: 'Plano', valor: membro.planoNome),
        _Linha(icone: Icons.event_available_outlined, rotulo: 'Membro desde', valor: Datas.formatar(membro.dataAdesao)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _ocupado ? null : () => _alterarAtivo(membro),
          style: OutlinedButton.styleFrom(
            foregroundColor: membro.ativo ? Cores.erro : Cores.primaria,
            minimumSize: const Size.fromHeight(48),
          ),
          icon: Icon(membro.ativo ? Icons.person_off_outlined : Icons.person_outline),
          label: Text(membro.ativo ? 'Desativar membro' : 'Reativar membro'),
        ),
      ],
    );
  }
}

/// Resumo da carteirinha digital no estilo da marca.
class _CartaoCarteirinha extends StatelessWidget {
  const _CartaoCarteirinha({required this.membro, required this.hoje});

  final Membro membro;
  final DateTime hoje;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final c = membro.carteirinha;
    final statusTexto = switch (c.status) {
      StatusCarteirinha.ativa => 'Carteirinha ativa',
      StatusCarteirinha.bloqueada => 'Carteirinha bloqueada',
      StatusCarteirinha.invalidada => 'Carteirinha invalidada',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Cores.primaria, Color(0xFF1C1F5C)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_2, size: 48, color: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusTexto, style: texto.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(membro.descricaoVencimento(hoje), style: texto.bodySmall?.copyWith(color: Colors.white70)),
                Text('Versão do QR Code: ${c.qrVersao}', style: texto.bodySmall?.copyWith(color: Cores.lilas)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.rotulo, required this.valor});

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icone, color: Cores.textoSecundario, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo, style: texto.labelMedium?.copyWith(color: Cores.textoSecundario)),
                Text(valor, style: texto.bodyLarge?.copyWith(color: Cores.tinta)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
