import 'package:dosya_gezgini/data/constants/hive_box_names.dart';
import 'package:dosya_gezgini/data/services/hive_service.dart';

class HiddenPasswordCredentials {
  const HiddenPasswordCredentials({
    required this.passwordHash,
    required this.passwordSalt,
  });

  final String passwordHash;
  final String passwordSalt;
}

class HiddenPasswordRepository {
  HiddenPasswordRepository(this._hiveService);

  static const String _passwordHashKey = 'password_hash';
  static const String _passwordSaltKey = 'password_salt';

  final HiveService _hiveService;

  Future<HiddenPasswordCredentials?> readCredentials() async {
    final box = await _hiveService.openBox(HiveBoxNames.hiddenPasswordSettings);
    final passwordHash = box.get(_passwordHashKey) as String?;
    final passwordSalt = box.get(_passwordSaltKey) as String?;

    if (passwordHash == null || passwordSalt == null) {
      return null;
    }

    return HiddenPasswordCredentials(
      passwordHash: passwordHash,
      passwordSalt: passwordSalt,
    );
  }

  Future<void> saveCredentials(HiddenPasswordCredentials credentials) async {
    final box = await _hiveService.openBox(HiveBoxNames.hiddenPasswordSettings);
    await box.putAll(<String, String>{
      _passwordHashKey: credentials.passwordHash,
      _passwordSaltKey: credentials.passwordSalt,
    });
  }
}
