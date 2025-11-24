enum Flavor {
  development,
  staging,
  production,
}

class FlavorConfig {
  final Flavor flavor;
  final String name;
  final String apiBaseUrl;

  FlavorConfig({
    required this.flavor,
    required this.name,
    required this.apiBaseUrl,
  });

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    return _instance ??= FlavorConfig(
      flavor: Flavor.development,
      name: 'Development',
      apiBaseUrl: 'https://dev-api.aurasphere.app',
    );
  }

  static void setFlavor(FlavorConfig config) {
    _instance = config;
  }
}
