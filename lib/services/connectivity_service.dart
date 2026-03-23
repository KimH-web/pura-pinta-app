import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Verifica si hay conexión activa (WiFi o datos móviles)
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    final first = results.isNotEmpty ? results.first : ConnectivityResult.none;
    return first == ConnectivityResult.mobile || first == ConnectivityResult.wifi;
  }

  // Escucha los cambios de conexión en tiempo real
  Stream<bool> get connectionStream async* {
    await for (final results in _connectivity.onConnectivityChanged) {
      final first = results.isNotEmpty ? results.first : ConnectivityResult.none;
      yield first == ConnectivityResult.mobile || first == ConnectivityResult.wifi;
    }
  }
}
