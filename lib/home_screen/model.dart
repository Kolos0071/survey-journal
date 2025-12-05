import 'package:flutter/material.dart';

class FormViewModel {
  final String label;
  final TextEditingController controller;
  final TextInputType type;
  final bool isRequired;

  FormViewModel(
      {required this.label,
      required this.controller,
      required this.type,
      this.isRequired = false});
}
