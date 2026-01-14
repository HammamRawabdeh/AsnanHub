import 'package:asnan_hub/models/case.dart';

class Casewithuser {
  Case c;
  String phoneNumber;
  String name;

  Casewithuser({
    required this.c,
    required this.phoneNumber,
    required this.name,
  });

  // Getters for easier access
  CaseState get state => c.state;
  DateTime get date => c.date;
}