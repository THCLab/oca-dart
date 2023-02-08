import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:json_class/json_class.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

dynamic body({
  required List<dynamic>? args,
  required JsonWidgetRegistry registry,
}) =>
        () {
      if (args != null && args.length == 1) {
        final String buildContextVarName = args[0];

        final BuildContext context = registry.getValue(buildContextVarName);
        FilePicker.platform.pickFiles().then((value) {
              registry.setValue('pickedFile', value?.files.single.name.toString());
              registry.setValue('pickedFilePath', value?.files.single.path.toString());
        });
      }
    };
const String key = 'showFilePicker';

class ActionData extends JsonClass {
  ActionData({
    required this.title,
    required this.onPressed,
  });
  factory ActionData.fromJson(dynamic json) {
    return ActionData(
      title: Map<String, dynamic>.from(
        json['title'],
      ),
      onPressed: json['onPressed'],
    );
  }

  Map<String, dynamic> title;

  Function onPressed;

  @override
  Map<String, dynamic> toJson() {
    return {'title': title, 'onPressed': onPressed};
  }
}

class DialogData extends JsonClass {
  DialogData({
    required this.title,
    required this.content,
    required this.actions,
  });

  factory DialogData.fromJson(dynamic json) {
    return DialogData(
      title: Map<String, dynamic>.from(
        json['title'],
      ),
      content: Map<String, dynamic>.from(
        json['content'],
      ),
      actions: List.from(
        json['actions'],
      ).map(
            (actionJson) => ActionData.fromJson(actionJson),
      ),
    );
  }

  Map<String, dynamic> title;

  Map<String, dynamic> content;

  Iterable<ActionData> actions;

  @override
  Map<String, dynamic> toJson() {
    return {'title': title, 'content': content};
  }
}