import 'package:json_dynamic_widget/json_dynamic_widget.dart';

///Class implementing an object special for the plugin, a `WidgetData`.
///It contains of two fields - Map of jsonData to render and a specific for
///`json_dynamic_widget` plugin object - `JsonWidgetRegistry`, which holds all
///the saved widgets and values.
class WidgetData {
  final JsonWidgetRegistry registry;
  final Map<String, dynamic> jsonData;

  WidgetData({required this.registry, required this.jsonData});
}