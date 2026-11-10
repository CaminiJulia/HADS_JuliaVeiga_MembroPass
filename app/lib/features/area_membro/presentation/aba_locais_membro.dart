import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/contraste.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../identidade/domain/organizacao.dart';
import '../../unidades/domain/unidade_evento.dart';
import '../domain/carteirinha_membro.dart';

enum _Filtro { todos, eventos, unidades }

/// Aba de locais do membro (RF09/RF11): eventos com capa e data em destaque,
/// e as unidades onde a carteirinha é aceita. Tocar abre os detalhes.
class AbaLocaisMembro extends StatefulWidget {
  const AbaLocaisMembro({super.key, required this.organizacao, required this.aoMostrarCarteirinha});

  final Organizacao? organizacao;
  final VoidCallback aoMostrarCarteirinha;

  @override
  State<AbaLocaisMembro> createState() => _AbaLocaisMembroState();
}

class _AbaLocaisMembroState extends State<AbaLocaisMembro> {
  List<UnidadeEvento>? _locais;
  String? _erro;
  _Filtro _filtro = _Filtro.todos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final lista = await context.read<AreaMembroRepositorio>().locais();
      if (mounted) setState(() => _locais = lista);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  _Paleta get _paleta {
    final cor = Contraste.lerHex(widget.organizacao?.corPrincipal ?? '') ?? Cores.marca;
    final segunda = Contraste.lerHex(widget.organizacao?.corSecundaria ?? '') ?? Color.lerp(cor, Colors.black, 0.35)!;
    return (cor, segunda);
  }

