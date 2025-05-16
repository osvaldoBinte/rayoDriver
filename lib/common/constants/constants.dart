import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String serverBase = dotenv.env['API_BASE'].toString();

  static String apikey = dotenv.env['API_KEY'].toString();


}