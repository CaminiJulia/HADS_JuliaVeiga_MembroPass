// Endereço da API. O padrão funciona no emulador Android, onde 10.0.2.2 é o
// computador que roda a API. Para outro endereço:
//   flutter run --dart-define=API_URL=http://192.168.0.10:3000/api
const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:3000/api');
