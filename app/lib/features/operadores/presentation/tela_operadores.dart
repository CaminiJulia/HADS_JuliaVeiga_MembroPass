import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../perfil/presentation/avatar_perfil.dart';
import '../domain/operador.dart';
import 'tela_formulario_operador.dart';

/// Operadores da organização: quem valida o check-in nas unidades e eventos.
/// O administrador cadastra, edita, gera nova senha e desativa o acesso.
class TelaOperadores extends StatefulWidget {
  const TelaOperadores({super.key});

  @override
  State<TelaOperadores> createState() => _TelaOperadoresState();
}

class _TelaOperadoresState extends State<TelaOperadores> {
  List<Operador>? _operadores;
  String? _erro;

  OperadoresRepositorio get _repositorio => context.read<OperadoresRepositorio>();

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final operadores = await _repositorio.listar();
      if (mounted) setState(() => _operadores = operadores);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  Future<void> _novo() async {
    final criado = await Navigator.of(
      context,
    ).push<Object>(MaterialPageRoute(builder: (_) => const TelaFormularioOperador()));
    if (criado is! OperadorCriado || !mounted) return;
    await mostrarSenhaProvisoria(
      context,
      titulo: '${criado.operador.nome} cadastrado',
      mensagem: 'Repasse ao operador o e-mail e a senha provisória para entrar no app:',
      email: criado.operador.email,
      senha: criado.senhaProvisoria,
      emailEnviado: criado.emailEnviado,
    );
    await _carregar();
  }

  Future<void> _editar(Operador operador) async {
    final salvo = await Navigator.of(
      context,
    ).push<Object>(MaterialPageRoute(builder: (_) => TelaFormularioOperador(operador: operador)));
    if (salvo is! Operador || !mounted) return;
    avisar(context, 'Dados de ${salvo.nome} atualizados.');
    await _carregar();
  }

  Future<void> _novaSenha(Operador operador) async {
    final confirmou = await confirmar(
      context,
      titulo: 'Gerar nova senha?',
      mensagem:
          'A senha atual de ${operador.nome} deixa de funcionar. Você vai receber uma senha provisória para repassar.',
      acao: 'Gerar senha',
    );
    if (!confirmou || !mounted) return;
    try {
      final gerada = await _repositorio.novaSenha(operador.id);
      if (!mounted) return;
      await mostrarSenhaProvisoria(
        context,
        titulo: 'Nova senha de ${operador.nome}',
        mensagem: 'Repasse a nova senha provisória ao operador:',
        email: operador.email,
        senha: gerada.senha,
        emailEnviado: gerada.emailEnviado,
      );
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    }
  }

  Future<void> _alterarStatus(Operador operador) async {
    final desativar = operador.ativo;
    final confirmou = await confirmar(
      context,
      titulo: desativar ? 'Desativar ${operador.nome}?' : 'Reativar ${operador.nome}?',
      mensagem: desativar
          ? 'O operador não consegue mais entrar no app. As leituras que ele já fez continuam no histórico.'
          : 'O operador volta a entrar no app com a senha que já tinha.',
      acao: desativar ? 'Desativar' : 'Reativar',
    );
    if (!confirmou || !mounted) return;
    try {
      await _repositorio.alterarStatus(operador.id, ativo: !desativar);
      if (!mounted) return;
      avisar(context, desativar ? '${operador.nome} desativado.' : '${operador.nome} reativado.');
      await _carregar();
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    }
  }

  /// Ações do operador numa folha inferior, para a lista ficar limpa.
  Future<void> _acoes(Operador operador) async {
    final acao = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: AvatarPerfil(iniciais: operador.iniciais, foto: operador.foto),
              title: Text(operador.nome, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(operador.email),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar dados'),
              onTap: () => Navigator.pop(context, 'editar'),
            ),
            ListTile(
              leading: const Icon(Icons.key_outlined),
              title: const Text('Gerar nova senha provisória'),
              subtitle: const Text('Para quando o operador esquecer a senha'),
              onTap: () => Navigator.pop(context, 'senha'),
            ),
            ListTile(
              leading: Icon(
                operador.ativo ? Icons.person_off_outlined : Icons.person_add_alt_outlined,
                color: operador.ativo ? Cores.erro : Cores.sucesso,
              ),
              title: Text(
                operador.ativo ? 'Desativar acesso' : 'Reativar acesso',
                style: TextStyle(color: operador.ativo ? Cores.erro : Cores.sucesso),
              ),
              onTap: () => Navigator.pop(context, 'status'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (acao) {
      case 'editar':
        await _editar(operador);
      case 'senha':
        await _novaSenha(operador);
      case 'status':
        await _alterarStatus(operador);
    }
  }

  @override
  Widget build(BuildContext context) {
    final operadores = _operadores;
    return Scaffold(
      appBar: AppBar(title: const Text('Operadores')),
      floatingActionButton: operadores == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('botao-novo-operador'),
              onPressed: _novo,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Novo operador'),
            ),
      body: _erro != null
          ? AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar)
          : operadores == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  const CaixaInfo(
                    'Operadores entram no app só para validar o check-in das carteirinhas '
                    'nas unidades e eventos. Toque em um operador para ver as opções.',
                  ),
                  const SizedBox(height: 16),
                  if (operadores.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: AvisoTela(
                        icone: Icons.badge_outlined,
                        texto: 'Nenhum operador cadastrado. Toque em "Novo operador" para começar.',
                      ),
                    )
                  else
                    for (final o in operadores) ...[
                      _CartaoOperador(o, aoTocar: () => _acoes(o)),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
    );
  }
}

class _CartaoOperador extends StatelessWidget {
  const _CartaoOperador(this.operador, {required this.aoTocar});

  final Operador operador;
  final VoidCallback aoTocar;

  /// "12 leituras hoje · última às 14:05", ou quando foi a última.
  String get _atividade {
    final ultimo = operador.ultimoCheckin;
    if (ultimo == null) return 'Ainda não fez leituras';
    final hoje = operador.checkinsHoje;
    if (hoje > 0) {
      return '$hoje ${hoje == 1 ? 'leitura' : 'leituras'} hoje · última às ${Datas.hora(ultimo)}';
    }
    return 'Última leitura em ${Datas.formatar(ultimo)}';
  }

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final ativoHoje = operador.ativo && operador.checkinsHoje > 0;
    return CartaoItem(
      aoTocar: aoTocar,
      esmaecido: !operador.ativo,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AvatarPerfil(iniciais: operador.iniciais, foto: operador.foto, tamanho: 48),
                // Ponto verde: fez leituras hoje.
                if (ativoHoje)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Cores.sucesso,
                        shape: BoxShape.circle,
                        border: Border.all(color: Cores.superficie, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          operador.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (!operador.ativo) ...[const SizedBox(width: 8), const Selo('Inativo')],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    operador.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texto.bodySmall?.copyWith(color: Cores.textoSecundario),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.qr_code_scanner, size: 14, color: ativoHoje ? Cores.sucesso : Cores.textoSecundario),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _atividade,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: texto.bodySmall?.copyWith(color: ativoHoje ? Cores.sucesso : Cores.textoSecundario),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.more_vert, color: Cores.textoSecundario),
          ],
        ),
      ),
    );
  }
}
