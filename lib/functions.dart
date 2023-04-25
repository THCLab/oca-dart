import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:form_validation/form_validation.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:http/http.dart' as http;
import 'package:oca_dart/bridge_generated.dart';
import 'package:oca_dart/exceptions.dart';
import 'package:oca_dart/widget_data.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'custom_validators/regex_validator.dart';
import 'custom_widgets/date_picker.dart' as show_date_picker_fun;
import 'custom_widgets/slider_builder.dart';
import 'custom_widgets/time_picker.dart' as show_time_picker_fun;
import 'custom_widgets/file_picker.dart' as show_file_picker_fun;
import 'my_custom_validator.dart';
import 'oca_dart.dart';

Map<String, dynamic> obtainedValues = {};
StreamController<bool> controller = StreamController<bool>();
Stream stream = controller.stream;


Future<Map<dynamic, dynamic>> getMapData(String path) async{
  final String mapString = await rootBundle.loadString(path);
  var mapData = await json.decode(mapString);
  return mapData;
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

Future<Uint8List> getJsonFromHttp (String url) async{
  Map<String,String> headers = {
    'Content-type' : 'application/json',
    'Accept': 'application/json',
  };
  final response = await http.get(Uri.parse(url), headers: headers);
  print(response.statusCode);
  print(response.bodyBytes.length);
  if(response.statusCode == 200){
    return response.bodyBytes;
  }else{
    throw ServiceUnreachableException("Couldn't download OCA json file. Check your digest or internet connection.");
  }

}

Future<Map<String, dynamic>> getFormFromAttributes (Map<String, dynamic> map, JsonWidgetRegistry registry) async{
  registry.setValue("schema", map["said"]);
  String jsonOverlay = '{ "elements": [{"type":"single_child_scroll_view", "children": [{"type":"form", "children":[{"type":"column", "children":[]}]}]}] }';
  Map<String, dynamic> jsonMap = json.decode(jsonOverlay);
  //print(jsonMap['elements'][0]['children'][0]);
  //print(map["capture_base"]["attributes"]);
  List<dynamic> labelOverlay = map["overlays"]["label"];
  bool containsEntryOverlay = false;
  List<dynamic> entryOverlay = [];
  Map<String, dynamic> entryCodeOverlay = {};
  if(map["overlays"]["entry"] != null){
    entryOverlay = map["overlays"]["entry"];
    containsEntryOverlay = true;
    entryCodeOverlay = map["overlays"]["entry_code"];
  }
  List<dynamic> informationOverlay = map["overlays"]["information"];
  Map<String, dynamic> conformanceOverlay = map["overlays"]["conformance"];
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(parseMetaOverlay(map["overlays"]["meta"], registry));
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSizedBox());
  if(containsEntryOverlay){
    parseEntryCodeOverlay(entryCodeOverlay, registry);
  }
  for(String attribute in map["capture_base"]["attributes"].keys){
    parseLabelOverlay(labelOverlay, registry, attribute, conformanceOverlay);
    parseInformationOverlay(informationOverlay, registry, attribute);
    if(containsEntryOverlay && map["overlays"]["entry_code"]["attribute_entry_codes"].keys.contains(attribute)){
      parseEntryOverlay(entryOverlay, registry, attribute);
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getDropdownMenu(attribute, map["overlays"]["entry_code"]["attribute_entry_codes"][attribute], conformanceOverlay));
    }else if(map["capture_base"]["attributes"][attribute] == "Numeric"){
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getNumericFormField(attribute, registry, conformanceOverlay));
    }else if(map["capture_base"]["attributes"][attribute] == "DateTime"){
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getDatePicker(attribute, registry, conformanceOverlay));
    }else if(map["capture_base"]["attributes"][attribute] == "Boolean"){
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getBool(attribute, registry, conformanceOverlay));
    }
    else{
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getFormField(attribute, registry, conformanceOverlay));
    }
    jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSizedBox());
  }
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSubmitButton());
  jsonOverlay = jsonEncode(jsonMap);
  return jsonMap;
}

