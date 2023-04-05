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

Map<String, dynamic> obtainedValues = {};

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

Future<Map<String, dynamic>> getFormFromAttributes (Map<String, dynamic> map, JsonWidgetRegistry registry) async{
  String jsonOverlay = '{ "elements": [{"type":"single_child_scroll_view", "children": [{"type":"form", "children":[{"type":"column", "children":[]}]}]}] }';
  Map<String, dynamic> jsonMap = json.decode(jsonOverlay);
  //print(jsonMap['elements'][0]['children'][0]);
  //print(map["capture_base"]["attributes"]);
  List<dynamic> labelOverlay = map["overlays"]["label"];
  List<dynamic> entryOverlay = map["overlays"]["entry"];
  List<dynamic> informationOverlay = map["overlays"]["information"];
  Map<String, dynamic> entryCodeOverlay = map["overlays"]["entry_code"];
  Map<String, dynamic> conformanceOverlay = map["overlays"]["conformance"];
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(parseMetaOverlay(map["overlays"]["meta"], registry));
  parseEntryCodeOverlay(entryCodeOverlay, registry);
  for(String attribute in map["capture_base"]["attributes"].keys){
    parseLabelOverlay(labelOverlay, registry, attribute, conformanceOverlay);
    parseInformationOverlay(informationOverlay, registry, attribute);
    //print(registry.values);
    if(map["overlays"]["entry_code"]["attribute_entry_codes"].keys.contains(attribute)){
      parseEntryOverlay(entryOverlay, registry, attribute);
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getDropdownMenu(attribute, map["overlays"]["entry_code"]["attribute_entry_codes"][attribute]));
    }else{
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getFormField(attribute, registry, conformanceOverlay));
    }
    jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSizedBox());
  }
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSubmitButton());
  jsonOverlay = jsonEncode(jsonMap);
  return jsonMap;
}

String getFormField(String attributeName, JsonWidgetRegistry registry, Map<String, dynamic> conformanceOverlay){
  String textFormFieldJson = '';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textFormFieldJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type": "text_form_field","args":{"validators": [{"type": "required"}]},"id": "edit${toBeginningOfSentenceCase(attributeName)}"}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(10)}","color": "#737170"}}}]}';
  }else{
    textFormFieldJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type": "text_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}"}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(10)}","color": "#737170"}}}]}';
  }
  return textFormFieldJson;
}

String getSizedBox(){
  String textSizedBoxJson = '{"type" : "sized_box","args" : {"height" : "\${scaleSize(20)}"}}';
  return textSizedBoxJson;
}

String getDropdownMenu(String attributeName, List<dynamic> attributeValues){
  String textDropdownJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type" : "container","args": {"width": "\${scaleSize(425)}","height": "\${scaleSize(60)}"},"children" : [{"type" : "set_value","children" : [{"type": "dropdown_button_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}","args": {"value" : "\${returnLabel(\'dropdown-$attributeName\', language ?? currentLanguage)[0]}","items": "\${returnLabel(\'dropdown-$attributeName\', language ?? currentLanguage)}"}}]} ]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(10)}","color": "#737170"}}}]}';
  return textDropdownJson;
}

String getNumericFormField(String attributeName, JsonWidgetRegistry registry){
  String textFormFieldJson = '{"type":"column", "children": [{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}},{"type": "text_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}"}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}"}}]}';
  return textFormFieldJson;
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
  String textFormTitleJson = '{"type" : "row","args" : {"mainAxisAlignment" : "spaceBetween"},"children" : [{"type" : "text","args": {"text" : "\${returnLabel(\'formTitle\', language ?? currentLanguage)}", "style": {"fontSize": "\${scaleSize(30)}","color": "#000000","fontWeight" : "bold"}}},{"type" : "container","args": {"width": "\${scaleSize(225)}","height": "\${scaleSize(60)}"},"children" : [{"type" : "set_value","children" : [{"type": "dropdown_button_form_field","id": "language","args": {"value" : "\${returnLanguages()[0]}","items": "\${returnLanguages()}"}}]} ]}]}';
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
    List<dynamic> values = [];
    values.addAll(overlay["attribute_entries"][attributeName].values);
    registry.setValue("dropdown-$attributeName-$language", values);
  }
}


