import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:json_class/json_class.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';

dynamic body({
  required List<dynamic>? args,
  required JsonWidgetRegistry registry,
}) =>
        () {
      if (args != null && args.length == 3) {
        final String buildContextVarName = args[0];
        final String pickedValueVarName = args[1];
        final String dateFormat = args[2];

        final List<String> formatLetters = dateFormat.split("");
        List<String> formatList = [];
        for(int i=0; i<formatLetters.length; i++){
          if(formatLetters[i].compareTo('m') == 0){
            formatList.add(formatLetters[i].toUpperCase());
          }else if(formatLetters[i].compareTo('M') == 0){
            formatList.add(formatLetters[i]);
          }else{
            formatList.add(formatLetters[i].toLowerCase());
          }
        }
        String newFormat = formatList.join();
        final BuildContext context = registry.getValue(buildContextVarName);
        showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1950),
            //DateTime.now() - not to allow to choose before today.
            lastDate: DateTime(2100)).then((value) {
              registry.setValue(pickedValueVarName, DateFormat(newFormat).format(value!).toString());
        });
      }
    };
const String key = 'showDatePicker';

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