Map<String, dynamic> getFilledForm(Map<String, dynamic> map, Map<String, dynamic> values){
  print(values);
  String jsonOverlay = '{ "elements": [{"type":"single_child_scroll_view", "children": [{"type":"form", "children":[{"type":"column", "children":[]}]}]}] }';
  Map<String, dynamic> jsonMap = json.decode(jsonOverlay);
  WidgetsFlutterBinding.ensureInitialized();
  var renderRegistry = JsonWidgetRegistry();
  renderRegistry.registerFunction('scaleSize', ({args, required registry}) => args![0].toDouble()/window.devicePixelRatio.toDouble());
  renderRegistry.registerFunction('returnLabel', ({args, required registry}) {
    Map<String, dynamic> registryValues = registry.values;
    return registry.getValue("${args![0]}-${args[1]}");
  } );
  renderRegistry.registerFunction('returnLanguages', ({args, required registry}) {
    return registry.getValue("languages");
  } );
  List<dynamic> labelOverlay = map["overlays"]["label"];
  List<dynamic> informationOverlay = map["overlays"]["information"];
  Map<String, dynamic> conformanceOverlay = map["overlays"]["conformance"];
  bool containsEntryOverlay = false;
  if(map["overlays"]["entry"] != null){
    containsEntryOverlay = true;
  }
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(parseMetaOverlay(map["overlays"]["meta"], renderRegistry));
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSizedBox());
  for(String attribute in map["capture_base"]["attributes"].keys){
    parseLabelOverlay(labelOverlay, renderRegistry, attribute, conformanceOverlay);
    parseInformationOverlay(informationOverlay, renderRegistry, attribute);
    if(containsEntryOverlay && map["overlays"]["entry"][0]["attribute_entries"].keys.contains(attribute)){
      String codeValue = values[attribute];
      String entryValue = map["overlays"]["entry"][0]["attribute_entries"][attribute][codeValue];
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSubmittedFormField(attribute, renderRegistry, entryValue));
    }else{
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSubmittedFormField(attribute, renderRegistry, values[attribute]!));
    }
    jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSizedBox());
  }

  jsonOverlay = jsonEncode(jsonMap);
  var widgetMap = {"registry":renderRegistry, "map":jsonMap};
  print(widgetMap);
  return widgetMap;
}

String getSubmittedFormField(String attributeName, JsonWidgetRegistry registry, String value){
  String textFormFieldJson = '';
  textFormFieldJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type": "text","args": {"text":"$value"}}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';
  return textFormFieldJson;
}

String getFormField(String attributeName, JsonWidgetRegistry registry, Map<String, dynamic> conformanceOverlay){
  String textFormFieldJson = '';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textFormFieldJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type": "text_form_field","args":{"validators": [{"type": "required"}]},"id": "edit${toBeginningOfSentenceCase(attributeName)}"}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';
  }else{
    textFormFieldJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type": "text_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}"}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';
  }
  return textFormFieldJson;
}

String getSizedBox(){
  String textSizedBoxJson = '{"type" : "sized_box","args" : {"height" : "\${scaleSize(40)}"}}';
  return textSizedBoxJson;
}

String getDropdownMenu(String attributeName, List<dynamic> attributeValues, Map<String, dynamic> conformanceOverlay){
  String textDropdownJson = '';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textDropdownJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type" : "container","args": {"width": "\${scaleSize(725)}","height": "\${scaleSize(120)}"},"children" : [{"type" : "set_value","children" : [{"type": "dropdown_button_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}","args": {"validators": [{"type": "required"}], "isExpanded":"true", "items": "\${returnLabel(\'dropdown-$attributeName\', language ?? currentLanguage)}"}}]} ]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';

  }else{
    textDropdownJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type" : "container","args": {"width": "\${scaleSize(725)}","height": "\${scaleSize(120)}"},"children" : [{"type" : "set_value","children" : [{"type": "dropdown_button_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}","args": {"isExpanded":"true", "items": "\${returnLabel(\'dropdown-$attributeName\', language ?? currentLanguage)}"}}]} ]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';
  }
  return textDropdownJson;
}

String getNumericFormField(String attributeName, JsonWidgetRegistry registry, Map<String, dynamic> conformanceOverlay){
  String textFormFieldJson = '';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textFormFieldJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type": "text_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}", "args":{"keyboardType":"number", "validators": [{"type": "required"},{"type":"regex","regex":"[+-]?([0-9]*[.])?[0-9]+"}]}}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';
  }else{
    textFormFieldJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type": "text_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}", "args":{"keyboardType":"number", "validators": [{"type":"regex","regex":"[+-]?([0-9]*[.])?[0-9]+"}]}}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';
  }
  return textFormFieldJson;
}

