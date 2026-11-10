import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/formatacao/datas.dart';
import '../../../core/tema/cores.dart';
import '../../../core/widgets/componentes.dart';
import '../domain/carteirinha_membro.dart';
import 'campos_membro.dart';

/// Primeiro acesso do membro: antes de ver a carteirinha, ele confere o nome,
/// preenche celular, nascimento e endereço, escolhe a foto e declara que as
/// informações são verdadeiras.
class TelaPrimeiroAcesso extends StatefulWidget {
  const TelaPrimeiroAcesso({
    super.key,
    required this.cadastro,
    required this.aoConcluir,
    required this.aoSair,
    this.aoAdiar,
  });

  final CadastroMembro cadastro;
  final ValueChanged<CadastroMembro> aoConcluir;
  final VoidCallback aoSair;

  /// Pula o formulário por agora; `null` quando o cadastro é obrigatório.
  final VoidCallback? aoAdiar;

  /// Por enquanto o cadastro é opcional (facilita os testes): aparece o botão
  /// "Preencher depois". Com `true`, a carteirinha só abre após o cadastro.
  static const obrigatorio = false;

  @override
  State<TelaPrimeiroAcesso> createState() => _TelaPrimeiroAcessoState();
}

class _TelaPrimeiroAcessoState extends State<TelaPrimeiroAcesso> {
  final _formulario = GlobalKey<FormState>();
  late final _nome = TextEditingController(text: widget.cadastro.nome);
  late final _telefone = TextEditingController(text: widget.cadastro.telefone ?? '');
  late final _nascimento = TextEditingController(
    text: widget.cadastro.dataNascimento == null ? '' : Datas.formatar(widget.cadastro.dataNascimento!),
  );
  late final _endereco = ControlesEndereco(widget.cadastro.endereco);

  late Uint8List? _foto = widget.cadastro.foto;
  String? _fotoTipo;
  bool _fotoNova = false;

