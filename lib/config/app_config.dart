import 'package:package_info_plus/package_info_plus.dart';

class AppConfig {
  static const String appName = 'Easy BO';
  static const String developer = 'DanielPl_03';
  static const String appDescription = 'Sistema de gestión para tiendas';
  
  static PackageInfo? _packageInfo;
  
  static Future<PackageInfo> get _getPackageInfo async {
    _packageInfo ??= await PackageInfo.fromPlatform();
    return _packageInfo!;
  }

  static Future<String> get appVersion async {
    final packageInfo = await _getPackageInfo;
    return packageInfo.version;
  }

  static Future<String> get buildNumber async {
    final packageInfo = await _getPackageInfo;
    return packageInfo.buildNumber;
  }

  static Future<String> get fullVersion async {
    final version = await appVersion;
    final build = await buildNumber;
    return '$version+$build';
  }

  // Puedes agregar más configuraciones aquí según sea necesario
} 