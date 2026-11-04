import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/formatacao/datas.dart';
import '../../core/rotas.dart';
import '../../core/suporte.dart';
import '../../core/tema/cores.dart';
import '../../core/widgets/componentes.dart';
import '../auth/domain/usuario.dart';
import '../auth/presentation/sair.dart';
import '../membros/domain/membro.dart';
import '../membros/domain/membros_repositorio.dart';
import '../perfil/domain/perfil.dart';
import '../perfil/presentation/avatar_perfil.dart';

/// Tela inicial do administrador: resumo dos membros, atalhos para cada
/// seção e o contato do suporte (RF18).
class TelaPainelAdmin extends StatefulWidget {
  const TelaPainelAdmin({super.key});

  static const _associacao = [
    _Secao('Membros', 'Cadastro, carteirinhas e situação', Icons.people_outline, Rotas.membros),
    _Secao('Ciclos e bloqueios', 'Confirmar pagamentos e bloquear', Icons.event_repeat_outlined, Rotas.ciclos),
    _Secao('Planos', 'Valores e duração dos ciclos', Icons.workspace_premium_outlined, Rotas.planos),
    _Secao('Benefícios', 'Descontos e parceiros', Icons.redeem_outlined, Rotas.beneficios),
  ];

  static const _organizacao = [
    _Secao('Unidades e eventos', 'Onde a carteirinha é aceita', Icons.place_outlined, Rotas.unidades),
    _Secao('Identidade visual', 'Logo e cor da carteirinha', Icons.palette_outlined, Rotas.identidade),
    _Secao('Histórico de ações', 'Auditoria da organização', Icons.history, Rotas.auditoria),
  ];

  static const _conta = [
    _Secao('Meu perfil', 'Foto, dados de contato e senha', Icons.account_circle_outlined, Rotas.perfil),
  ];

  @override
  State<TelaPainelAdmin> createState() => _TelaPainelAdminState();
}

class _TelaPainelAdminState extends State<TelaPainelAdmin> {
  /// `null` enquanto carrega ou se não foi possível carregar.
  Map<SituacaoMembro, int>? _contagem;