  bool _declarou = false;
  bool _tentouEnviar = false;
  bool _enviando = false;

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _nascimento.dispose();
    _endereco.dispose();
    super.dispose();
  }

  Future<void> _escolherFoto() async {
    final escolhida = await escolherFotoMembro(context);
    if (escolhida == null || !mounted) return;
    setState(() {
      _foto = escolhida.bytes;
      _fotoTipo = escolhida.tipo;
      _fotoNova = true;
    });
  }

  /// "25/12/1990" → DateTime, ou `null` se não for uma data de nascimento possível.
  static DateTime? _lerNascimento(String texto) {
    final partes = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(texto.trim());
    if (partes == null) return null;
    final dia = int.parse(partes[1]!);
    final mes = int.parse(partes[2]!);
    final ano = int.parse(partes[3]!);
    final data = DateTime(ano, mes, dia);
    // DateTime corrige 31/02 para março; aqui isso é data inválida.
    if (data.day != dia || data.month != mes) return null;
    if (ano < 1900 || !data.isBefore(Datas.hoje())) return null;
    return data;
  }

  Future<void> _concluir() async {
    setState(() => _tentouEnviar = true);
    final valido = _formulario.currentState!.validate();
    if (!valido || _foto == null) {
      avisar(
        context,
        _foto == null && valido ? 'Escolha uma foto para a carteirinha.' : 'Confira os campos destacados.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _enviando = true);
    try {
      final cadastro = await context.read<AreaMembroRepositorio>().completarCadastro(
        DadosCadastroMembro(
          nome: _nome.text.trim(),
          telefone: _telefone.text.trim(),
          dataNascimento: _lerNascimento(_nascimento.text)!,
          endereco: _endereco.paraEndereco(),
          foto: _fotoNova ? _foto : null,
          fotoTipo: _fotoNova ? _fotoTipo : null,
        ),
      );
      if (!mounted) return;
      avisar(context, 'Cadastro concluído. Esta é a sua carteirinha!');
      widget.aoConcluir(cadastro);
    } catch (e) {
      if (mounted) avisar(context, mensagemDeErro(e));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete seu cadastro'),
        automaticallyImplyLeading: false,
        actions: [IconButton(tooltip: 'Sair', icon: const Icon(Icons.logout), onPressed: widget.aoSair)],
      ),
      // Botão fixo no rodapé: continua visível com o teclado aberto.
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                key: const Key('botao-concluir-cadastro'),
                onPressed: _enviando || !_declarou ? null : _concluir,
                child: _enviando ? const CarregandoBotao() : const Text('Concluir cadastro'),
              ),
              if (widget.aoAdiar != null) ...[
                const SizedBox(height: 4),
                TextButton(
                  key: const Key('botao-preencher-depois'),
                  onPressed: _enviando ? null : widget.aoAdiar,
                  child: const Text('Preencher depois'),
                ),
              ],
            ],
          ),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formulario,
            autovalidateMode: _tentouEnviar ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: _conteudo(context)),
          ),
        ),
      ),
    );
  }

  List<Widget> _conteudo(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    final primeiroNome = widget.cadastro.nome.trim().split(RegExp(r'\s+')).first;
    final semFoto = _tentouEnviar && _foto == null;

    return [
      Text('Olá, $primeiroNome!', style: texto.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      Text(
        'Antes de usar a carteirinha, confira e complete seus dados. É rápido e só precisa ser feito uma vez.',
        style: texto.bodyMedium?.copyWith(color: Cores.textoSecundario, height: 1.4),
      ),
      const SizedBox(height: 16),
      const _AvisoVeracidade(),

      const TituloSecaoMembro('Foto da carteirinha'),
      Center(
        child: FotoMembroEditavel(
          key: const Key('foto-primeiro-acesso'),
          nome: _nome.text,
          foto: _foto,
          erro: semFoto,
          aoTocar: _enviando ? null : _escolherFoto,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        semFoto
            ? 'Escolha uma foto para a carteirinha.'
            : 'Foto recente, de frente, com o rosto visível (sem boné ou óculos escuros).',
        textAlign: TextAlign.center,
        style: texto.bodySmall?.copyWith(color: semFoto ? Cores.erro : Cores.textoSecundario),
      ),

      const TituloSecaoMembro('Dados pessoais'),
      TextFormField(
        key: const Key('campo-nome-cadastro'),
        controller: _nome,
        enabled: !_enviando,
        onChanged: (_) => setState(() {}),
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        maxLength: 150,
        decoration: const InputDecoration(
          labelText: 'Nome completo',
          prefixIcon: Icon(Icons.person_outline),
          helperText: 'Confira se está igual ao seu documento.',
          counterText: '',
        ),
        validator: (v) => (v ?? '').trim().isEmpty ? 'Informe seu nome.' : null,
      ),
      const SizedBox(height: 14),
      TextFormField(
        initialValue: widget.cadastro.email,
        enabled: false,
        decoration: const InputDecoration(
          labelText: 'E-mail de acesso',
          prefixIcon: Icon(Icons.mail_outline),
          suffixIcon: Icon(Icons.lock_outline, size: 18),
        ),
      ),
      const SizedBox(height: 14),
      CampoCelular(chave: const Key('campo-celular-cadastro'), controle: _telefone, habilitado: !_enviando),
      const SizedBox(height: 14),
      TextFormField(
        key: const Key('campo-nascimento-cadastro'),
        controller: _nascimento,
        enabled: !_enviando,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        inputFormatters: [Mascara.data],
        decoration: const InputDecoration(
          labelText: 'Data de nascimento',
          hintText: 'DD/MM/AAAA',
          prefixIcon: Icon(Icons.cake_outlined),
        ),
        validator: (v) => _lerNascimento(v ?? '') == null ? 'Informe uma data válida (DD/MM/AAAA).' : null,
      ),

      const TituloSecaoMembro('Endereço'),
      CamposEndereco(
        controles: _endereco,
        habilitado: !_enviando,
        aoMudarUf: (uf) => setState(() => _endereco.uf = uf),
      ),

      const SizedBox(height: 24),
      Container(
        decoration: BoxDecoration(
          color: Cores.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _declarou ? Cores.primaria.withValues(alpha: 0.6) : Cores.borda),
        ),
        child: CheckboxListTile(
          key: const Key('declaracao-veracidade'),
          value: _declarou,
          onChanged: _enviando ? null : (v) => setState(() => _declarou = v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            'Declaro que as informações acima são verdadeiras e estou ciente de que dados falsos podem levar à minha expulsão.',
            style: texto.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ),
    ];
  }
}

/// Aviso em destaque: os dados precisam ser verdadeiros, sob risco de expulsão.
class _AvisoVeracidade extends StatelessWidget {
  const _AvisoVeracidade();

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Container(
      key: const Key('aviso-veracidade'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Cores.alertaFundo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Cores.alerta.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Cores.alerta),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'As informações devem ser verdadeiras',
                  style: texto.titleSmall?.copyWith(color: Cores.alerta, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'A associação confere estes dados. Se alguma informação for falsa, '
                  'você corre o risco de ser expulso(a) e perder a carteirinha.',
                  style: texto.bodySmall?.copyWith(color: Cores.tinta, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
