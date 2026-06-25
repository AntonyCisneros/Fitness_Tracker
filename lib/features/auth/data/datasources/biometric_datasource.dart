import 'package:local_auth/local_auth.dart';
import '../../domain/entities/auth_result.dart';

abstract class BiometricDataSource {
  Future<bool> canAuthenticate();
  Future<AuthResult> authenticate();
}

class BiometricDataSourceImpl implements BiometricDataSource {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics &&
          await _auth.isDeviceSupported();
    } catch (e) {
      print('Error verificando biometría: $e');
      return false;
    }
  }

  @override
  Future<AuthResult> authenticate() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Autentícate para acceder a Fitness Tracker',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      return AuthResult(
        success: authenticated,
        message: authenticated ? 'Autenticación exitosa' : 'Autenticación fallida',
      );
    } catch (e) {
      return AuthResult(success: false, message: 'Error: $e');
    }
  }
}
