import 'package:flutter_dotenv/flutter_dotenv.dart';

final String OPENAI_API_KEY = dotenv.env['OPENAI_API_KEY'] ?? '';
