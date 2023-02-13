import 'package:child_builder/child_builder.dart';
import 'package:flutter/material.dart';
import 'package:json_class/json_class.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:json_theme/json_theme.dart';
import 'package:meta/meta.dart';

class CustomSlider extends JsonWidgetBuilder {
  CustomSlider({
    this.activeColor,
    required this.min,
    required this.max,
    required this.value,
    this.onChanged,
    this.label,
  }) : super(numSupportedChildren: kNumSupportedChildren);

  static const type = 'slider';
  static const kNumSupportedChildren = -1;

  final double min;
  final double max;
  final double value;
  final Color? activeColor;
  final String? label;
  final ValueChanged<double>? onChanged;

  static CustomSlider fromDynamic(
      dynamic map, {
        JsonWidgetRegistry? registry,
      }) {
    CustomSlider result;
    result = CustomSlider(
      activeColor: ThemeDecoder.decodeColor(
        map['activeColor'],
        validate: false,
      ),
      min: JsonClass.parseDouble(map['min']) ?? 0.0,
      max: JsonClass.parseDouble(map['max']) ?? 1.0,
      value: JsonClass.parseDouble(map['value']) ?? 0.5,
      onChanged: map['onPressed'],
      label: map['label'],
    );
    return result;
  }

  @override
  Widget buildCustom({
    ChildWidgetBuilder? childBuilder,
    BuildContext? context,
    JsonWidgetData? data,
    Key? key,
  }) {
    assert(
    data?.children?.isNotEmpty != true,
    '[Slider] does not support children.',
    );
    return FormField<double>(
      key: key,
      builder: (FormFieldState state) => MergeSemantics(
        child: Semantics(
          label: label ?? '',
          child: Slider(
              activeColor: activeColor,
              min: min,
              max: max,
              value: data?.registry.getValue(data.id) ?? (max-min)/2,
              onChanged: (double value) {
                state.didChange(value);
                if (data?.id.isNotEmpty == true) {
                  data?.registry.setValue(
                    data.id,
                    value,
                    originator: data.id,
                  );
                }
                state.setState(() {

                });
                print(value);
              },
            onChangeStart: (double value) {
              state.didChange(value);
              if (data?.id.isNotEmpty == true) {
                data?.registry.setValue(
                  data.id,
                  value,
                  originator: data.id,
                );
              }

            },
            onChangeEnd: (double value) {
              state.didChange(value);
              if (data?.id.isNotEmpty == true) {
                data?.registry.setValue(
                  data.id,
                  value,
                  originator: data.id,
                );
              }
            },
            )
        ),
      ),
    );
  }
}