import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/componentes.dart';
import '../domain/registro_auditoria.dart';
import 'item_auditoria.dart';

/// RF16: histórico das ações sensíveis da organização. Somente leitura:
/// o banco não deixa alterar nem apagar registros.
class TelaAuditoria extends StatefulWidget {
  const TelaAuditoria({super.key});

  @override
  State<TelaAuditoria> createState() => _TelaAuditoriaState();
}

class _TelaAuditoriaState extends State<TelaAuditoria> {
  List<RegistroAuditoria>? _registros;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _erro = null);
    try {
      final registros = await context.read<AuditoriaRepositorio>().listar();
      if (mounted) setState(() => _registros = registros);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final registros = _registros;
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico de ações')),
      body: _erro != null
          ? AvisoTela(icone: Icons.cloud_off, texto: _erro!, aoTentarDeNovo: _carregar)
          : registros == null
              ? const Center(child: CircularProgressIndicator())
              : registros.isEmpty
                  ? const AvisoTela(
                      icone: Icons.history,
                      texto: 'Nenhuma ação registrada ainda.\nPagamentos, bloqueios e '
                          'desativações aparecem aqui.',
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: registros.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) => ItemAuditoria(registros[i]),
                      ),
                    ),
    );
  }
}
