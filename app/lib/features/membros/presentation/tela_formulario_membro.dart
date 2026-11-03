import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/tema/cores.dart';
import '../../../core/validacao/validadores.dart';
import '../../../core/widgets/componentes.dart';
import '../../auth/presentation/widgets/aviso_erro.dart';
import '../../planos/domain/plano.dart';
import '../../planos/domain/planos_repositorio.dart';
import '../domain/membro.dart';
import '../domain/membros_repositorio.dart';

/// Cadastra um membro novo (fecha devolvendo [MembroCriado]) ou edita [membro]
/// (fecha devolvendo o [Membro] atualizado).
class TelaFormularioMembro extends StatefulWidget {
  const TelaFormularioMembro({super.key, this.membro});

  final Membro? membro;

  @override
  State<TelaFormularioMembro> createState() => _TelaFormularioMembroState();
}

class _TelaFormularioMembroState extends State<TelaFormularioMembro> {
  final _formulario = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.membro?.nome);
  late final _email = TextEditingController(text: widget.membro?.email);
  late final _telefone = TextEditingController(text: widget.membro?.telefone);
  late String? _planoId = widget.membro?.planoId;

  List<Plano>? _planos;
  bool _salvando = false;
  String? _erro;

  bool get _editando => widget.membro != null;

  @override
  void initState() {
    super.initState();
    _carregarPlanos();
  }

  Future<void> _carregarPlanos() async {
    try {
      final planos = await context.read<PlanosRepositorio>().listar();
      // Só planos ativos aceitam membros; o plano atual aparece mesmo se inativo.
      if (mounted) {
        setState(
          () => _planos = [
            for (final p in planos)
              if (p.ativo || p.id == _planoId) p,
          ],
        );
      }
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_salvando || !_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _salvando = true;
      _erro = null;
    });

    final telefone = _telefone.text.trim();
    final dados = DadosMembro(
      nome: _nome.text.trim(),
      email: _email.text.trim().toLowerCase(),
      telefone: telefone.isEmpty ? null : telefone,
      planoId: _planoId!,
    );
    final repositorio = context.read<MembrosRepositorio>();
    try {
      final Object resultado = _editando
          ? await repositorio.editar(widget.membro!.id, dados)
          : await repositorio.criar(dados);
      if (mounted) Navigator.of(context).pop(resultado);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = mensagemDeErro(e);
        _salvando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final planos = _planos;
    final trocouPlano = _editando && _planoId != widget.membro!.planoId;

    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar membro' : 'Novo membro')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_erro != null) ...[AvisoErro(mensagem: _erro!), const SizedBox(height: 16)],
                    TextFormField(
                      key: const Key('campo-nome-membro'),
                      controller: _nome,
                      enabled: !_salvando,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Nome completo',
                        prefixIcon: Icon(Icons.person_outline),
                        counterText: '',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty ? 'Informe o nome do membro.' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo-email-membro'),
                      controller: _email,
                      enabled: !_salvando,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'E-mail',
                        prefixIcon: Icon(Icons.mail_outline),
                        helperText: 'Usado pelo membro para entrar no app.',
                      ),
                      validator: (v) => Validadores.email(v)?.replaceFirst('seu e-mail', 'o e-mail'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('campo-telefone-membro'),
                      controller: _telefone,
                      enabled: !_salvando,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefone (opcional)',
                        prefixIcon: Icon(Icons.phone_outlined),
                        hintText: '(54) 99999-0000',
                      ),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return null;
                        return RegExp(r'^[\d\s()+-]{8,20}$').hasMatch(t) ? null : 'Informe um telefone válido.';
                      },
                    ),
                    const SizedBox(height: 16),
                    if (planos == null)
                      const LinearProgressIndicator()
                    else if (planos.isEmpty)
                      Text(
                        'Nenhum plano ativo. Crie um plano antes de cadastrar membros.',
                        style: texto.bodyMedium?.copyWith(color: Cores.erro),
                      )
                    else
                      DropdownButtonFormField<String>(
                        key: const Key('campo-plano-membro'),
                        initialValue: _planoId,
                        decoration: const InputDecoration(
                          labelText: 'Plano',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                        items: [
                          for (final p in planos)
                            DropdownMenuItem(value: p.id, child: Text(p.ativo ? p.nome : '${p.nome} (inativo)')),
                        ],
                        onChanged: _salvando ? null : (id) => setState(() => _planoId = id),
                        validator: (id) => id == null ? 'Escolha um plano.' : null,
                      ),
                    if (trocouPlano) ...[
                      const SizedBox(height: 8),
                      Text(
                        'O vencimento atual não muda. O novo plano vale a partir da próxima confirmação de pagamento.',
                        style: texto.bodySmall?.copyWith(color: Cores.alerta),
                      ),
                    ],
                    if (!_editando) ...[
                      const SizedBox(height: 16),
                      const CaixaInfo(
                        'A carteirinha é emitida na hora, vencendo após a duração do plano. '
                        'Você verá uma senha provisória para repassar ao membro.',
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      key: const Key('botao-salvar-membro'),
                      onPressed: _salvando || (planos?.isEmpty ?? true) ? null : _salvar,
                      child: _salvando
                          ? const CarregandoBotao()
                          : Text(_editando ? 'Salvar alterações' : 'Cadastrar membro'),
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
