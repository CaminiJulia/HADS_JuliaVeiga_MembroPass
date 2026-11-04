import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../../auth/presentation/sair.dart';
import '../domain/perfil.dart';
import 'avatar_perfil.dart';

/// Aba "Meu perfil" do administrador: foto, dados de contato, senha e saída.
class TelaPerfil extends StatefulWidget {
  const TelaPerfil({super.key});

  static const tamanhoMaximoFoto = 512 * 1024;

  @override
  State<TelaPerfil> createState() => _TelaPerfilState();
}

class _TelaPerfilState extends State<TelaPerfil> {
  final _formulario = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _cargo = TextEditingController();

  Perfil? _perfil;
  String? _erro;
  bool _salvando = false;

  Uint8List? _foto;
  String? _fotoTipo;
  bool _fotoAlterada = false;

  PerfilRepositorio get _repositorio => context.read<PerfilRepositorio>();

  @override
  void initState() {
    super.initState();
    for (final c in [_nome, _telefone, _cargo]) {
      c.addListener(() => setState(() {}));
    }
    _carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _cargo.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final perfil = await _repositorio.buscar();
      if (mounted) _aplicar(perfil);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  void _aplicar(Perfil perfil) => setState(() {
    _perfil = perfil;
    _nome.text = perfil.nome;
    _telefone.text = perfil.telefone ?? '';
    _cargo.text = perfil.cargo ?? '';
    _foto = perfil.foto;
    _fotoTipo = perfil.fotoTipo;
    _fotoAlterada = false;
  });

  /// Há algo diferente do que está salvo?
  bool get _alterado {
    final p = _perfil;
    if (p == null) return false;
    return _fotoAlterada ||
        _nome.text.trim() != p.nome ||
        _telefone.text.trim() != (p.telefone ?? '') ||
        _cargo.text.trim() != (p.cargo ?? '');
  }

  Future<void> _opcoesFoto() async {
    final escolha = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.pop(context, 'galeria'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Tirar foto'),
              onTap: () => Navigator.pop(context, 'camera'),
            ),
            if (_foto != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Cores.erro),
                title: const Text('Remover foto', style: TextStyle(color: Cores.erro)),
                onTap: () => Navigator.pop(context, 'remover'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    switch (escolha) {
      case 'galeria':
        await _escolherFoto(ImageSource.gallery);
      case 'camera':
        await _escolherFoto(ImageSource.camera);
      case 'remover':
        setState(() {
          _foto = null;
          _fotoTipo = null;
          _fotoAlterada = true;
        });
    }
  }

  Future<void> _escolherFoto(ImageSource origem) async {
    final arquivo = await ImagePicker().pickImage(
      source: origem,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
      preferredCameraDevice: CameraDevice.front,
    );
    if (arquivo == null) return;
    final bytes = await arquivo.readAsBytes();
    if (!mounted) return;
    if (bytes.length > TelaPerfil.tamanhoMaximoFoto) {
      avisar(context, 'A foto pode ter no máximo 512 KB.');
      return;
    }
    setState(() {
      _foto = bytes;
      _fotoTipo = arquivo.name.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      _fotoAlterada = true;
    });
  }

  Future<void> _salvar() async {
    if (!_formulario.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _salvando = true);
    try {
      String? opcional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
      final perfil = await _repositorio.salvar(
        DadosPerfil(
          nome: _nome.text.trim(),
          telefone: opcional(_telefone),
          cargo: opcional(_cargo),
          manterFoto: !_fotoAlterada,
          foto: _foto,
          fotoTipo: _fotoTipo,
        ),
      );
      if (!mounted) return;
      _aplicar(perfil);
      avisar(context, 'Perfil atualizado.');
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _trocarSenha() async {
    final trocou = await showDialog<bool>(context: context, builder: (_) => _DialogoTrocarSenha(_repositorio));
    if (trocou == true && mounted) avisar(context, 'Senha alterada. Use a nova senha no próximo login.');
  }

  Future<void> _sair() async {
    final confirmou = await confirmar(
      context,
      titulo: 'Sair da conta?',
      mensagem: 'Você vai precisar entrar de novo com seu e-mail e senha.',
      acao: 'Sair',
    );
    if (confirmou && mounted) sairDaConta(context);
  }

  @override
  Widget build(BuildContext context) {
    final perfil = _perfil;
    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      // Botão fixo no rodapé: continua visível com o teclado aberto.
      bottomNavigationBar: perfil == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: FilledButton(
                  key: const Key('botao-salvar-perfil'),
                  onPressed: _salvando || !_alterado ? null : _salvar,
                  child: _salvando ? const CarregandoBotao() : const Text('Salvar alterações'),
                ),
              ),
            ),
      body: _erro != null
          ? AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar)
          : perfil == null
          ? const Center(child: CircularProgressIndicator())
          : _conteudo(perfil),
    );
  }

