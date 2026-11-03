import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../auditoria/domain/registro_auditoria.dart';
import '../../auditoria/presentation/item_auditoria.dart';
import '../domain/membro.dart';
import '../domain/membros_repositorio.dart';
import 'dialogos_ciclo.dart';
import 'tela_formulario_membro.dart';
import 'widgets/visual_membro.dart';

/// Dados do membro, carteirinha, ações do administrador (RF07) e histórico (RF16).
class TelaDetalheMembro extends StatefulWidget {
  const TelaDetalheMembro({super.key, required this.membroId});

  final String membroId;

  @override
  State<TelaDetalheMembro> createState() => _TelaDetalheMembroState();
}

class _TelaDetalheMembroState extends State<TelaDetalheMembro> {
  Membro? _membro;
  List<RegistroAuditoria> _historico = const [];
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
      final (membro, historico) = await (
        _repositorio.buscar(widget.membroId),
        _repositorio.historico(widget.membroId),
      ).wait;
      if (mounted) {
        setState(() {
          _membro = membro;
          _historico = historico;
        });
      }
    } catch (e) {
      final erro = e is ParallelWaitError ? e.errors.$1 ?? e.errors.$2 : e;
      if (mounted) setState(() => _erro = mensagemDeErro(erro!));
    }
  }

  /// Executa uma ação que devolve o membro atualizado e recarrega o histórico.
  Future<void> _executar(Future<Membro> Function() acao, String sucesso) async {
    setState(() => _ocupado = true);
    try {
      final membro = await acao();
      final historico = await _repositorio.historico(membro.id);
      if (!mounted) return;
      setState(() {
        _membro = membro;
        _historico = historico;
      });
      avisar(context, sucesso);
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  Future<void> _editar(Membro membro) async {
    final atualizado = await Navigator.of(
      context,
    ).push<Membro>(MaterialPageRoute(builder: (_) => TelaFormularioMembro(membro: membro)));
    if (atualizado == null || !mounted) return;
    setState(() => _membro = atualizado);
    avisar(context, 'Dados de ${atualizado.nome} atualizados.');
  }

  Future<void> _confirmarPagamento(Membro membro) async {
    final data = await pedirDataPagamento(context, membro);
    if (data == null) return;
    await _executar(
      () => _repositorio.confirmarPagamento(membro.id, data),
      'Pagamento confirmado. Novo vencimento: ${Datas.formatar(membro.novoVencimento(data))}.',
    );
  }

  Future<void> _bloquear(Membro membro) async {
    final justificativa = await pedirJustificativa(
      context,
      titulo: 'Bloquear a carteirinha de ${membro.nome}?',
      mensagem: 'O QR Code atual deixa de valer até você desbloquear ou confirmar um novo pagamento.',
      rotulo: 'Motivo do bloqueio',
      acao: 'Bloquear',
      obrigatoria: true,
    );
    if (justificativa == null) return;
    await _executar(() => _repositorio.bloquear(membro.id, justificativa), 'Carteirinha bloqueada.');
  }

  Future<void> _desbloquear(Membro membro) async {
    final confirmou = await confirmar(
      context,
      titulo: 'Desbloquear a carteirinha?',
      mensagem: 'A carteirinha de ${membro.nome} volta a valer com um QR Code novo.',
      acao: 'Desbloquear',
    );
    if (!confirmou) return;
    await _executar(() => _repositorio.desbloquear(membro.id), 'Carteirinha desbloqueada.');
  }

  Future<void> _alterarAtivo(Membro membro) async {
    String? justificativa;
    if (membro.ativo) {
      justificativa = await pedirJustificativa(
        context,
        titulo: 'Desativar ${membro.nome}?',
        mensagem:
            'A carteirinha deixa de valer e o membro não consegue mais entrar no app. '
            'Você pode reativar depois.',
        rotulo: 'Motivo (opcional)',
        acao: 'Desativar',
        obrigatoria: false,
      );
      if (justificativa == null) return;
    }
    await _executar(
      () => _repositorio.alterarAtivo(membro.id, ativo: !membro.ativo, justificativa: justificativa),
      membro.ativo ? 'Cadastro de ${membro.nome} desativado.' : 'Cadastro de ${membro.nome} reativado.',
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
    final bloqueada = membro.carteirinha.status == StatusCarteirinha.bloqueada;

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
        if (membro.ativo) ...[
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('botao-confirmar-pagamento'),
            onPressed: _ocupado ? null : () => _confirmarPagamento(membro),
            icon: const Icon(Icons.payments_outlined),
            label: const Text('Confirmar pagamento'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _ocupado ? null : () => bloqueada ? _desbloquear(membro) : _bloquear(membro),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            icon: Icon(bloqueada ? Icons.lock_open_outlined : Icons.block),
            label: Text(bloqueada ? 'Desbloquear carteirinha' : 'Bloquear carteirinha'),
          ),
        ],
        const _TituloSecao('Dados do membro'),
        CartaoItem(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                _Linha(icone: Icons.mail_outline, rotulo: 'E-mail', valor: membro.email),
                _Linha(icone: Icons.phone_outlined, rotulo: 'Telefone', valor: membro.telefone ?? 'Não informado'),
                _Linha(
                  icone: Icons.workspace_premium_outlined,
                  rotulo: 'Plano',
                  valor: '${membro.planoNome} (ciclo de ${membro.planoDuracaoDias} dias)',
                ),
                _Linha(
                  icone: Icons.event_available_outlined,
                  rotulo: 'Membro desde',
                  valor: Datas.formatar(membro.dataAdesao),
                ),
              ],
            ),
          ),
        ),
        const _TituloSecao('Histórico'),
        CartaoItem(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _historico.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Nenhuma ação registrada ainda.',
                      style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
                    ),
                  )
                : Column(
                    children: [
                      for (final (i, registro) in _historico.indexed) ...[
                        if (i > 0) const Divider(),
                        ItemAuditoria(registro, mostrarDescricao: false),
                      ],
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: _ocupado ? null : () => _alterarAtivo(membro),
          style: TextButton.styleFrom(foregroundColor: membro.ativo ? Cores.erro : Cores.primaria),
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
      // Ativa no banco, mas vencida: o QR Code não passa no check-in.
      StatusCarteirinha.ativa when membro.diasParaVencer(hoje) < 0 => 'Carteirinha vencida',
      StatusCarteirinha.ativa => 'Carteirinha ativa',
      StatusCarteirinha.bloqueada => 'Carteirinha bloqueada',
      StatusCarteirinha.invalidada => 'Carteirinha invalidada',
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Cores.marca, Cores.marcaEscura]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(
            c.status == StatusCarteirinha.ativa ? Icons.qr_code_2 : Icons.qr_code_2_outlined,
            size: 48,
            color: c.status == StatusCarteirinha.ativa ? Colors.white : Colors.white38,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTexto,
                  style: texto.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                ),
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

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 10),
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
