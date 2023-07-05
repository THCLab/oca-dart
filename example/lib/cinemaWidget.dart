import 'package:flutter/material.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

class CinemaWidget extends StatefulWidget {
  final Map<String, dynamic> jsonData;
  final JsonWidgetRegistry registry;
  const CinemaWidget({required this.jsonData, required this.registry, Key? key,}) : super(key: key);

  @override
  State<CinemaWidget> createState() => _CinemaWidgetState();
}

class _CinemaWidgetState extends State<CinemaWidget> {
  late var _data;
  late var _registry;

  @override
  void initState() {
    super.initState();
    print(widget.jsonData);
    _registry = widget.registry;
    _data = JsonWidgetData.fromDynamic(widget.jsonData, registry: _registry);
  }

  @override
  Widget build(BuildContext context) {
    var widget = JsonWidgetData.fromDynamic(_data, registry: _registry);
    return widget!.build(context: context);
  }
}