  Widget _conteudo(Perfil perfil) {
    final texto = Theme.of(context).textTheme;
    final nomeAtual = _nome.text.trim().isEmpty ? perfil.nome : _nome.text.trim();
    final cargoAtual = _cargo.text.trim();
    final iniciais = Perfil(id: '', nome: nomeAtual, email: '', organizacaoNome: '').iniciais;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Form(
          key: _formulario,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              // Cabeçalho: foto com botão de câmera, nome e organização.
              Center(
                child: Semantics(
                  button: true,
                  label: _foto == null ? 'Adicionar foto' : 'Trocar foto',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: _salvando ? null : _opcoesFoto,
                    customBorder: const CircleBorder(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Cores.primaria.withValues(alpha: 0.5), width: 2),
                          ),
                          child: AvatarPerfil(iniciais: iniciais, foto: _foto, tamanho: 112),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 2,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Cores.primaria,
                              shape: BoxShape.circle,
                              border: Border.all(color: Cores.fundo, width: 3),
                            ),
                            child: const Icon(Icons.photo_camera, size: 18, color: Cores.noPrimaria),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                nomeAtual,
                textAlign: TextAlign.center,
                style: texto.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                cargoAtual.isEmpty ? perfil.organizacaoNome : '$cargoAtual · ${perfil.organizacaoNome}',
                textAlign: TextAlign.center,
                style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario),
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Cores.primaria.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Cores.primaria.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 16, color: Cores.primaria),
                      const SizedBox(width: 6),
                      Text(
                        'Administrador',
                        style: texto.labelMedium?.copyWith(color: Cores.primaria, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),

              const _TituloSecao('Dados pessoais'),
              TextFormField(
                key: const Key('campo-nome-perfil'),
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
                validator: (v) => (v ?? '').trim().isEmpty ? 'Informe seu nome.' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('campo-cargo-perfil'),
                controller: _cargo,
                enabled: !_salvando,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Cargo ou função (opcional)',
                  hintText: 'Ex.: Coordenação, Secretaria',
                  prefixIcon: Icon(Icons.work_outline),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('campo-telefone-perfil'),
                controller: _telefone,
                enabled: !_salvando,
                keyboardType: TextInputType.phone,
                maxLength: 20,
                decoration: const InputDecoration(
                  labelText: 'Telefone (opcional)',
                  hintText: '(54) 99999-0000',
                  prefixIcon: Icon(Icons.phone_outlined),
                  counterText: '',
                ),
                validator: (v) {
                  final t = (v ?? '').trim();
                  return t.isEmpty || RegExp(r'^[\d\s()+-]{8,20}$').hasMatch(t) ? null : 'Informe um telefone válido.';
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                initialValue: perfil.email,
                enabled: false,
                decoration: const InputDecoration(
                  labelText: 'E-mail de acesso',
                  prefixIcon: Icon(Icons.mail_outline),
                  suffixIcon: Icon(Icons.lock_outline, size: 18),
                  helperText: 'É o e-mail usado para entrar; não pode ser alterado aqui.',
                ),
              ),

              const _TituloSecao('Segurança'),
              CartaoItem(
                aoTocar: _salvando ? null : _trocarSenha,
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
                        child: const Icon(Icons.key_outlined, color: Cores.primaria, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Alterar senha', style: texto.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text('Confirme a senha atual e escolha uma nova', style: texto.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Cores.textoSecundario),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              OutlinedButton.icon(
                key: const Key('botao-sair-perfil'),
                onPressed: _salvando ? null : _sair,
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
    );
  }
}

/// Troca de senha: pede a atual e a nova duas vezes. Fecha com `true` se trocou.
class _DialogoTrocarSenha extends StatefulWidget {
  const _DialogoTrocarSenha(this.repositorio);

  final PerfilRepositorio repositorio;

  @override
  State<_DialogoTrocarSenha> createState() => _DialogoTrocarSenhaState();
}

class _DialogoTrocarSenhaState extends State<_DialogoTrocarSenha> {
  final _formulario = GlobalKey<FormState>();
  final _atual = TextEditingController();
  final _nova = TextEditingController();
  final _confirmacao = TextEditingController();
  bool _mostrar = false;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _atual.dispose();
    _nova.dispose();
    _confirmacao.dispose();
    super.dispose();
  }

  /// Mesmas regras da API: 8+ caracteres, com letras e números.
  static String? _validarNova(String? v) {
    final s = v ?? '';
    if (s.length < 8) return 'Use pelo menos 8 caracteres.';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) return 'Use letras e números.';
    return null;
  }

  Future<void> _enviar() async {
    setState(() => _erro = null);
    if (!_formulario.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await widget.repositorio.trocarSenha(senhaAtual: _atual.text, novaSenha: _nova.text);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration decoracao(String rotulo) => InputDecoration(
      labelText: rotulo,
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        tooltip: _mostrar ? 'Ocultar senhas' : 'Mostrar senhas',
        icon: Icon(_mostrar ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        onPressed: () => setState(() => _mostrar = !_mostrar),
      ),
    );

    return AlertDialog(
      title: const Text('Alterar senha'),
      content: SingleChildScrollView(
        child: Form(
          key: _formulario,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('campo-senha-atual'),
                controller: _atual,
                obscureText: !_mostrar,
                enabled: !_enviando,
                textInputAction: TextInputAction.next,
                decoration: decoracao('Senha atual'),
                validator: (v) => (v ?? '').isEmpty ? 'Informe sua senha atual.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo-nova-senha'),
                controller: _nova,
                obscureText: !_mostrar,
                enabled: !_enviando,
                textInputAction: TextInputAction.next,
                decoration: decoracao(
                  'Nova senha',
                ).copyWith(helperText: 'Mínimo de 8 caracteres, com letras e números.'),
                validator: _validarNova,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('campo-confirmar-senha'),
                controller: _confirmacao,
                obscureText: !_mostrar,
                enabled: !_enviando,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _enviar(),
                decoration: decoracao('Repita a nova senha'),
                validator: (v) => v != _nova.text ? 'As senhas não conferem.' : null,
              ),
              if (_erro != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Cores.erroFundo, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Cores.erro, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _erro!,
                          key: const Key('erro-trocar-senha'),
                          style: const TextStyle(color: Cores.erro, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _enviando ? null : () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(
          key: const Key('botao-trocar-senha'),
          onPressed: _enviando ? null : _enviar,
          child: _enviando ? const CarregandoBotao() : const Text('Alterar'),
        ),
      ],
    );
  }
}

/// Título de seção em caixa alta.
class _TituloSecao extends StatelessWidget {
  const _TituloSecao(this.texto);

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
