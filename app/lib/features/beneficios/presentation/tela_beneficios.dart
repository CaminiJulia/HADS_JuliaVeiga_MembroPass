import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../planos/domain/plano.dart';
import '../../planos/domain/planos_repositorio.dart';
import '../domain/beneficio.dart';
import '../domain/beneficios_repositorio.dart';
import 'cartao_beneficio.dart';
import 'tela_formulario_beneficio.dart';

/// RF08: benefícios da organização e os planos que dão direito a cada um.
class TelaBeneficios extends StatefulWidget {
  const TelaBeneficios({super.key});

  @override
  State<TelaBeneficios> createState() => _TelaBeneficiosState();
}

class _TelaBeneficiosState extends State<TelaBeneficios> {
  List<Beneficio>? _beneficios;
  List<Plano> _planos = const [];
  String? _erro;

  BeneficiosRepositorio get _repositorio => context.read<BeneficiosRepositorio>();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final (beneficios, planos) = await (_repositorio.listar(), context.read<PlanosRepositorio>().listar()).wait;
      if (mounted) {
        setState(() {
          _beneficios = beneficios;
          _planos = planos;
        });
      }
    } catch (e) {
      final erro = e is ParallelWaitError ? e.errors.$1 ?? e.errors.$2 : e;
      if (mounted) setState(() => _erro = mensagemDeErro(erro!));
    }
  }

  Future<void> _abrirFormulario([Beneficio? beneficio]) async {
    final salvo = await Navigator.of(context).push<Beneficio>(
      MaterialPageRoute(
        builder: (_) => TelaFormularioBeneficio(beneficio: beneficio, planos: _planos),
      ),
    );
    if (salvo == null || !mounted) return;
    avisar(context, beneficio == null ? 'Benefício "${salvo.nome}" criado.' : 'Benefício "${salvo.nome}" atualizado.');
    await _carregar();
  }

  Future<void> _excluir(Beneficio beneficio) async {
    final confirmou = await confirmar(
      context,
      titulo: 'Excluir "${beneficio.nome}"?',
      mensagem: 'O benefício deixa de aparecer para os membros de todos os planos.',
      acao: 'Excluir',
    );
    if (!confirmou || !mounted) return;
    try {
      await _repositorio.excluir(beneficio.id);
      if (!mounted) return;
      avisar(context, 'Benefício "${beneficio.nome}" excluído.');
      await _carregar();
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Benefícios')),
      floatingActionButton: _beneficios == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _abrirFormulario(),
              icon: const Icon(Icons.add),
              label: const Text('Novo benefício'),
            ),
      body: _corpo(),
    );
  }

  Widget _corpo() {
    if (_erro != null) return AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar);
    final beneficios = _beneficios;
    if (beneficios == null) return const Center(child: CircularProgressIndicator());
    if (beneficios.isEmpty) {
      return const AvisoTela(
        icone: Icons.redeem_outlined,
        texto: 'Nenhum benefício ainda.\nCadastre descontos e vantagens para os seus membros.',
      );
    }

    final hoje = Datas.hoje();
    final vigentes = beneficios.where((b) => b.situacao(hoje) == SituacaoVigencia.vigente).length;
    final texto = Theme.of(context).textTheme;

    return RefreshIndicator(
      onRefresh: _carregar,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
                child: Text(
                  '${beneficios.length} ${beneficios.length == 1 ? 'benefício' : 'benefícios'} · '
                  '$vigentes ${vigentes == 1 ? 'vigente' : 'vigentes'}',
                  style: texto.labelMedium?.copyWith(color: Cores.textoSecundario),
                ),
              ),
              for (final b in beneficios)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: CartaoBeneficio(
                    beneficio: b,
                    situacao: b.situacao(hoje),
                    // Na mesma ordem da lista de planos, não na ordem em que foram vinculados.
                    planos: [
                      for (final p in _planos)
                        if (b.planoIds.contains(p.id)) p,
                    ],
                    aoEditar: () => _abrirFormulario(b),
                    aoExcluir: () => _excluir(b),
                  ),
                ),
              const SizedBox(height: 4),
              const CaixaInfo(
                'Cada membro vê, no app, os benefícios vigentes do plano dele. '
                'Benefícios encerrados ou ainda não iniciados ficam ocultos.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
