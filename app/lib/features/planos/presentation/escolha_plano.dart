import 'package:flutter/material.dart';

import '../../../core/formatacao/moeda.dart';
import '../../../core/tema/cores.dart';
import '../domain/plano.dart';
import 'cor_plano.dart';

/// Escolha de um único plano em cartões (cor, nome, valor e duração), com
/// validação de formulário. Substitui a lista suspensa, que escondia o valor
/// e a duração de cada plano.
class EscolhaPlano extends FormField<String> {
  EscolhaPlano({
    super.key,
    required List<Plano> planos,
    required String? selecionado,
    required ValueChanged<String> aoEscolher,
    bool habilitado = true,
  }) : super(
         initialValue: selecionado,
         validator: (id) => id == null ? 'Escolha um plano.' : null,
         builder: (campo) {
           final texto = Theme.of(campo.context).textTheme;
           return Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               Padding(
                 padding: const EdgeInsets.only(left: 4, bottom: 8),
                 child: Text('Plano', style: texto.labelLarge?.copyWith(color: Cores.textoSecundario)),
               ),
               for (final plano in planos)
                 Padding(
                   padding: const EdgeInsets.only(bottom: 8),
                   child: _OpcaoPlano(
                     plano: plano,
                     marcado: campo.value == plano.id,
                     aoTocar: habilitado
                         ? () {
                             campo.didChange(plano.id);
                             aoEscolher(plano.id);
                           }
                         : null,
                   ),
                 ),
               if (campo.hasError)
                 Padding(
                   padding: const EdgeInsets.only(left: 12),
                   child: Text(campo.errorText!, style: texto.bodySmall?.copyWith(color: Cores.erro)),
                 ),
             ],
           );
         },
       );
}

class _OpcaoPlano extends StatelessWidget {
  const _OpcaoPlano({required this.plano, required this.marcado, required this.aoTocar});

  final Plano plano;
  final bool marcado;
  final VoidCallback? aoTocar;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final cor = corDoPlano(plano.cor);
    final duracao = plano.duracaoDias == 1 ? '1 dia' : '${plano.duracaoDias} dias';

    return Semantics(
      selected: marcado,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: marcado ? cor.withValues(alpha: 0.14) : Cores.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: marcado ? cor : Cores.borda, width: marcado ? 2 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: Key('opcao-plano-${plano.id}'),
            borderRadius: BorderRadius.circular(14),
            onTap: aoTocar,
            child: Padding(
              padding: EdgeInsets.all(marcado ? 13 : 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: degradeDoPlano(plano.cor),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.workspace_premium_outlined, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plano.ativo ? plano.nome : '${plano.nome} (inativo)',
                          overflow: TextOverflow.ellipsis,
                          style: texto.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${Moeda.formatar(plano.valorReferencia)} · $duracao',
                          style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    marcado ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: marcado ? cor : Cores.textoSecundario,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