  /// Foto e nome atualizados do administrador; `null` até carregar.
  Perfil? _perfil;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    try {
      final perfil = await context.read<PerfilRepositorio>().buscar();
      if (mounted) setState(() => _perfil = perfil);
    } catch (_) {
      // Sem o perfil, o cabeçalho usa os dados do login.
    }
  }

  Future<void> _carregarResumo() async {
    try {
      final membros = await context.read<MembrosRepositorio>().listar();
      final hoje = Datas.hoje();
      final contagem = <SituacaoMembro, int>{};
      for (final m in membros) {
        contagem.update(m.situacao(hoje), (n) => n + 1, ifAbsent: () => 1);
      }
      if (mounted) setState(() => _contagem = contagem);
    } catch (_) {
      // O resumo é complementar: sem ele, o painel continua utilizável.
      if (mounted) setState(() => _contagem = null);
    }
  }

  /// Abre uma seção e, na volta, atualiza o resumo.
  Future<void> _abrir(String rota) async {
    await Navigator.of(context).pushNamed(rota);
    if (!mounted) return;
    await Future.wait([_carregarResumo(), _carregarPerfil()]);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ModalRoute.of(context)?.settings.arguments as Usuario?;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _carregarResumo,
        edgeOffset: 120,
        child: CustomScrollView(
          slivers: [
            _Cabecalho(usuario: usuario, perfil: _perfil, aoAbrirPerfil: () => _abrir(Rotas.perfil)),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Resumo(contagem: _contagem, aoAbrir: _abrir),
                        const _TituloGrupo('Associação'),
                        _GrupoSecoes(secoes: TelaPainelAdmin._associacao, aoAbrir: _abrir),
                        const _TituloGrupo('Organização'),
                        _GrupoSecoes(secoes: TelaPainelAdmin._organizacao, aoAbrir: _abrir),
                        const _TituloGrupo('Conta'),
                        _GrupoSecoes(secoes: TelaPainelAdmin._conta, aoAbrir: _abrir),
                        const SizedBox(height: 24),
                        const _CartaoSuporte(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho com a marca que encolhe ao rolar, mantendo o nome da organização
/// e o botão de sair sempre visíveis.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.usuario, required this.perfil, required this.aoAbrirPerfil});

  final Usuario? usuario;
  final Perfil? perfil;
  final VoidCallback aoAbrirPerfil;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final nome = perfil?.nome ?? usuario?.nome;
    final primeiroNome = nome?.split(' ').first;
    final iniciais = Perfil(id: '', nome: nome ?? '', email: '', organizacaoNome: '').iniciais;

    return SliverAppBar(
      pinned: true,
      expandedHeight: 168,
      automaticallyImplyLeading: false,
      backgroundColor: Cores.marcaEscura,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: () => sairDaConta(context)),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16, end: 64),
        expandedTitleScale: 1.45,
        title: Text(
          usuario?.organizacaoNome ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        background: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Cores.marca, Cores.marcaEscura],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 72, 0),
              // No topo, alinhado com o botão de sair.
              child: Align(
                alignment: Alignment.topLeft,
                child: Row(
                  children: [
                    // Avatar à esquerda, ao lado da saudação: abre o perfil.
                    Semantics(
                      button: true,
                      label: 'Meu perfil',
                      excludeSemantics: true,
                      child: Tooltip(
                        message: 'Meu perfil',
                        child: InkWell(
                          onTap: aoAbrirPerfil,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: AvatarPerfil(iniciais: iniciais, foto: perfil?.foto, tamanho: 48, borda: true),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PAINEL DA ORGANIZAÇÃO',
                            style: texto.labelSmall?.copyWith(
                              color: Cores.lilas,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (primeiroNome != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Olá, $primeiroNome',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: texto.bodyLarge?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Indicadores dos membros, com atalho para quem precisa de atenção.
class _Resumo extends StatelessWidget {
  const _Resumo({required this.contagem, required this.aoAbrir});

  final Map<SituacaoMembro, int>? contagem;
  final void Function(String rota) aoAbrir;

  @override
  Widget build(BuildContext context) {
    int? soma(Iterable<SituacaoMembro> situacoes) =>
        contagem == null ? null : situacoes.fold<int>(0, (t, s) => t + (contagem![s] ?? 0));

    final ativos = soma(SituacaoMembro.values.where((s) => s != SituacaoMembro.desativado));
    final vencendo = soma([SituacaoMembro.venceEmBreve]);
    final atrasados = soma([SituacaoMembro.vencido, SituacaoMembro.bloqueado]);

    // IntrinsicHeight + stretch: os três cartões ficam com a altura do maior.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _Indicador(
              rotulo: 'Membros ativos',
              valor: ativos,
              icone: Icons.people_alt_outlined,
              cor: Cores.primaria,
              aoTocar: () => aoAbrir(Rotas.membros),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Indicador(
              rotulo: 'Vencem em 7 dias',
              valor: vencendo,
              icone: Icons.schedule,
              cor: Cores.alerta,
              aoTocar: () => aoAbrir(Rotas.ciclos),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Indicador(
              rotulo: 'Vencidos ou bloqueados',
              valor: atrasados,
              icone: Icons.error_outline,
              cor: Cores.erro,
              aoTocar: () => aoAbrir(Rotas.ciclos),
            ),
          ),
        ],
      ),
    );
  }
}

class _Indicador extends StatelessWidget {
  const _Indicador({
    required this.rotulo,
    required this.valor,
    required this.icone,
    required this.cor,
    required this.aoTocar,
  });

  final String rotulo;
  final int? valor;
  final IconData icone;
  final Color cor;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$rotulo: ${valor ?? 'carregando'}',
      excludeSemantics: true,
      child: CartaoItem(
        aoTocar: aoTocar,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icone, size: 20, color: cor),
              const SizedBox(height: 10),
              Text(valor?.toString() ?? '–', style: texto.headlineSmall?.copyWith(color: Cores.tinta, height: 1)),
              const SizedBox(height: 4),
              Text(rotulo, maxLines: 2, style: texto.bodySmall?.copyWith(height: 1.25)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TituloGrupo extends StatelessWidget {
  const _TituloGrupo(this.texto);

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

class _Secao {
  const _Secao(this.titulo, this.descricao, this.icone, this.rota);

  final String titulo;
  final String descricao;
  final IconData icone;
  final String rota;
}

/// Seções agrupadas num único cartão, com divisórias, como numa lista de ajustes.
class _GrupoSecoes extends StatelessWidget {
  const _GrupoSecoes({required this.secoes, required this.aoAbrir});

  final List<_Secao> secoes;
  final void Function(String rota) aoAbrir;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return CartaoItem(
      child: Column(
        children: [
          for (final (i, secao) in secoes.indexed) ...[
            if (i > 0) const Divider(indent: 68),
            InkWell(
              onTap: () => aoAbrir(secao.rota),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Cores.primaria.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(secao.icone, color: Cores.primaria, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(secao.titulo, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(secao.descricao, style: texto.bodySmall),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Cores.textoSecundario),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// RF18: contatos do suporte da plataforma.
class _CartaoSuporte extends StatelessWidget {
  const _CartaoSuporte();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;

    Widget contato(IconData icone, String valor, String rotulo) => Row(
      children: [
        Icon(icone, size: 20, color: Cores.primaria),
        const SizedBox(width: 12),
        Expanded(child: SelectableText(valor, style: texto.bodyMedium)),
        IconButton(
          tooltip: 'Copiar $rotulo',
          icon: const Icon(Icons.copy_rounded, size: 18),
          color: Cores.textoSecundario,
          onPressed: () {
            Clipboard.setData(ClipboardData(text: valor));
            avisar(context, '${rotulo[0].toUpperCase()}${rotulo.substring(1)} copiado.');
          },
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 4, 8),
      decoration: BoxDecoration(
        color: Cores.primaria.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Cores.primaria.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent, color: Cores.primaria),
              const SizedBox(width: 10),
              Text('Precisa de ajuda?', style: texto.titleSmall),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Text('Fale com o suporte do MembroPass. ${Suporte.horario}.', style: texto.bodySmall),
          ),
          const SizedBox(height: 4),
          contato(Icons.mail_outline, Suporte.email, 'e-mail'),
          contato(Icons.chat_outlined, Suporte.whatsapp, 'WhatsApp'),
        ],
      ),
    );
  }
}
