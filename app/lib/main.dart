import 'package:flutter/material.dart';

import 'app.dart';
import 'features/auth/data/auth_repositorio_mock.dart';

void main() {
  runApp(MembroPassApp(authRepositorio: AuthRepositorioMock()));
}