  void _abrirDetalhes(UnidadeEvento local) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _DetalhesLocal(
        local: local,
        paleta: _paleta,
        aoMostrarCarteirinha: () {
          Navigator.pop(context);
          widget.aoMostrarCarteirinha();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = _locais;
    if (_erro != null) return AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar);
    if (lista == null) return const Center(child: CircularProgressIndicator());

    final hoje = Datas.hoje();
    // Eventos do mais próximo ao mais distante; unidades em ordem alfabética.
    final eventos = lista.where((l) => l.evento && !l.encerrado(hoje)).toList()
      ..sort((a, b) => (a.dataInicio ?? hoje).compareTo(b.dataInicio ?? hoje));
    final unidades = lista.where((l) => !l.evento).toList()..sort((a, b) => a.nome.compareTo(b.nome));
    final mostrarEventos = _filtro != _Filtro.unidades && eventos.isNotEmpty;
    final mostrarUnidades = _filtro != _Filtro.eventos && unidades.isNotEmpty;
    final texto = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _carregar,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            key: const Key('lista-locais'),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Text('Onde usar', style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                'Lugares e eventos que aceitam a sua carteirinha.',
                style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
              ),
              const SizedBox(height: 14),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip(_Filtro.todos, 'Todos', lista.where((l) => !l.encerrado(hoje)).length),
                    const SizedBox(width: 8),
                    _chip(_Filtro.eventos, 'Eventos', eventos.length, icone: Icons.celebration_outlined),
                    const SizedBox(width: 8),
                    _chip(_Filtro.unidades, 'Unidades', unidades.length, icone: Icons.storefront_outlined),
                  ],
                ),
              ),
              if (!mostrarEventos && !mostrarUnidades)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 0),
                  child: Column(
                    children: [
                      const Icon(Icons.place_outlined, size: 48, color: Cores.textoSecundario),
                      const SizedBox(height: 12),
                      Text(
                        switch (_filtro) {
                          _Filtro.eventos => 'Nenhum evento programado por enquanto.',
                          _Filtro.unidades => 'Nenhuma unidade cadastrada para o seu plano.',
                          _Filtro.todos => 'Ainda não há locais cadastrados para o seu plano.',
                        },
                        textAlign: TextAlign.center,
                        style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
                      ),
                    ],
                  ),
                ),
              if (mostrarEventos) ...[
                const _TituloSecao('Próximos eventos'),
                for (final e in eventos) ...[
                  _CartaoEvento(evento: e, paleta: _paleta, hoje: hoje, aoTocar: () => _abrirDetalhes(e)),
                  const SizedBox(height: 14),
                ],
              ],
              if (mostrarUnidades) ...[
                const _TituloSecao('Unidades'),
                for (final u in unidades) ...[
                  _CartaoUnidade(unidade: u, paleta: _paleta, aoTocar: () => _abrirDetalhes(u)),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(_Filtro filtro, String rotulo, int quantidade, {IconData? icone}) {
    final selecionado = _filtro == filtro;
    return ChoiceChip(
      key: Key('filtro-locais-${filtro.name}'),
      selected: selecionado,
      showCheckmark: false,
      avatar: icone == null
          ? null
          : Icon(icone, size: 18, color: selecionado ? Cores.noPrimaria : Cores.textoSecundario),
      label: Text('$rotulo · $quantidade'),
      labelStyle: TextStyle(
        color: selecionado ? Cores.noPrimaria : Cores.tinta,
        fontWeight: selecionado ? FontWeight.w700 : FontWeight.w500,
      ),
      selectedColor: Cores.primaria,
      backgroundColor: Cores.superficie,
      side: BorderSide(color: selecionado ? Cores.primaria : Cores.borda),
      shape: const StadiumBorder(),
      onSelected: (_) => setState(() => _filtro = filtro),
    );
  }
}

/// Cor principal e segunda cor do degradê da organização.
typedef _Paleta = (Color, Color);

/// "Acontecendo agora", "Hoje", "Amanhã", "Em 20 dias"; `null` para unidades.
(String, Color)? _contagem(UnidadeEvento e, DateTime hoje) {
  switch (e.situacao(hoje)) {
    case SituacaoEvento.acontecendo:
      return ('Acontecendo agora', Cores.sucesso);
    case SituacaoEvento.futuro:
      final dias = e.diasParaComecar(hoje);
      return (dias == 1 ? 'Amanhã' : 'Em $dias dias', dias <= 7 ? Cores.alerta : Cores.primaria);
    case SituacaoEvento.encerrado:
      return ('Encerrado', Cores.textoSecundario);
    case null:
      return null;
  }
}

/// Capa do local: a imagem enviada pela organização ou, sem ela, o degradê
/// da marca com um ícone grande e apagado.
class _Capa extends StatelessWidget {
  const _Capa({required this.local, required this.paleta});

  final UnidadeEvento local;
  final _Paleta paleta;

  @override
  Widget build(BuildContext context) {
    final imagem = local.imagem;
    if (imagem != null) {
      return Image.memory(
        imagem,
        fit: BoxFit.cover,
        semanticLabel: 'Imagem de ${local.nome}',
        errorBuilder: (_, _, _) => _Capa(local: local.semImagem, paleta: paleta),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [paleta.$1, paleta.$2]),
      ),
      child: LayoutBuilder(
        builder: (context, r) => Stack(
          children: [
            Positioned(
              right: -r.maxHeight * 0.12,
              bottom: -r.maxHeight * 0.18,
              child: Icon(
                local.evento ? Icons.celebration : Icons.storefront,
                size: r.maxHeight * 0.95,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Evento com capa, "calendário" com dia e mês e selo de contagem regressiva.
class _CartaoEvento extends StatelessWidget {
  const _CartaoEvento({required this.evento, required this.paleta, required this.hoje, required this.aoTocar});

  final UnidadeEvento evento;
  final _Paleta paleta;
  final DateTime hoje;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final e = evento;
    final inicio = e.dataInicio;
    final periodo = inicio != null && e.dataFim != null ? Datas.periodoPorExtenso(inicio, e.dataFim!) : null;
    final contagem = _contagem(e, hoje);

    return Material(
      color: Cores.superficie,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Cores.borda),
      ),
      child: InkWell(
        onTap: aoTocar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Capa(local: e, paleta: paleta),
                  // Escurece a base da capa para o selo e a data se destacarem em qualquer foto.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x66000000)],
                      ),
                    ),
                  ),
                  if (inicio != null)
                    Positioned(
                      left: 14,
                      top: 14,
                      child: _Calendario(data: inicio, cor: paleta.$2),
                    ),
                  if (contagem != null)
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Cores.fundo.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: contagem.$2.withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(color: contagem.$2, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              contagem.$1,
                              style: texto.labelSmall?.copyWith(color: contagem.$2, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.nome, style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  if (periodo != null) ...[
                    const SizedBox(height: 8),
                    _Linha(icone: Icons.event_outlined, texto: periodo),
                  ],
                  if (e.localizacao != null) ...[
                    const SizedBox(height: 6),
                    _Linha(icone: Icons.place_outlined, texto: e.localizacao!),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Folhinha de calendário: mês em cima, dia grande embaixo.
class _Calendario extends StatelessWidget {
  const _Calendario({required this.data, required this.cor});

  final DateTime data;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: cor,
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text(
              Datas.mesAbreviado(data.month),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '${data.day}',
              style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.w900, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Unidade em formato compacto: miniatura, nome e endereço.
class _CartaoUnidade extends StatelessWidget {
  const _CartaoUnidade({required this.unidade, required this.paleta, required this.aoTocar});

  final UnidadeEvento unidade;
  final _Paleta paleta;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Material(
      color: Cores.superficie,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Cores.borda),
      ),
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: _Capa(local: unidade, paleta: paleta),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(unidade.nome, style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    if (unidade.localizacao != null) ...[
                      const SizedBox(height: 4),
                      _Linha(icone: Icons.place_outlined, texto: unidade.localizacao!),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.verified_outlined, size: 15, color: Cores.sucesso),
                        const SizedBox(width: 5),
                        Text(
                          'Aceita seu plano',
                          style: texto.labelSmall?.copyWith(color: Cores.sucesso, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Cores.textoSecundario),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detalhes do local, como entrar e o atalho para a carteirinha.
class _DetalhesLocal extends StatelessWidget {
  const _DetalhesLocal({required this.local, required this.paleta, required this.aoMostrarCarteirinha});

  final UnidadeEvento local;
  final _Paleta paleta;
  final VoidCallback aoMostrarCarteirinha;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final l = local;
    final hoje = Datas.hoje();
    final periodo = l.dataInicio != null && l.dataFim != null
        ? Datas.periodoPorExtenso(l.dataInicio!, l.dataFim!)
        : null;
    final contagem = _contagem(l, hoje);
    final endereco = l.localizacao;

    return SafeArea(
      child: SingleChildScrollView(
        key: const Key('detalhes-local'),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 8,
                child: _Capa(local: l, paleta: paleta),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  l.evento ? Icons.celebration_outlined : Icons.storefront_outlined,
                  size: 16,
                  color: Cores.primaria,
                ),
                const SizedBox(width: 6),
                Text(
                  l.evento ? 'EVENTO' : 'UNIDADE',
                  style: texto.labelMedium?.copyWith(
                    color: Cores.primaria,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                if (contagem != null) ...[
                  const SizedBox(width: 10),
                  Text('·  ${contagem.$1}', style: texto.labelMedium?.copyWith(color: contagem.$2)),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(l.nome, style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (periodo != null) ...[const SizedBox(height: 12), _Linha(icone: Icons.event_outlined, texto: periodo)],
            if (endereco != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _Linha(icone: Icons.place_outlined, texto: endereco),
                  ),
                  TextButton.icon(
                    key: const Key('copiar-endereco'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: endereco));
                      if (context.mounted) avisar(context, 'Endereço copiado.');
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copiar'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Cores.superficieElevada, borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.qr_code_scanner, color: Cores.primaria),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Na entrada', style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(
                          'Mostre sua carteirinha: o QR Code é lido na hora e seu acesso é liberado.',
                          style: texto.bodyMedium?.copyWith(height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('local-mostrar-carteirinha'),
                onPressed: aoMostrarCarteirinha,
                icon: const Icon(Icons.qr_code_2),
                label: const Text('Mostrar minha carteirinha'),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
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

class _Linha extends StatelessWidget {
  const _Linha({required this.icone, required this.texto});

  final IconData icone;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 16, color: Cores.textoSecundario),
        const SizedBox(width: 6),
        Expanded(child: Text(texto, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}
