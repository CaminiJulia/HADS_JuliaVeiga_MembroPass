import 'package:flutter/material.dart';

import 'app.dart';
import 'core/api/cliente_api.dart';
import 'repositorios.dart';

void main() {
  runApp(MembroPassApp(repositorios: Repositorios.api(ClienteApi())));
}
