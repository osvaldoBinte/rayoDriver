enum Enviroment {
  production,
  testing,
  development,
} 

extension EnviromentValue on Enviroment {
  String get value {
    switch (this) {
      case Enviroment.production:
        return '.env';
      case Enviroment.development:
        return 'dev.env';
      case Enviroment.testing:
        return 'test.env';
      default:
        return '';
    }
  }
}