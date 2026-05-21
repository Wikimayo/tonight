class ApiConfig {
  const ApiConfig._();

  // Para emulador Android usar 10.0.2.2.
  static const String localAndroidEmulatorBaseUrl = 'http://10.0.2.2:3000';

  // Para movil fisico usar la IP local del PC.
  static const String localPhysicalDeviceBaseUrl = 'http://192.168.1.X:3000';

  // Para produccion cambiar productionBaseUrl y useProductionBackend.
  static const String productionBaseUrl =
      'https://tonight-production-2d53.up.railway.app';

  static const bool useProductionBackend = true;

  static String get baseUrl {
    if (useProductionBackend) {
      return productionBaseUrl;
    }

    return localAndroidEmulatorBaseUrl;
  }
}
