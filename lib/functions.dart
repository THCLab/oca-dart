import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:http/http.dart' as http;
import 'package:oca_dart/exceptions.dart';
import 'package:oca_dart/widget_data.dart';
import 'dart:ui';
import 'custom_widgets/date_picker.dart' as show_date_picker_fun;
import 'custom_widgets/time_picker.dart' as show_time_picker_fun;
import 'custom_widgets/file_picker.dart' as show_file_picker_fun;

Future<Map<dynamic, dynamic>> getMapData(String path) async{
  final String mapString = await rootBundle.loadString(path);
  var mapData = await json.decode(mapString);
  return mapData;
}

void parseCells(List cellsList, template, layout){
  try{
    Map<dynamic, dynamic> cells = cellsList[0];
    for(var key in cells.keys){
      List keys = cells[key];
      parseTree(template, keys, keys.length, layout);
    }
  }catch(e){
    if(e.toString().contains('is not a subtype of')){
      throw WrongCellFormatException("One of the cells is unreachable. Check if the value in template overlay is of type List<Int>.");
    }
  }
}

void parseTree(Map<String, dynamic> template, List cell, int cellsLength, List layout){
  if(cellsLength >0){
    var temp = cell[0];
    cell.removeAt(0);
    parseTree(template['children'][temp], cell, cellsLength-1, layout);

  }else{
    for (Map <String, dynamic> element in layout){
      if(element['label'] == template['label']){
        template['args'] = element['args'];
        if(template['children'].length ==0){
          template['children'] = element['children'];
        }
        break;
      }
    }
    template.remove('label');
  }
}

void parseAttributes (JsonWidgetRegistry registry, List attributes){
  try {
    for (Map<String, dynamic> attribute in attributes){
      Map<String, dynamic> labels = attribute["args"]["labels"];
      for (MapEntry<String, dynamic> label in labels.entries) {
        registry.setValue("${attribute["name"]}-${label.key}", label.value);
      }
      registry.setValue("currentLanguage", labels.entries.first.key);
    }
  }catch(e){
    if(e.runtimeType == NoSuchMethodError){
      throw NoLabelException("No field `labels` have been found for one of the attributes. Check and correct the attribute overlay.");
    }
  }
}

Future<Uint8List> getZipFromHttp (String digest) async{
  Map<String,String> headers = {
    'Content-type' : 'application/zip',
    'Accept': 'application/zip',
  };
  String url = "https://repository.oca.argo.colossi.network/api/v0.1/namespaces/b1/schemas/$digest/archive";
  final response = await http.get(Uri.parse(url), headers: headers);
  print(response.statusCode);
  print(response.bodyBytes.length);
  return response.bodyBytes;
}

Widget getWidgetFromJSON (WidgetData data, BuildContext context){
  var widget = JsonWidgetData.fromDynamic(data.jsonData, registry: data.registry);
  return widget!.build(context: context);
}

Future<WidgetData> initialSteps(String path) async{
  WidgetsFlutterBinding.ensureInitialized();
  var registry = JsonWidgetRegistry();
  registry.registerFunction('scaleSize', ({args, required registry}) => args![0].toDouble()/window.devicePixelRatio.toDouble());
  registry.registerFunction('returnLabel', ({args, required registry}) => registry.getValue("${args![0]}-${args[1]}"));
  registry.registerFunctions({
    show_date_picker_fun.key: show_date_picker_fun.body,
    show_time_picker_fun.key: show_time_picker_fun.body,
    show_file_picker_fun.key: show_file_picker_fun.body,
  });
  var layoutData = await getMapData('assets/layout.json');
  var templateData = await getMapData('assets/form_template.json');
  var attributeData = await getMapData('assets/attribute.json');
  var a = templateData['template'][0];
  parseCells(templateData['cells'], a, layoutData['elements']);
  parseAttributes(registry, attributeData['attributes']);
  return(WidgetData(registry: registry, jsonData: a));
}