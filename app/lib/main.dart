import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/cliente_api.dart';
import 'repositorios.dart';

void main() {
  final api = ClienteApi()..acordar();
  runApp(MembroPassApp(repositorios: Repositorios.api(api)));
}
