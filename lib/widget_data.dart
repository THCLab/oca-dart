import 'package:json_dynamic_widget/json_dynamic_widget.dart';

class WidgetData {
  final JsonWidgetRegistry registry;
  final Map<String, dynamic> jsonData;

  WidgetData({required this.registry, required this.jsonData});
}