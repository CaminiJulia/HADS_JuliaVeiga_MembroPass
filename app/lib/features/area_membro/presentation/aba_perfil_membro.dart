import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../domain/carteirinha_membro.dart';
import 'campos_membro.dart';

/// Aba "Meu perfil" do membro: troca a foto e mantém celular e endereço em dia.
/// Nome e nascimento aparecem travados: foram declarados no primeiro acesso
/// e só a administração corrige.
class AbaPerfilMembro extends StatefulWidget {
  const AbaPerfilMembro({super.key, required this.aoSalvar, required this.aoSair});

  /// Avisa a área do membro, para a carteirinha mostrar a foto nova.
  final ValueChanged<CadastroMembro> aoSalvar;
  final VoidCallback aoSair;

  @override
  State<AbaPerfilMembro> createState() => _AbaPerfilMembroState();
}

class _AbaPerfilMembroState extends State<AbaPerfilMembro> {
  final _formulario = GlobalKey<FormState>();
  final _telefone = TextEditingController();
  ControlesEndereco _endereco = ControlesEndereco();

  CadastroMembro? _cadastro;
  String? _erro;
  bool _salvando = false;

  Uint8List? _foto;
  String? _fotoTipo;
  bool _fotoNova = false;

  @override
  void initState() {
    super.initState();
    _telefone.addListener(_atualizar);
    _carregar();
  }

  @override
  void dispose() {
    _telefone.dispose();
    _endereco.dispose();
    super.dispose();
  }

  void _atualizar() => setState(() {});

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final cadastro = await context.read<AreaMembroRepositorio>().cadastro();
      if (mounted) _aplicar(cadastro);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  void _aplicar(CadastroMembro c) {
    final antigo = _endereco;
    _endereco = ControlesEndereco(c.endereco);
    for (final campo in _endereco.campos) {
      campo.addListener(_atualizar);
    }
    // Descarta os controles antigos só depois de a tela trocar para os novos.
    WidgetsBinding.instance.addPostFrameCallback((_) => antigo.dispose());
    setState(() {
      _cadastro = c;
      _telefone.text = c.telefone ?? '';
      _foto = c.foto;
      _fotoTipo = null;
      _fotoNova = false;
    });
  }

  bool get _alterado {
    final c = _cadastro;
    if (c == null) return false;
    return _fotoNova || _telefone.text.trim() != (c.telefone ?? '') || _endereco.diferenteDe(c.endereco);
  }

  Future<void> _trocarFoto() async {
    final escolhida = await escolherFotoMembro(context);
    if (escolhida == null || !mounted) return;
    setState(() {
      _foto = escolhida.bytes;
      _fotoTipo = escolhida.tipo;
      _fotoNova = true;
    });
  }

  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) {
      avisar(context, 'Confira os campos destacados.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);
    try {
      final cadastro = await context.read<AreaMembroRepositorio>().atualizarPerfil(
        DadosPerfilMembro(
          telefone: _telefone.text.trim(),
          endereco: _endereco.paraEndereco(),
          foto: _fotoNova ? _foto : null,
          fotoTipo: _fotoNova ? _fotoTipo : null,
        ),
      );
      if (!mounted) return;
      _aplicar(cadastro);
      widget.aoSalvar(cadastro);
      avisar(context, 'Perfil atualizado.');
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _cadastro;
    if (_erro != null) return AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar);
    if (c == null) return const Center(child: CircularProgressIndicator());
    final texto = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formulario,
                child: ListView(
                  key: const Key('lista-perfil-membro'),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Center(
                      child: FotoMembroEditavel(
                        key: const Key('foto-perfil-membro'),
                        nome: c.nome,
                        foto: _foto,
                        aoTocar: _salvando ? null : _trocarFoto,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      c.nome,
                      textAlign: TextAlign.center,
                      style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      c.email,
                      textAlign: TextAlign.center,
                      style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
                    ),
                    if (_fotoNova) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Foto nova escolhida. Toque em "Salvar alterações" para usar na carteirinha.',
                        textAlign: TextAlign.center,
                        style: texto.bodySmall?.copyWith(color: Cores.primaria),
                      ),
                    ],

                    const TituloSecaoMembro('Dados pessoais'),
                    Container(
                      decoration: BoxDecoration(
                        color: Cores.superficie,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Cores.borda),
                      ),
                      child: Column(
                        children: [
                          _ItemTravado(icone: Icons.person_outline, rotulo: 'Nome completo', valor: c.nome),
                          const Divider(height: 1, indent: 52),
                          _ItemTravado(
                            icone: Icons.cake_outlined,
                            rotulo: 'Data de nascimento',
                            valor: c.dataNascimento == null ? 'Não informada' : Datas.formatar(c.dataNascimento!),
                          ),
                          const Divider(height: 1, indent: 52),
                          _ItemTravado(icone: Icons.mail_outline, rotulo: 'E-mail de acesso', valor: c.email),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Para corrigir nome, nascimento ou e-mail, fale com a administração do clube.',
                        style: texto.bodySmall,
                      ),
                    ),

                    const TituloSecaoMembro('Contato'),
                    CampoCelular(chave: const Key('campo-celular-perfil'), controle: _telefone, habilitado: !_salvando),

                    const TituloSecaoMembro('Endereço'),
                    CamposEndereco(
                      // Recria os campos quando o endereço é recarregado do servidor.
                      key: ObjectKey(_endereco),
                      controles: _endereco,
                      habilitado: !_salvando,
                      aoMudarUf: (uf) => setState(() => _endereco.uf = uf),
                    ),

                    const SizedBox(height: 28),
                    OutlinedButton.icon(
                      key: const Key('botao-sair-perfil-membro'),
                      onPressed: _salvando ? null : widget.aoSair,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Cores.erro,
                        side: BorderSide(color: Cores.erro.withValues(alpha: 0.5)),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair da conta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Botão fixo embaixo: aparece só quando há algo para salvar.
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: _alterado || _salvando
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                  decoration: const BoxDecoration(
                    color: Cores.fundo,
                    border: Border(top: BorderSide(color: Cores.borda)),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          key: const Key('botao-salvar-perfil-membro'),
                          onPressed: _salvando ? null : _salvar,
                          child: _salvando ? const CarregandoBotao() : const Text('Salvar alterações'),
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Linha de dado que o membro não edita, com cadeado.
class _ItemTravado extends StatelessWidget {
  const _ItemTravado({required this.icone, required this.rotulo, required this.valor});

  final IconData icone;
  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      child: Row(
        children: [
          Icon(icone, size: 20, color: Cores.textoSecundario),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rotulo, style: texto.labelSmall?.copyWith(color: Cores.textoSecundario)),
                const SizedBox(height: 2),
                Text(valor, style: texto.bodyLarge),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: Cores.textoSecundario),
        ],
      ),
    );
  }
}
