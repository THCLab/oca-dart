import 'package:form_validation/form_validation.dart';
import 'package:flutter/material.dart';
import 'package:json_class/json_class.dart';
import 'package:static_translations/static_translations.dart';

class RegexValidator extends ValueValidator {
  static const type = 'regex';
  final String regex;

  RegexValidator({
    required this.regex
  }) : assert(regex.isNotEmpty);

  static RegexValidator fromDynamic(dynamic map) {
    RegexValidator result;

    if (map != null) {
      assert(map['type'] == type);

      result = RegexValidator(
        regex: map['regex'] ?? ''
      );
    }else{
      throw Exception("map is null");
    }

    return result;
  }

  Map<String, dynamic> toJson() => {
    // add additional attributes here
    "type": type,
    "regex": regex,
  };

  @override
  String? validate({
    required String label,
    required Translator translator,
    required String? value,
  }) {
    String? error;

    // In general, validators should pass if the value is empty.  Combine
    // validators with the RequiredValidator to ensure a value is non-empty.
    if (value?.isNotEmpty == true) {
      final regExp = RegExp(regex);
      if (!regExp.hasMatch(value ?? '')) {
        error = "Invalid Regex";
      }
    }

    return error;
  }
}