String getDatePicker(String attributeName, JsonWidgetRegistry registry, Map<String, dynamic> conformanceOverlay){
  String textDatePickerJson='';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textDatePickerJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type":"save_context", "args":{"key":"${toBeginningOfSentenceCase(attributeName)}Context"}, "children":[{"type": "text_form_field","args": {"validators": [{"type": "required"}],"readOnly" : "true","initialValue": "\${pickedDate}","decoration" : {"suffixIcon": {"type": "icon_button","args": {"icon": {"type": "icon","args": {"icon": {"codePoint": 984763,"fontFamily": "MaterialIcons","size": 50}}},"onPressed": "\${showDatePicker(\'${toBeginningOfSentenceCase(attributeName)}Context\', \'edit${toBeginningOfSentenceCase(attributeName)}\', \'YYYY-MM-DD\')}"}}}},"id": "edit${toBeginningOfSentenceCase(attributeName)}"}]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';
  }else{
    textDatePickerJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type":"save_context", "args":{"key":"${toBeginningOfSentenceCase(attributeName)}Context"}, "children":[{"type": "text_form_field","args": {"initialValue": "\${pickedDate}","readOnly" : "true","decoration" : {"suffixIcon": {"type": "icon_button","args": {"icon": {"type": "icon","args": {"icon": {"codePoint": 984763,"fontFamily": "MaterialIcons","size": 50}}},"onPressed": "\${showDatePicker(\'${toBeginningOfSentenceCase(attributeName)}Context\', \'edit${toBeginningOfSentenceCase(attributeName)}\', \'YYYY-MM-DD\')}"}}}},"id": "edit${toBeginningOfSentenceCase(attributeName)}"}]},{"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';
  }
  return textDatePickerJson;
}

String getBool(String attributeName, JsonWidgetRegistry registry, Map<String, dynamic> conformanceOverlay){
  String textBooleanJson = '';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textBooleanJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type":"switch","id":"edit${toBeginningOfSentenceCase(attributeName)}","args":{"validators": [{"type": "required"}], "value":"false"}}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';
  }else{
    textBooleanJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type":"switch","id":"edit${toBeginningOfSentenceCase(attributeName)}","args":{"value":"false"}},{"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}';
  }
  return textBooleanJson;

}

String getSubmitButton(){
  String textButtonJson = '{"type" : "row","args" : {"mainAxisAlignment" : "center"},"children" :[{"type":"save_context","args": {"key": "buttonContext"},"children": [{"type" : "set_value","args" : {"firstInfo" : "edit_message_1"},"children" : [{"type": "text_button","args": {"onPressed" : "\${validateForm(\'buttonContext\')}"},"child": {"type": "text","args": {"text": "SUBMIT"}}}]}]}]}';
  return textButtonJson;
}

String parseMetaOverlay(List<dynamic> metaOverlay, JsonWidgetRegistry registry){
  List<String> languages = [];
  for (Map<String, dynamic> overlay in metaOverlay){
    var language = overlay["language"];
    registry.setValue("formTitle-$language", overlay["name"]);
    languages.add(overlay["language"]);
  }
  registry.setValue("currentLanguage", metaOverlay[0]['language']);
  registry.setValue("languages", languages);
  //print(registry.values);
  String textFormTitleJson = '{"type" : "column","children" : [{"type" : "text","args": {"text" : "\${returnLabel(\'formTitle\', language ?? currentLanguage)}", "style": {"fontSize": "\${scaleSize(65)}","color": "#000000","fontWeight" : "bold"}}},{"type" : "container","args": {"width": "\${scaleSize(225)}","height": "\${scaleSize(120)}"},"children" : [{"type" : "set_value","children" : [{"type": "dropdown_button_form_field","id": "language","args": {"style": {"fontSize": "\${scaleSize(20)", "color":"#000000"},"value" : "\${returnLanguages()[0]}","items": "\${returnLanguages()}"}}]} ]}]}';
  return textFormTitleJson;
}

void parseLabelOverlay(List<dynamic> labelOverlay, JsonWidgetRegistry registry, String attributeName, Map<String, dynamic> conformanceOverlay){
  for (Map<String, dynamic> overlay in labelOverlay){
    var language = overlay["language"];
    if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
      registry.setValue("$attributeName-$language", "${overlay["attribute_labels"][attributeName]} *");
    }else{
      registry.setValue("$attributeName-$language", overlay["attribute_labels"][attributeName]);
    }
  }
}

void parseInformationOverlay(List<dynamic> informationOverlay, JsonWidgetRegistry registry, String attributeName){
  for (Map<String, dynamic> overlay in informationOverlay){
    var language = overlay["language"];
    registry.setValue("information-$attributeName-$language", overlay["attribute_information"][attributeName]);
  }
}

bool parseConformanceOverlay(Map<String, dynamic> conformanceOverlay, String attributeName){
  for (String attribute in conformanceOverlay["attribute_conformance"].keys){
    if(conformanceOverlay["attribute_conformance"][attributeName] == "O"){
      return true;
    }
  }
  return false;
}

void parseEntryCodeOverlay(Map<String, dynamic> entryCodeOverlay, JsonWidgetRegistry registry){
  for (String attribute in entryCodeOverlay["attribute_entry_codes"].keys){
    registry.setValue("selectable-$attribute", entryCodeOverlay["attribute_entry_codes"][attribute]);
  }
}

void parseEntryOverlay(List<dynamic> entryOverlay, JsonWidgetRegistry registry, String attributeName){
  for (Map<String, dynamic> overlay in entryOverlay){
    var language = overlay["language"];
    List<dynamic> vals = [];
    print(attributeName);
    vals.addAll(overlay["attribute_entries"][attributeName].values);
    registry.setValue("dropdown-$attributeName-$language", vals);
  }
}


