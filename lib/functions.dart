import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:form_validation/form_validation.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:http/http.dart' as http;
import 'package:oca_dart/exceptions.dart';
import 'package:oca_dart/widget_data.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'custom_validators/regex_validator.dart';
import 'custom_widgets/date_picker.dart' as show_date_picker_fun;
import 'custom_widgets/slider_builder.dart';
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
    }else if(e.toString().contains('Only valid value is')){
      throw CellPathException('The path to one of the widget in `cells` is incorrect. Check the template overlay for the mistake.');
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

void parseForm(dynamic layout, Map<dynamic, dynamic> formatOverlay){
  for (Map <String, dynamic> element in layout){
    if(element['children'] != null){
      for(int i=0; i<element['children'].length; i++){
        //print(element['children'][i]['type']);
        if(element['children'][i]['id'] != null){
          for(var key in formatOverlay['attribute_formats'].keys){
            if(element['children'][i]['id'] == "edit${toBeginningOfSentenceCase(key)}"){
              element['children'][i]['validators'] = json.encode([{
                "type": "regex",
                "regex" : formatOverlay['attribute_formats'][key]
              }]);
            }
          }
          //print(element['children'][i]['id']);
          //print(element['children'][i]['validators']);
        }
        parseForm(element['children'], formatOverlay);
      }
    }
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
  if(response.statusCode == 200){
    return response.bodyBytes;
  }else{
    throw ServiceUnreachableException("Couldn't download OCA zip file. Check your digest or internet connection.");
  }

}

Widget getWidgetFromJSON (WidgetData data, BuildContext context){
  var widget = JsonWidgetData.fromDynamic(data.jsonData, registry: data.registry);
  return widget!.build(context: context);
}

Future<WidgetData> initialSteps(String path) async{
  WidgetsFlutterBinding.ensureInitialized();
  var registry = JsonWidgetRegistry();
  var navigatorKey = GlobalKey<NavigatorState>();
  registry.registerFunction('scaleSize', ({args, required registry}) => args![0].toDouble()/window.devicePixelRatio.toDouble());
  registry.registerFunction('returnLabel', ({args, required registry}) => registry.getValue("${args![0]}-${args[1]}"));
  registry.registerFunctions({
    show_date_picker_fun.key: show_date_picker_fun.body,
    show_time_picker_fun.key: show_time_picker_fun.body,
    show_file_picker_fun.key: show_file_picker_fun.body,
    'validateForm': ({args, required registry}) => () {
      print(registry.values);
      final BuildContext context = registry.getValue(args![0]);
      final valid = Form.of(context).validate();
      registry.setValue('form_validation', valid);
    },
    'validateFormAndNavigate': ({args, required registry}) => () {
      final BuildContext context = registry.getValue(args![0]);
      final valid = Form.of(context).validate();
      registry.setValue('form_validation', valid);
      if(valid){
        registry.navigatorKey?.currentState!.pushNamed(args[1]);
      }
    }
  });
  Validator.registerCustomValidatorBuilder(
    RegexValidator.type,
    RegexValidator.fromDynamic,
  );
  registry.registerCustomBuilder(
    CustomSlider.type,
    JsonWidgetBuilderContainer(
      builder: CustomSlider.fromDynamic,
    ),
  );
  var layoutData = await getMapData('assets/layout.json');
  var templateData = await getMapData('assets/form_template.json');
  var attributeData = await getMapData('assets/attribute.json');
  var formatData = await getMapData('assets/format.json');
  var a = templateData['template'][0];
  parseForm(layoutData['elements'], formatData);
  parseCells(templateData['cells'], a, layoutData['elements']);
  parseAttributes(registry, attributeData['attributes']);
  print(a);
  return(WidgetData(registry: registry, jsonData: a));
}

bool isValid(String regex, String entry) {
  final regExp = RegExp(regex);
  return regExp.hasMatch(entry);
}