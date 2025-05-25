import 'package:uuid/uuid.dart';

class UUIDGenerator {
  static final Uuid _uuid = const Uuid();
  
  static String generate() {
    return _uuid.v4();
  }
}