Widget getWidgetFromJSON (WidgetData data, BuildContext context){
  var widget = JsonWidgetData.fromDynamic(data.jsonData, registry: data.registry);
  return widget!.build(context: context);
}

Future<WidgetData> initialSteps() async{
  WidgetsFlutterBinding.ensureInitialized();
  var registry = JsonWidgetRegistry();
  var navigatorKey = GlobalKey<NavigatorState>();
  registry.registerFunction('scaleSize', ({args, required registry}) => args![0].toDouble()/window.devicePixelRatio.toDouble());
  registry.registerFunction('returnLabel', ({args, required registry}) {
    Map<String, dynamic> registryValues = registry.values;
    for(String key in registryValues.keys){
      if(key.startsWith("edit")){
        print(key);
      }
    }
    return registry.getValue("${args![0]}-${args[1]}");
  } );
  registry.registerFunction('returnLanguages', ({args, required registry}) {
    return registry.getValue("languages");
  } );
  registry.registerFunctions({
    show_date_picker_fun.key: show_date_picker_fun.body,
    show_time_picker_fun.key: show_time_picker_fun.body,
    show_file_picker_fun.key: show_file_picker_fun.body,
    'validateForm': ({args, required registry}) => () {
      //print(registry.values);
      final BuildContext context = registry.getValue(args![0]);
      Map<String, dynamic> values = {};
      Map<String, dynamic> registryValues = registry.values;
      for(String key in registryValues.keys){
        //print(key);
        if(key.startsWith("edit")){
          values[key] = registryValues[key];
        }
      }
      registry.setValue("obtainedValues", values);
      obtainedValues = values;
      print("-----------------------------OBTAINED--------------------------------");
      print(registry.getValue("obtainedValues"));
      final valid = Form.of(context).validate();
      registry.setValue('form_validation', valid);
      if(valid){
        //registry.navigatorKey?.currentState!.push(MaterialPageRoute(builder: (context) => MyFormRenderPage(jsonData: {}, registry: registry,)));
        //Navigator.pushNamed(navigatorKey.currentContext!, '/second');
      }
    },
      'returnValues': ({args, required registry}) {
        Map<String, dynamic> values = {};
        Map<String, dynamic> registryValues = registry.values;
        for(String key in registryValues.keys){
          print(key);
          if(key.startsWith("edit")){
            values[registryValues[key]] = registryValues[key];
          }
        }
        registry.setValue("obtainedValues", values);
        print(registry.getValue("obtainedValues"));
      }
  });
  registry.registerFunction('nooped', ({args, required registry}) {
    print(registry.getValue("language"));
  } );
  // registry.registerFunction('returnValues', ({args, required registry}) {
  //   Map<String, dynamic> values = {};
  //   Map<String, dynamic> registryValues = registry.values;
  //   for(String key in registryValues.keys){
  //     print(key);
  //     if(key.startsWith("edit")){
  //       values[registryValues[key]] = registryValues[key];
  //     }
  //   }
  //   registry.setValue("obtainedValues", values);
  //   print(registry.getValue("obtainedValues"));
  // } );
  return(WidgetData(registry: registry, jsonData: {}));
}

Map<String, dynamic> returnObtainedValues(){
  return obtainedValues;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class MyFormRenderPage extends StatefulWidget {
  final Map<String, dynamic> jsonData;
  final JsonWidgetRegistry registry;
  const MyFormRenderPage({required this.jsonData, required this.registry, Key? key,}) : super(key: key);

  @override
  State<MyFormRenderPage> createState() => _MyFormRenderPageState();
}

class _MyFormRenderPageState extends State<MyFormRenderPage> {
  late var _data;
  late var _registry;

  @override
  void initState() {
    super.initState();
    _registry = widget.registry;
    _data = JsonWidgetData.fromDynamic(widget.jsonData, registry: _registry);
  }

  @override
  Widget build(BuildContext context) {
    _registry.setValue('myContext', context);
    print(_registry.getValue('myContext'));
    print(_registry.getValue('editAssigner'));
    return Scaffold(
      appBar: AppBar(
        title: const Text("My App"),
      ),
      body: Center(
        child: CinemaWidget(registry: _registry, jsonData: widget.jsonData,),
      ),
    );
  }
}

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
