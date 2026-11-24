import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/api/cliente_api.dart';
import '../../../core/formatacao/datas.dart';
import '../../../core/rotas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../auth/domain/usuario.dart';
import '../../auth/presentation/sair.dart';
import '../../perfil/domain/perfil.dart';
import '../../perfil/presentation/avatar_perfil.dart';
import '../../planos/presentation/cor_plano.dart';
import '../../unidades/domain/unidade_evento.dart';
import '../domain/checkin.dart';
import 'leitor_qr.dart';
import 'tela_resultado_checkin.dart';

/// Área do operador (RF02 e RF10): escolhe o local onde está, lê o QR Code
/// das carteirinhas e acompanha as leituras do dia naquele local.
class TelaAreaOperador extends StatefulWidget {
  const TelaAreaOperador({super.key});

  @override
  State<TelaAreaOperador> createState() => _TelaAreaOperadorState();
}

class _TelaAreaOperadorState extends State<TelaAreaOperador> {
  List<UnidadeEvento>? _locais;
  String? _erroLocais;

  /// Onde o operador está. Fica escolhido até ele trocar ou sair.
  UnidadeEvento? _local;

  List<RegistroCheckin>? _registros;
  String? _erroRegistros;

  /// Enviando um QR Code para a API: o botão de leitura fica ocupado.
  bool _validando = false;

  _Filtro _filtro = _Filtro.todas;

  /// Foto e nome atualizados do operador; `null` até carregar.
  Perfil? _perfil;

  OperadorRepositorio get _repositorio => context.read<OperadorRepositorio>();