// Widget getWidgetFromJSON (WidgetData data, BuildContext context){
//   var widget = JsonWidgetData.fromDynamic(data.jsonData["elements"][0], registry: data.registry);
//   return widget!.build(context: context);
// }


Widget renderFilledForm (Map<String, dynamic> widgetMap, BuildContext context) {
  var widget = JsonWidgetData.fromDynamic(widgetMap["map"]["elements"][0], registry: widgetMap["registry"]);
  return widget!.build(context: context);
}

Widget? renderWidgetData (WidgetData widgetData, BuildContext context) {
  var w = JsonWidgetData.fromDynamic(widgetData.jsonData["elements"][0], registry: widgetData.registry);
  return w?.build(context: context);
}

Future<WidgetData> getWidgetData (String json) async{
  WidgetData firstWidgetData = await initialSteps();
  final OcaBundle bundle = await OcaDartPlugin.loadOca(json: json);
  final String ocaBundle = await bundle.toJson();
  final ocaMap = jsonDecode(ocaBundle);
  var jsonData = await getFormFromAttributes(ocaMap, firstWidgetData.registry);
  WidgetData widgetData = WidgetData(registry: firstWidgetData.registry, jsonData: jsonData);
  return widgetData;
}


//Performs initial steps related to json_dynamic_widget mostly and returns new object
//of WidgetData, containing json to render and registry
Future<WidgetData> initialSteps() async{
  var registry = JsonWidgetRegistry();
  var navigatorKey = GlobalKey<NavigatorState>();

  //registers the function to adjust widget and font size to the device size
  registry.registerFunction('scaleSize', ({args, required registry}) => args![0].toDouble()/window.devicePixelRatio.toDouble());
  //registers the function to return the label in chosen language
  registry.registerFunction('returnLabel', ({args, required registry}) {
    Map<String, dynamic> registryValues = registry.values;
    for(String key in registryValues.keys){
      if(key.startsWith("edit")){
        print(key);
      }
    }
    return registry.getValue("${args![0]}-${args[1]}");
  } );
  //registers the function to return the list of languages from the OCA
  registry.registerFunction('returnLanguages', ({args, required registry}) {
    return registry.getValue("languages");
  } );
  //registers the functions to show pickers and validate form
  registry.registerFunctions({
    show_date_picker_fun.key: show_date_picker_fun.body,
    show_time_picker_fun.key: show_time_picker_fun.body,
    show_file_picker_fun.key: show_file_picker_fun.body,
    'validateForm': ({args, required registry}) => () {
      final BuildContext context = registry.getValue(args![0]);
      Map<String, dynamic> values = {};
      Map<String, dynamic> registryValues = registry.values;
      print(registryValues);
      Map<String, dynamic> selectableValues = {};
      Map<String, dynamic> dropdownValues = {};
      registryValues.keys.forEach((element) {
        if(element.startsWith('selectable-')){
          selectableValues[element.substring(element.indexOf('selectable-')+ 'selectable-'.length, element.length)] = registryValues[element];
        }else if(element.startsWith('dropdown-')){
          dropdownValues[element] = registryValues[element];
        }
      });
      for(String key in registryValues.keys){
        if(key.startsWith("edit") && !key.endsWith(".error")){
          String attributeName = key.substring(key.indexOf("edit")+4, key.indexOf("edit")+5).toLowerCase() + key.substring(key.indexOf("edit")+5, key.length);
          if(selectableValues.keys.contains(attributeName)){
            String currentValue = registryValues[key];
            for(String mapKey in dropdownValues.keys){
              if(dropdownValues[mapKey].contains(currentValue)){
                int index = dropdownValues[mapKey].indexOf(currentValue);
                values[attributeName] = selectableValues[attributeName][index];
              }
            }
          }else{
            values[attributeName] = registryValues[key];
          }
        }
      }
      registry.setValue("obtainedValues", values);
      obtainedValues = values;
      print("-----------------------------OBTAINED--------------------------------");
      print(registry.getValue("obtainedValues"));
      final valid = Form.of(context).validate();
      registry.setValue('form_validation', valid);
      if(valid){
        controller.add(valid);
      }
    }
  });
  Validator.registerCustomValidatorBuilder(
    MyCustomValidator.type,
    MyCustomValidator.fromDynamic,
  );
  return(WidgetData(registry: registry, jsonData: {}));
}

Map<String, dynamic> returnObtainedValues(){
  return obtainedValues;
}

Stream returnValidationStream(){
  return stream;
}

String returnSchemaId(WidgetData widgetData){
  return widgetData.registry.getValue("schema");
}
