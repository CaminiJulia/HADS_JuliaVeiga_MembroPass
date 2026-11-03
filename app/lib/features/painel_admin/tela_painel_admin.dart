import 'package:flutter/material.dart';

import '../../core/rotas.dart';
import '../../core/tema/cores.dart';
import '../auth/domain/usuario.dart';
import '../auth/presentation/sair.dart';

/// Tela inicial do administrador da organização: atalhos para cada seção.
/// As seções ainda não implementadas aparecem como "Em breve".
class TelaPainelAdmin extends StatelessWidget {
  const TelaPainelAdmin({super.key});

  static const _secoes = [
    _Secao('Planos', 'Valores e duração dos ciclos', Icons.workspace_premium_outlined, Rotas.planos),
    _Secao('Membros', 'Cadastro e carteirinhas', Icons.people_outline, Rotas.membros),
    _Secao('Ciclos e bloqueios', 'Confirmar pagamentos', Icons.event_repeat_outlined),
    _Secao('Benefícios', 'Descontos e parceiros', Icons.redeem_outlined, Rotas.beneficios),
    _Secao('Unidades e eventos', 'Onde a carteirinha vale', Icons.place_outlined),
    _Secao('Identidade visual', 'Logo e cor da carteirinha', Icons.palette_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final usuario = ModalRoute.of(context)?.settings.arguments as Usuario?;
    final texto = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Cabecalho(usuario: usuario)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Gerenciar',
                style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 164,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _secoes.length,
              itemBuilder: (context, i) => _CartaoSecao(_secoes[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cabecalho extends StatelessWidget {
  const _Cabecalho({required this.usuario});

  final Usuario? usuario;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final primeiroNome = usuario?.nome.split(' ').first;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Cores.primaria, Color(0xFF1C1F5C)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 8, 28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Painel da organização',
                        style: texto.labelLarge?.copyWith(color: Cores.lilas, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        usuario?.organizacaoNome ?? '',
                        style: texto.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      if (primeiroNome != null)
                        Text(
                          'Olá, $primeiroNome',
                          style: texto.bodyMedium?.copyWith(color: Colors.white70),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Sair',
                color: Colors.white,
                icon: const Icon(Icons.logout),
                onPressed: () => sairDaConta(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Secao {
  const _Secao(this.titulo, this.descricao, this.icone, [this.rota]);

  final String titulo;
  final String descricao;
  final IconData icone;

  /// `null` enquanto a seção não foi implementada.
  final String? rota;
}

class _CartaoSecao extends StatelessWidget {
  const _CartaoSecao(this.secao);

  final _Secao secao;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final disponivel = secao.rota != null;

    return Material(
      color: Cores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Cores.borda),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: disponivel ? () => Navigator.of(context).pushNamed(secao.rota!) : null,
        child: Opacity(
          opacity: disponivel ? 1 : 0.55,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Cores.lilas.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(secao.icone, color: Cores.primaria),
                    ),
                    const Spacer(),
                    if (!disponivel) const _Selo('Em breve'),
                  ],
                ),
                const Spacer(),
                Text(
                  secao.titulo,
                  style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: Cores.tinta),
                ),
                const SizedBox(height: 2),
                Text(
                  secao.descricao,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Cores.fundo,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Cores.borda),
      ),
      child: Text(
        texto,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Cores.textoSecundario),
      ),
    );
  }
}