  @override
  void initState() {
    super.initState();
    _carregarLocais();
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

  /// Abre "Meu perfil" e, na volta, atualiza a foto e o nome do cabeçalho.
  Future<void> _abrirPerfil() async {
    await Navigator.of(context).pushNamed(Rotas.perfilOperador);
    if (mounted) await _carregarPerfil();
  }

  Future<void> _carregarLocais() async {
    setState(() => _erroLocais = null);
    try {
      final locais = await _repositorio.locais();
      if (!mounted) return;
      setState(() => _locais = locais);
      // Um local só: não há o que escolher.
      if (locais.length == 1) _escolher(locais.single);
    } catch (e) {
      if (mounted) setState(() => _erroLocais = mensagemDeErro(e));
    }
  }

  void _escolher(UnidadeEvento local) {
    setState(() {
      _local = local;
      _registros = null;
      _filtro = _Filtro.todas;
    });
    _carregarRegistros();
  }

  Future<void> _carregarRegistros() async {
    final local = _local;
    if (local == null) return;
    setState(() => _erroRegistros = null);
    try {
      final registros = await _repositorio.checkinsDeHoje(local.id);
      if (mounted && _local == local) setState(() => _registros = registros);
    } catch (e) {
      if (mounted && _local == local) setState(() => _erroRegistros = mensagemDeErro(e));
    }
  }

  /// Lê, valida e mostra o resultado; repete enquanto o operador pedir a
  /// próxima. Com [primeira], valida essa identificação antes de abrir a câmera.
  Future<void> _lerCarteirinha({IdentificacaoCarteirinha? primeira}) async {
    final local = _local;
    if (local == null || _validando) return;
    final leitor = context.read<LeitorQr>();

    var proxima = primeira;
    while (true) {
      if (!mounted) return;
      final carteirinha = proxima ?? await leitor.ler(context);
      proxima = null;
      if (carteirinha == null || !mounted) return;

      setState(() => _validando = true);
      ResultadoCheckin resultado;
      try {
        resultado = await _repositorio.registrar(localId: local.id, carteirinha: carteirinha);
      } catch (e) {
        if (!mounted) return;
        setState(() => _validando = false);
        // O local deixou de valer (evento encerrado ou local excluído).
        if (e is ErroApi && (e.status == 404 || e.status == 409)) {
          setState(() => _local = null);
          _carregarLocais();
        }
        avisar(context, mensagemDeErro(e));
        return;
      }
      if (!mounted) return;
      setState(() => _validando = false);
      _carregarRegistros();

      final lerProxima = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => TelaResultadoCheckin(resultado: resultado, localNome: local.nome),
        ),
      );
      if (lerProxima != true) return;
    }
  }

  /// Sem câmera ou QR ilegível: o operador digita o número da carteirinha.
  Future<void> _digitarNumero() async {
    final numero = await pedirNumeroCarteirinha(context);
    if (numero != null && mounted) await _lerCarteirinha(primeira: PorNumero(numero));
  }

  Future<void> _sair() async {
    final confirmou = await confirmar(
      context,
      titulo: 'Sair da conta?',
      mensagem: 'Você vai precisar entrar de novo para validar check-ins.',
      acao: 'Sair',
    );
    if (confirmou && mounted) sairDaConta(context);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ModalRoute.of(context)?.settings.arguments as Usuario?;
    final local = _local;
    final cabecalho = _Cabecalho(
      usuario: usuario,
      perfil: _perfil,
      local: local,
      aoSair: _sair,
      aoAbrirPerfil: _abrirPerfil,
      aoTrocarLocal: local == null || _validando ? null : () => setState(() => _local = null),
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: local == null ? _carregarLocais : _carregarRegistros,
        edgeOffset: 120,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [cabecalho, if (local == null) ..._escolhaDoLocal() else ..._painelDoLocal()],
        ),
      ),
    );
  }

  /// Conteúdo centralizado e com largura máxima, como no painel do admin.
  static Widget _conteudo(Widget child, {EdgeInsets padding = const EdgeInsets.fromLTRB(16, 20, 16, 0)}) =>
      SliverToBoxAdapter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(padding: padding, child: child),
          ),
        ),
      );

  List<Widget> _escolhaDoLocal() {
    final locais = _locais;
    if (_erroLocais != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AvisoTela(icone: Icons.cloud_off, texto: _erroLocais!, aoTentarDeNovo: _carregarLocais),
        ),
      ];
    }
    if (locais == null) {
      return [const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))];
    }
    if (locais.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: AvisoTela(
            icone: Icons.location_off_outlined,
            texto: 'Nenhuma unidade ou evento disponível hoje. Fale com a administração.',
            aoTentarDeNovo: _carregarLocais,
          ),
        ),
      ];
    }

    final texto = Theme.of(context).textTheme;
    final eventos = locais.where((l) => l.evento).toList();
    final unidades = locais.where((l) => !l.evento).toList();
    return [
      _conteudo(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Onde você está?', style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(
              'Escolha o local para começar a validar as carteirinhas.',
              style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
            ),
            if (eventos.isNotEmpty) ...[
              const _TituloSecao('Eventos de hoje', icone: Icons.celebration_outlined),
              for (final l in eventos) ...[_OpcaoLocal(l, aoTocar: () => _escolher(l)), const SizedBox(height: 10)],
            ],
            if (unidades.isNotEmpty) ...[
              const _TituloSecao('Unidades', icone: Icons.storefront_outlined),
              for (final l in unidades) ...[_OpcaoLocal(l, aoTocar: () => _escolher(l)), const SizedBox(height: 10)],
            ],
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
      ),
    ];
  }

  List<Widget> _painelDoLocal() {
    final registros = _registros;
    final filtrados = registros?.where(_filtro.aceita).toList();
    final texto = Theme.of(context).textTheme;

    return [
      _conteudo(
        _AreaLeitura(validando: _validando, aoLer: _lerCarteirinha, aoDigitar: _digitarNumero),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      ),
      _conteudo(_Placar(registros: registros)),
      _conteudo(
        Row(
          children: [
            Expanded(
              child: Text('Leituras de hoje', style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (registros != null && registros.isNotEmpty)
              Text('${registros.length} no total', style: texto.bodySmall?.copyWith(color: Cores.textoSecundario)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      ),
      if (registros != null && registros.isNotEmpty)
        _conteudo(
          _FiltroLeituras(selecionado: _filtro, aoEscolher: (f) => setState(() => _filtro = f)),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        ),
      if (_erroRegistros != null)
        _conteudo(_AvisoLista(icone: Icons.cloud_off, texto: _erroRegistros!, aoTentarDeNovo: _carregarRegistros))
      else if (registros == null || filtrados == null)
        _conteudo(
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        )
      else if (registros.isEmpty)
        _conteudo(
          const _AvisoLista(
            icone: Icons.qr_code_2,
            texto: 'Nenhuma carteirinha lida aqui hoje.',
            detalhe: 'As entradas aparecem aqui assim que você ler a primeira.',
          ),
        )
      else if (filtrados.isEmpty)
        _conteudo(const _AvisoLista(icone: Icons.filter_alt_off_outlined, texto: 'Nenhuma leitura neste filtro.'))
      else
        _conteudo(
          Column(
            children: [
              for (var i = 0; i < filtrados.length; i++)
                _ItemLinhaDoTempo(filtrados[i], primeiro: i == 0, ultimo: i == filtrados.length - 1),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        ),
    ];
  }
}

/// Filtros do histórico do dia.
enum _Filtro {
  todas('Todas'),
  liberadas('Liberadas'),
  recusadas('Recusadas');

  const _Filtro(this.rotulo);

  final String rotulo;

  bool aceita(RegistroCheckin r) => switch (this) {
    _Filtro.todas => true,
    _Filtro.liberadas => r.aprovado,
    _Filtro.recusadas => !r.aprovado,
  };
}

/// Cabeçalho na cor da marca: saudação, data e, com o local escolhido, onde
/// o operador está e o botão de trocar.
class _Cabecalho extends StatelessWidget {
  const _Cabecalho({
    required this.usuario,
    required this.perfil,
    required this.local,
    required this.aoSair,
    required this.aoAbrirPerfil,
    this.aoTrocarLocal,
  });

  final Usuario? usuario;
  final Perfil? perfil;
  final UnidadeEvento? local;
  final VoidCallback aoSair;
  final VoidCallback aoAbrirPerfil;
  final VoidCallback? aoTrocarLocal;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final nome = perfil?.nome ?? usuario?.nome;
    final primeiroNome = nome?.split(' ').first;
    final iniciais = Perfil(id: '', nome: nome ?? '', email: '', organizacaoNome: '').iniciais;
    final local = this.local;
    final hoje = Datas.diaPorExtenso(Datas.hoje());

    return SliverAppBar(
      pinned: true,
      expandedHeight: local == null ? 150 : 210,
      automaticallyImplyLeading: false,
      // Avatar sempre visível, mesmo com o cabeçalho encolhido: abre o perfil.
      leading: Semantics(
        button: true,
        label: 'Meu perfil',
        excludeSemantics: true,
        child: Tooltip(
          message: 'Meu perfil',
          child: InkWell(
            onTap: aoAbrirPerfil,
            customBorder: const CircleBorder(),
            child: Center(
              child: AvatarPerfil(iniciais: iniciais, foto: perfil?.foto, tamanho: 38, borda: true),
            ),
          ),
        ),
      ),
      leadingWidth: 64,
      titleSpacing: 0,
      backgroundColor: Cores.marcaEscura,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text('Validar check-in', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [
        IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: aoSair),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Cores.marca, Cores.marcaEscura],
            ),
          ),
          child: Stack(
            children: [
              // QR Code grande e apagado ao fundo, só de enfeite.
              Positioned(
                right: -28,
                bottom: -36,
                child: Icon(Icons.qr_code_2, size: 190, color: Colors.white.withValues(alpha: 0.06)),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, kToolbarHeight + 2, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        [if (primeiroNome != null) 'Olá, $primeiroNome', hoje].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: texto.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                      if (local != null) ...[
                        const SizedBox(height: 12),
                        _LocalAtual(local, aoTrocar: aoTrocarLocal),
                      ] else if (usuario != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          usuario!.organizacaoNome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: texto.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Faixa translúcida com o local atual, dentro do cabeçalho.
class _LocalAtual extends StatelessWidget {
  const _LocalAtual(this.local, {this.aoTrocar});

  final UnidadeEvento local;
  final VoidCallback? aoTrocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(local.evento ? Icons.event : Icons.storefront_outlined, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ponto verde: o operador está "em serviço" neste local.
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Cores.sucesso, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'VALIDANDO EM',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: texto.labelSmall?.copyWith(
                          color: Cores.lilas,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  local.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: texto.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          TextButton(
            key: const Key('botao-trocar-local'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            onPressed: aoTrocar,
            child: const Text('Trocar'),
          ),
        ],
      ),
    );
  }
}

/// O botão principal: um círculo grande para tocar sem precisar mirar,
/// com o atalho de digitar o número logo abaixo.
class _AreaLeitura extends StatelessWidget {
  const _AreaLeitura({required this.validando, required this.aoLer, required this.aoDigitar});

  final bool validando;
  final VoidCallback aoLer;
  final VoidCallback aoDigitar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
      decoration: BoxDecoration(
        color: Cores.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        children: [
          Semantics(
            button: true,
            label: validando ? 'Validando carteirinha' : 'Ler carteirinha',
            excludeSemantics: true,
            child: _BotaoCircular(key: const Key('botao-ler-qr'), validando: validando, aoTocar: aoLer),
          ),
          const SizedBox(height: 18),
          Text(
            validando ? 'Validando...' : 'Ler carteirinha',
            style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Toque no botão e aponte a câmera para o QR Code do membro.',
            textAlign: TextAlign.center,
            style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 6),
          TextButton.icon(
            key: const Key('botao-digitar-numero'),
            onPressed: validando ? null : aoDigitar,
            icon: const Icon(Icons.keyboard_outlined, size: 20),
            label: const Text('QR Code não lê? Digitar o número'),
          ),
        ],
      ),
    );
  }
}

/// Círculo com degradê e dois anéis em volta. Sem animação contínua: o
/// destaque vem da forma, e a tela fica parada quando ninguém está lendo.
class _BotaoCircular extends StatelessWidget {
  const _BotaoCircular({super.key, required this.validando, required this.aoTocar});

  final bool validando;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    Widget anel(double tamanho, double alfa) => Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Cores.primaria.withValues(alpha: alfa), width: 1.5),
      ),
    );

    return SizedBox.square(
      dimension: 188,
      child: Stack(
        alignment: Alignment.center,
        children: [
          anel(188, 0.12),
          anel(160, 0.22),
          Material(
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: 8,
            shadowColor: Cores.marca,
            child: Ink(
              width: 132,
              height: 132,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: validando ? const [Cores.borda, Cores.superficieElevada] : const [Cores.lilas, Cores.marca],
                ),
              ),
              child: InkWell(
                onTap: validando ? null : aoTocar,
                child: Center(
                  child: validando
                      ? const SizedBox.square(
                          dimension: 40,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                      : const Icon(Icons.qr_code_scanner, size: 60, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placar do dia: liberadas, com alerta e recusadas, e a proporção entre elas.
class _Placar extends StatelessWidget {
  const _Placar({required this.registros});

  final List<RegistroCheckin>? registros;

  @override
  Widget build(BuildContext context) {
    final r = registros;
    int conta(DesfechoCheckin d) => r?.where((x) => x.desfecho == d).length ?? 0;
    final liberadas = conta(DesfechoCheckin.liberado);
    final alerta = conta(DesfechoCheckin.liberadoComAlerta);
    final recusadas = conta(DesfechoCheckin.recusado);
    final total = liberadas + alerta + recusadas;

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // "Liberadas" conta também as com alerta: todas entraram.
              Expanded(
                child: _Numero(
                  key: const Key('contador-liberadas'),
                  rotulo: 'Liberadas',
                  valor: r == null ? null : liberadas + alerta,
                  desfecho: DesfechoCheckin.liberado,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Numero(
                  key: const Key('contador-alerta'),
                  rotulo: 'Com alerta',
                  valor: r == null ? null : alerta,
                  desfecho: DesfechoCheckin.liberadoComAlerta,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Numero(
                  key: const Key('contador-recusadas'),
                  rotulo: 'Recusadas',
                  valor: r == null ? null : recusadas,
                  desfecho: DesfechoCheckin.recusado,
                ),
              ),
            ],
          ),
        ),
        if (total > 0) ...[
          const SizedBox(height: 12),
          // Barra com a proporção de cada desfecho.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  for (final (d, n) in [
                    (DesfechoCheckin.liberado, liberadas),
                    (DesfechoCheckin.liberadoComAlerta, alerta),
                    (DesfechoCheckin.recusado, recusadas),
                  ])
                    if (n > 0)
                      Expanded(
                        flex: n,
                        child: ColoredBox(color: d.cor),
                      ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Numero extends StatelessWidget {
  const _Numero({super.key, required this.rotulo, required this.valor, required this.desfecho});

  final String rotulo;
  final int? valor;
  final DesfechoCheckin desfecho;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Semantics(
      label: '$rotulo: ${valor ?? 'carregando'}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
        decoration: BoxDecoration(
          color: desfecho.cor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: desfecho.cor.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(desfecho.icone, size: 20, color: desfecho.cor),
            const SizedBox(height: 8),
            Text(
              valor?.toString() ?? '–',
              style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1),
            ),
            const SizedBox(height: 4),
            Text(rotulo, style: texto.bodySmall?.copyWith(color: Cores.textoSecundario)),
          ],
        ),
      ),
    );
  }
}

class _FiltroLeituras extends StatelessWidget {
  const _FiltroLeituras({required this.selecionado, required this.aoEscolher});

  final _Filtro selecionado;
  final ValueChanged<_Filtro> aoEscolher;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        for (final f in _Filtro.values)
          ChoiceChip(
            key: Key('filtro-${f.name}'),
            label: Text(f.rotulo),
            selected: f == selecionado,
            showCheckmark: false,
            onSelected: (_) => aoEscolher(f),
          ),
      ],
    );
  }
}

/// Uma leitura do dia, na linha do tempo: hora, ponto colorido e o membro.
class _ItemLinhaDoTempo extends StatelessWidget {
  const _ItemLinhaDoTempo(this.registro, {required this.primeiro, required this.ultimo});

  final RegistroCheckin registro;
  final bool primeiro;
  final bool ultimo;

  String get _iniciais {
    final partes = registro.membroNome!.trim().split(RegExp(r'\s+'));
    return (partes.first[0] + (partes.length > 1 ? partes.last[0] : '')).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final desfecho = registro.desfecho;
    final digitado = registro.forma == FormaCheckin.numero;
    final reconhecido = registro.membroNome != null;
    final corPlano = corDoPlano(registro.planoCor);
    final detalhe = switch (desfecho) {
      DesfechoCheckin.recusado => registro.mensagem ?? 'Recusada',
      DesfechoCheckin.liberadoComAlerta => 'Pagamento vencido',
      DesfechoCheckin.liberado => registro.planoNome == null ? 'Liberada' : 'Plano ${registro.planoNome}',
    };
    final selo = switch (desfecho) {
      DesfechoCheckin.liberado => 'Liberada',
      DesfechoCheckin.liberadoComAlerta => 'Alerta',
      DesfechoCheckin.recusado => 'Recusada',
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                Datas.hora(registro.dataHora),
                style: texto.labelMedium?.copyWith(color: Cores.textoSecundario, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Trilho vertical com o ponto do desfecho.
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(width: 2, height: 18, color: primeiro ? Colors.transparent : Cores.borda),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: desfecho.cor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Cores.fundo, width: 2),
                  ),
                ),
                Expanded(child: Container(width: 2, color: ultimo ? Colors.transparent : Cores.borda)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Cores.superficie,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Cores.borda),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: (reconhecido ? corPlano : Cores.textoSecundario).withValues(alpha: 0.18),
                      foregroundColor: reconhecido ? corPlano : Cores.textoSecundario,
                      child: reconhecido
                          ? Text(_iniciais, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13))
                          : const Icon(Icons.help_outline, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            registro.membroNome ?? (digitado ? 'Número não reconhecido' : 'QR Code não reconhecido'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: texto.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            digitado ? '$detalhe · número digitado' : detalhe,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Selo(selo, cor: desfecho.cor.withValues(alpha: 0.16), corTexto: desfecho.cor),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unidade ou evento para escolher, com o endereço e o período.
class _OpcaoLocal extends StatelessWidget {
  const _OpcaoLocal(this.local, {required this.aoTocar});

  final UnidadeEvento local;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final fim = local.dataFim;
    final periodo = local.evento && fim != null
        ? (fim == Datas.hoje() ? 'Último dia hoje' : 'Até ${Datas.formatar(fim)}')
        : null;

    return CartaoItem(
      aoTocar: aoTocar,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: local.evento ? const [Cores.alerta, Color(0xFFE2703A)] : const [Cores.lilas, Cores.marca],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(local.evento ? Icons.event : Icons.storefront_outlined, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(local.nome, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  if (local.localizacao != null && local.localizacao!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 14, color: Cores.textoSecundario),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            local.localizacao!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (periodo != null) ...[
                    const SizedBox(height: 6),
                    Selo(periodo, cor: Cores.alertaFundo, corTexto: Cores.alerta),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Cores.textoSecundario),
          ],
        ),
      ),
    );
  }
}

class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto, {required this.icone});

  final String texto;
  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 24, 0, 10),
      child: Row(
        children: [
          Icon(icone, size: 16, color: Cores.lilas),
          const SizedBox(width: 6),
          Text(
            texto.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Cores.lilas, letterSpacing: 1.1, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AvisoLista extends StatelessWidget {
  const _AvisoLista({required this.icone, required this.texto, this.detalhe, this.aoTentarDeNovo});

  final IconData icone;
  final String texto;
  final String? detalhe;
  final VoidCallback? aoTentarDeNovo;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Cores.borda),
      ),
      child: Column(
        children: [
          Icon(icone, size: 40, color: Cores.lilas.withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: estilo.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (detalhe != null) ...[
            const SizedBox(height: 4),
            Text(
              detalhe!,
              textAlign: TextAlign.center,
              style: estilo.bodySmall?.copyWith(color: Cores.textoSecundario),
            ),
          ],
          if (aoTentarDeNovo != null) TextButton(onPressed: aoTentarDeNovo, child: const Text('Tentar de novo')),
        ],
      ),
    );
  }
}
