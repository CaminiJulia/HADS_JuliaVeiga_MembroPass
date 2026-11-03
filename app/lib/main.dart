import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/cliente_api.dart';
import 'features/auth/data/auth_repositorio_api.dart';
import 'features/planos/data/planos_repositorio_api.dart';

void main() {
  final api = ClienteApi();
  runApp(MembroPassApp(
    authRepositorio: AuthRepositorioApi(api),
    planosRepositorio: PlanosRepositorioApi(api),
  ));
}
