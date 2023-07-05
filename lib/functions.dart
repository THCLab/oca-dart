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

//values obtained from the form
Map<String, dynamic> obtainedValues = {};
//stream controller and stream to listen to the form being submitted
StreamController<bool> controller = StreamController<bool>();
Stream stream = controller.stream.asBroadcastStream();

//Loads map from json under given path
Future<Map<dynamic, dynamic>> getMapData(String path) async{
  final String mapString = await rootBundle.loadString(path);
  var mapData = await json.decode(mapString);
  return mapData;
}

//Allows to return bytes of zip from url with given digest
Future<Uint8List> getZipFromHttp (String digest) async{
  Map<String,String> headers = {
    'Content-type' : 'application/zip',
    'Accept': 'application/zip',
  };
  String url = "https://repository.oca.argo.colossi.network/api/v0.1/namespaces/b1/schemas/$digest/archive";
  final response = await http.get(Uri.parse(url), headers: headers);
  if(response.statusCode == 200){
    return response.bodyBytes;
  }else{
    throw ServiceUnreachableException("Couldn't download OCA zip file. Check your digest or internet connection.");
  }

}

//Allows to return bytes of json file from given url
Future<Uint8List> getJsonFromHttp (String url) async{
  Map<String,String> headers = {
    'Content-type' : 'application/json',
    'Accept': 'application/json',
  };
  final response = await http.get(Uri.parse(url), headers: headers);
  //print(response.statusCode);
  //print(response.bodyBytes.length);
  if(response.statusCode == 200){
    return response.bodyBytes;
  }else{
    throw ServiceUnreachableException("Couldn't download OCA json file. Check your digest or internet connection.");
  }

}

//Prepares the form widget basing on given oca map
Future<Map<String, dynamic>> getFormFromAttributes (Map<String, dynamic> map, JsonWidgetRegistry registry, String issuerId) async{
  //save the schema id in the widget registry
  registry.setValue("schema", map["d"]);
  String schema = map["d"];

  //prepare the template for the form to render
  String jsonOverlay = '{ "elements": [{"type":"single_child_scroll_view", "children": [{"type":"form","args":{"autovalidate":"true", "autovalidateMode":"onUserInteraction"}, "children":[{"type":"column", "children":[]}]}]}] }';

  //decode the template to work with it as a json, not a string
  Map<String, dynamic> jsonMap = json.decode(jsonOverlay);

  //get the list of label overlays in all the supported languages
  List<dynamic> labelOverlay = map["overlays"]["label"];

  //boolean value to hold whether the oca contains of an entry (code) overlay
  bool containsEntryOverlay = false;
  bool containsCardinalityOverlay = false;
  List<dynamic> entryOverlay = [];
  Map<String, dynamic> entryCodeOverlay = {};
  Map<String, dynamic> cardinalityOverlay = {};

  //check if the oca contains entry (code) overlays, get them and set value to true
  if(map["overlays"]["entry"] != null){
    entryOverlay = map["overlays"]["entry"];
    containsEntryOverlay = true;
    entryCodeOverlay = map["overlays"]["entry_code"];
  }

  if(map["overlays"]["cardinality"] != null){
    containsCardinalityOverlay = true;
    cardinalityOverlay = map["overlays"]["cardinality"];
  }

  //get the list of information overlays for all the supported languages
  List<dynamic> informationOverlay = map["overlays"]["information"];

  //get the conformance overlay
  Map<String, dynamic> conformanceOverlay = map["overlays"]["conformance"];

  //parse the meta overlay to get the form title and language dropdown
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(parseMetaOverlay(map["overlays"]["meta"], registry));

  //add some space
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSizedBox());
  if(containsEntryOverlay){
    parseEntryCodeOverlay(entryCodeOverlay, registry);
  }

  if(containsCardinalityOverlay){
    parseCardinalityOverlay(cardinalityOverlay, registry);
  }

  //Loop for each of the attributes in capture base
  for(String attribute in map["capture_base"]["attributes"].keys){
    //parse the label and information overlay for this attribute to get its labels and field descriptions in all supported languages
    if(attribute != "d" && attribute != "i"){
      parseLabelOverlay(labelOverlay, registry, attribute, conformanceOverlay);
      parseInformationOverlay(informationOverlay, registry, attribute);

      //if the oca supports entry overlay, get the dropdown menu for this attribute
      if(containsEntryOverlay && map["overlays"]["entry_code"]["attribute_entry_codes"].keys.contains(attribute)){
        parseEntryOverlay(entryOverlay, registry, attribute);
        jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getDropdownMenu(attribute, map["overlays"]["entry_code"]["attribute_entry_codes"][attribute], conformanceOverlay));

        //check the type of the attribute field and add a proper widget to the json form template
      }else if(map["capture_base"]["attributes"][attribute] == "Numeric"){
        jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getNumericFormField(attribute, registry, conformanceOverlay));
      }else if(map["capture_base"]["attributes"][attribute] == "DateTime"){
        jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getDatePicker(attribute, registry, conformanceOverlay));
      }else if(map["capture_base"]["attributes"][attribute] == "Boolean"){
        jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getBool(attribute, registry, conformanceOverlay));
      }else if(map["capture_base"]["attributes"][attribute] == "Array[Text]"){
        jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getArray(attribute, registry, conformanceOverlay));
      }
      else{
        jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getFormField(attribute, registry, conformanceOverlay));
      }
      //leave some space after the attribute
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSizedBox());
    }else if(attribute == "d"){
      registry.setValue("editD", schema);
    }else if(attribute =="i"){
      registry.setValue("editI", issuerId);
    }

  }
  //following all the form fields, render a submit button
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSubmitButton());
  jsonOverlay = jsonEncode(jsonMap);
  return jsonMap;
}

//Prepares filled form based on given values and oca map
Map<String, dynamic> getFilledForm(Map<String, dynamic> map, Map<String, dynamic> values){
  //prepare the template for the form to render
  String jsonOverlay = '{ "elements": [{"type":"single_child_scroll_view", "children": [{"type":"form", "children":[{"type":"column", "children":[]}]}]}] }';

  //decode the template to work with it as a json, not a string
  Map<String, dynamic> jsonMap = json.decode(jsonOverlay);
  //create a render registry to be able to switch languages
  var renderRegistry = JsonWidgetRegistry();

  //register all the necessary functions in the new registry
  renderRegistry.registerFunction('scaleSize', ({args, required registry}) => args![0].toDouble()/window.devicePixelRatio.toDouble());
  renderRegistry.registerFunction('returnLabel', ({args, required registry}) {
    Map<String, dynamic> registryValues = registry.values;
    return registry.getValue("${args![0]}-${args[1]}");
  } );
  renderRegistry.registerFunction('returnLanguages', ({args, required registry}) {
    return registry.getValue("languages");
  } );

  //get the list of label overlays in all the supported languages
  List<dynamic> labelOverlay = map["overlays"]["label"];

  //get the list of information overlays for all the supported languages
  List<dynamic> informationOverlay = map["overlays"]["information"];

  //get the conformance overlay
  Map<String, dynamic> conformanceOverlay = map["overlays"]["conformance"];

  //check if the oca contains entry (code) overlays and set value to true
  bool containsEntryOverlay = false;
  if(map["overlays"]["entry"] != null){
    containsEntryOverlay = true;
  }

  //parse the meta overlay to get the form title and language dropdown
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(parseMetaOverlay(map["overlays"]["meta"], renderRegistry));

  //add some space
  jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSizedBox());

  //Loop for each of the attributes in capture base
  for(String attribute in map["capture_base"]["attributes"].keys){
    if(attribute != "d" && attribute != "i"){
      //parse the label and information overlay for this attribute to get its labels and field descriptions in all supported languages
      parseLabelOverlay(labelOverlay, renderRegistry, attribute, conformanceOverlay);
      parseInformationOverlay(informationOverlay, renderRegistry, attribute);

      //if the oca supports entry overlay, get the code value from value map and find proper entry value in the oca
      if(containsEntryOverlay && map["overlays"]["entry"][0]["attribute_entries"].keys.contains(attribute)){
        String codeValue = values[attribute];
        String entryValue = map["overlays"]["entry"][0]["attribute_entries"][attribute][codeValue];
        jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSubmittedFormField(attribute, renderRegistry, entryValue.toString()));
      }else{
        if(values[attribute] != null){
          if(map["capture_base"]["attributes"][attribute] == "Array[Text]"){
            jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSubmittedListView(attribute, renderRegistry, values[attribute]!.toString()));
          }else{
            jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSubmittedFormField(attribute, renderRegistry, values[attribute]!.toString()));
          }
        }
      }
      jsonMap['elements'][0]['children'][0]['children'][0]['children'].add(getSizedBox());
    }
  }

  jsonOverlay = jsonEncode(jsonMap);
  var widgetMap = {"registry":renderRegistry, "map":jsonMap};
  //print(widgetMap);
  return widgetMap;
}

//Returns a string of text field json containing given value
String getSubmittedFormField(String attributeName, JsonWidgetRegistry registry, String value){
  String textFormFieldJson = '';
  textFormFieldJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type":"container", "args":{"width":"infinity","decoration":{"border": {"width":1,"color": "#737170"}, "borderRadius":"5"}, "padding": "\${scaleSize(50)}"}, "children":[{"type": "text","args": {"text":"$value", "style":{"fontSize": "\${scaleSize(48)}"}}}]}]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  return textFormFieldJson;
}

String getSubmittedListView(String attributeName, JsonWidgetRegistry registry, String value){
  String textFormFieldJson = '';
  String firstListViewJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]}]}]}';
  List<String> valueList = value.substring(value.indexOf("[")+1, value.indexOf("]")).split(",");
  Map<String, dynamic> jsonMap = json.decode(firstListViewJson);
  for(String value in valueList){
    jsonMap["children"][0]["children"].add('{"type":"row","children":[{"type": "icon","args": {"icon": {"codePoint": 57687,"fontFamily": "MaterialIcons"}}},{"type" : "text","args" : {"text" : "$value"}}]}');
  }
  jsonMap["children"][0]["children"].add('{"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}');
  String jsonOverlay = jsonEncode(jsonMap);
  return jsonOverlay;
}

//Returns a string of text form field, taking the conformance overlay into account
String getFormField(String attributeName, JsonWidgetRegistry registry, Map<String, dynamic> conformanceOverlay){
  String textFormFieldJson = '';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textFormFieldJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type": "text_form_field","args":{"decoration":{"border": {"type":"outline","width":2}}, "validators": [{"type": "required"}]},"id": "edit${toBeginningOfSentenceCase(attributeName)}"}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }else{
    textFormFieldJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type": "text_form_field","args":{"decoration":{"border": {"type":"outline","width":2}}}, "id": "edit${toBeginningOfSentenceCase(attributeName)}"}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }
  return textFormFieldJson;
}

//Returns sized box, giving some space
String getSizedBox(){
  String textSizedBoxJson = '{"type" : "sized_box","args" : {"height" : "\${scaleSize(55)}"}}';
  return textSizedBoxJson;
}

//Returns a string of dropdown menu, taking the conformance overlay into account
String getDropdownMenu(String attributeName, List<dynamic> attributeValues, Map<String, dynamic> conformanceOverlay){
  String textDropdownJson = '';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textDropdownJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type" : "container", "children" : [{"type" : "set_value","children" : [{"type": "dropdown_button_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}","args": {"decoration":{"border": {"type":"outline","width":2}},"validators": [{"type": "required"}], "isExpanded":"true", "items": "\${returnLabel(\'dropdown-$attributeName\', language ?? currentLanguage)}"}}]} ]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }else{
    textDropdownJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type" : "container","children" : [{"type" : "set_value","children" : [{"type": "dropdown_button_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}","args": {"decoration":{"border": {"type":"outline","width":2}},"isExpanded":"true", "items": "\${returnLabel(\'dropdown-$attributeName\', language ?? currentLanguage)}"}}]} ]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }
  return textDropdownJson;
}

//Returns a string of numeric text form field, taking the conformance overlay into account
String getNumericFormField(String attributeName, JsonWidgetRegistry registry, Map<String, dynamic> conformanceOverlay){
  String textFormFieldJson = '';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textFormFieldJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type": "text_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}", "args":{"decoration":{"border": {"type":"outline","width":2}}, "keyboardType":"number", "validators": [{"type": "required"},{"type":"regex","regex":"[+-]?([0-9]*[.])?[0-9]+"}]}}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }else{
    textFormFieldJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type": "text_form_field","id": "edit${toBeginningOfSentenceCase(attributeName)}", "args":{"decoration":{"border": {"type":"outline","width":2}},"keyboardType":"number", "validators": [{"type":"regex","regex":"[+-]?([0-9]*[.])?[0-9]+"}]}}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }
  return textFormFieldJson;
}

//Returns a string of date picker form field, taking the conformance overlay into account
String getDatePicker(String attributeName, JsonWidgetRegistry registry, Map<String, dynamic> conformanceOverlay){
  String textDatePickerJson='';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textDatePickerJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type":"save_context", "args":{"key":"${toBeginningOfSentenceCase(attributeName)}Context"}, "children":[{"type": "text_form_field","args": {"validators": [{"type": "required"}],"readOnly" : "true","initialValue": "\${pickedDate}","decoration" : {"border": {"type":"outline","width":2},"suffixIcon": {"type": "icon_button","args": {"icon": {"type": "icon","args": {"icon": {"codePoint": 984763,"fontFamily": "MaterialIcons","size": 50}}},"onPressed": "\${showDatePicker(\'${toBeginningOfSentenceCase(attributeName)}Context\', \'edit${toBeginningOfSentenceCase(attributeName)}\', \'YYYY-MM-DD\')}"}}}},"id": "edit${toBeginningOfSentenceCase(attributeName)}"}]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }else{
    textDatePickerJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type":"save_context", "args":{"key":"${toBeginningOfSentenceCase(attributeName)}Context"}, "children":[{"type": "text_form_field","args": {"initialValue": "\${pickedDate}","readOnly" : "true","decoration" : {"border": {"type":"outline","width":2}, "suffixIcon": {"type": "icon_button","args": {"icon": {"type": "icon","args": {"icon": {"codePoint": 984763,"fontFamily": "MaterialIcons","size": 50}}},"onPressed": "\${showDatePicker(\'${toBeginningOfSentenceCase(attributeName)}Context\', \'edit${toBeginningOfSentenceCase(attributeName)}\', \'YYYY-MM-DD\')}"}}}},"id": "edit${toBeginningOfSentenceCase(attributeName)}"}]},{"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }
  return textDatePickerJson;
}

//Returns a string of bool form field (toggle), taking the conformance overlay into account
String getBool(String attributeName, JsonWidgetRegistry registry, Map<String, dynamic> conformanceOverlay){
  String textBooleanJson = '';
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    registry.setValue("edit${toBeginningOfSentenceCase(attributeName)}", false);
    textBooleanJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type":"set_value", "children":[{"type":"switch","id":"edit${toBeginningOfSentenceCase(attributeName)}","args":{"validators": [{"type": "required"}], "value":"false"}}]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }else{
    textBooleanJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type":"switch","id":"edit${toBeginningOfSentenceCase(attributeName)}","args":{"value":"false"}},{"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }
  return textBooleanJson;

}

String getArray(String attributeName, JsonWidgetRegistry registry, Map<String, dynamic> conformanceOverlay){
  String textArrayJson = '';
  int min = int.parse(registry.getValue("cardinality-$attributeName-min"));
  int max = int.parse(registry.getValue("cardinality-$attributeName-max"));
  List<Map<String, dynamic>> vms = [{ "vm_name": 123, "identifier": 456 }, { "vm_name": 227, "identifier": 432 }, { "vm_name": 324, "identifier": 675 }];
  List<String> items = vms.map((e) => e["vm_name"].toString()).toList();
  registry.setValue("array-$attributeName", items);
  if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
    textArrayJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type": "column","args": {"mainAxisAlignment" : "start"},"children": [{"type": "dynamic","id": "items-$attributeName","args": {"dynamic": {"builderType": "list_view","childTemplate": {"type": "set_value","args": {"remove{id}Element": {"type": "remove","builder": "items-$attributeName","target": {"id": "{id}"}}},"child": {"id": "{id}","type": "row","children": [{"type":"container","args": {"width": "\${scaleSize(800)}"},"children":[{"type":"set_value","children":[{"type":"dropdown_button_form_field","id":"edit${toBeginningOfSentenceCase(attributeName)}{id}","args":{"decoration":{"border":{"type":"outline","width":2}},"validators":[{"type":"required"}],"isExpanded":"true","items":"\${returnArrayList(\'$attributeName\')}"}}]}]},{"type": "icon_button","args": {"icon": {"type": "icon","args": {"icon": {"codePoint": 58646,"fontFamily": "MaterialIcons","size": 50}}},"onPressed": "\${removeDynamically(dynamic(\'remove{id}Element\'), $min, \'$attributeName\')}"}}],"args": {"mainAxisAlignment" : "spaceBetween"}}},"initState": [{"id": "1"}]},"shrinkWrap" : "true"}},{"type": "set_value","args": {"dynamicItemsAdd": {"type": "add","builder": "items-$attributeName","target": {"index": -1}}},"child": {"type": "icon_button","args": {"icon": {"type": "icon","args": {"icon": {"codePoint": 57415,"fontFamily": "MaterialIcons","size": 50}}},"onPressed": "\${addDynamically(dynamic(\'dynamicItemsAdd\'),$max, \'$attributeName\')}"}}}]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }else{
    textArrayJson = '{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"column", "children": [{"type":"align", "args":{"alignment":"centerLeft"}, "children":[{"type": "text","args": {"text":"\${returnLabel(\'$attributeName\', language ?? currentLanguage)}"}}]},{"type": "column","args": {"mainAxisAlignment" : "start"},"children": [{"type": "dynamic","id": "items-$attributeName","args": {"dynamic": {"builderType": "list_view","childTemplate": {"type": "set_value","args": {"remove{id}Element": {"type": "remove","builder": "items-$attributeName","target": {"id": "{id}"}}},"child": {"id": "{id}","type": "row","children": [{"type":"container","args": {"width": "\${scaleSize(800)}"},"children":[{"type":"set_value","children":[{"type":"dropdown_button_form_field","id":"edit${toBeginningOfSentenceCase(attributeName)}{id}","args":{"decoration":{"border":{"type":"outline","width":2}},"validators":[{"type":"required"}],"isExpanded":"true","items":"\${returnArrayList(\'$attributeName\')}"}}]}]},{"type": "icon_button","args": {"icon": {"type": "icon","args": {"icon": {"codePoint": 58646,"fontFamily": "MaterialIcons","size": 50}}},"onPressed": "\${removeDynamically(dynamic(\'remove{id}Element\'), $min, \'$attributeName\')}"}}],"args": {"mainAxisAlignment" : "spaceBetween"}}}},"shrinkWrap" : "true"}},{"type": "set_value","args": {"dynamicItemsAdd": {"type": "add","builder": "items-$attributeName","target": {"index": -1}}},"child": {"type": "icon_button","args": {"icon": {"type": "icon","args": {"icon": {"codePoint": 57415,"fontFamily": "MaterialIcons","size": 50}}},"onPressed": "\${addDynamically(dynamic(\'dynamicItemsAdd\'),$max, \'$attributeName\')}"}}}]}, {"type": "text","args": {"text":"\${returnLabel(\'information-$attributeName\', language ?? currentLanguage)}","style": {"fontSize": "\${scaleSize(25)}","color": "#737170"}}}]}]}';
  }
  return textArrayJson;
}

//Returns the button that submits the form
String getSubmitButton(){
  String textButtonJson = '{"type" : "row","args" : {"mainAxisAlignment" : "center"},"children" :[{"type":"save_context","args": {"key": "buttonContext"},"children": [{"type" : "set_value","args" : {"firstInfo" : "edit_message_1"},"children" : [{"type": "text_button","args": {"onPressed" : "\${validateForm(\'buttonContext\')}"},"child": {"type": "text","args": {"text": "ISSUE"}}}]}]}]}';
  return textButtonJson;
}

//Parses the meta overlay to return the title of the form and languages dropdown
String parseMetaOverlay(List<dynamic> metaOverlay, JsonWidgetRegistry registry){
  List<String> languages = [];
  registry.setValue("meta", metaOverlay[0]["description"]);
  //for all the languages in meta overlay
  for (Map<String, dynamic> overlay in metaOverlay){
    var language = overlay["language"];
    //save the title for this language in the registry
    registry.setValue("formTitle-$language", overlay["name"]);
    languages.add(overlay["language"]);
  }
  //save the current language and all languages to the registry
  registry.setValue("currentLanguage", metaOverlay[0]['language']);
  registry.setValue("languages", languages);
  String textFormTitleJson = '{"type" : "column","children" : [{"type":"padding","args":{"padding":"\${scaleSize(25)}"}, "children":[{"type":"align", "args":{"alignment":"centerRight"}, "children":[{"type" : "container","args": {"width": "\${scaleSize(325)}","height": "\${scaleSize(180)}"},"children" : [{"type" : "set_value","children" : [{"type": "dropdown_button_form_field","id": "language","args": {"decoration":{"border": {"type":"outline","width":2}},"style": {"fontSize": "\${scaleSize(20)", "color":"#000000"},"value" : "\${returnLanguages()[0]}","items": "\${returnLanguages()}"}}]} ]}]}]}, {"type" : "text","args": {"text" : "\${returnLabel(\'formTitle\', language ?? currentLanguage)}", "style": {"fontSize": "\${scaleSize(65)}","color": "#000000","fontWeight" : "bold"}}}]}';
  return textFormTitleJson;
}

//Parses the label overlay to save labels in all languages for given attribute in the registry
void parseLabelOverlay(List<dynamic> labelOverlay, JsonWidgetRegistry registry, String attributeName, Map<String, dynamic> conformanceOverlay){
  print('weszło do label');
  for (Map<String, dynamic> overlay in labelOverlay){
    var language = overlay["language"];
    if(parseConformanceOverlay(conformanceOverlay, attributeName) == true){
      registry.setValue("$attributeName-$language", "${overlay["attribute_labels"][attributeName]} *");
    }else{
      registry.setValue("$attributeName-$language", overlay["attribute_labels"][attributeName]);
    }
  }
}

//Parses the information overlay to save the field descriptors in all languages for given attribute in the registry
void parseInformationOverlay(List<dynamic> informationOverlay, JsonWidgetRegistry registry, String attributeName){
  for (Map<String, dynamic> overlay in informationOverlay){
    var language = overlay["language"];
    registry.setValue("information-$attributeName-$language", overlay["attribute_information"][attributeName]);
  }
}

//Parses the conformance overlay to check whether the given attribute is obligatory
bool parseConformanceOverlay(Map<String, dynamic> conformanceOverlay, String attributeName){
  if(conformanceOverlay["attribute_conformance"][attributeName] == "M"){
    return true;
  }
  return false;
}

//Parses the entry code overlay to save all selectable values for each of the attributes
void parseEntryCodeOverlay(Map<String, dynamic> entryCodeOverlay, JsonWidgetRegistry registry){
  for (String attribute in entryCodeOverlay["attribute_entry_codes"].keys){
    registry.setValue("selectable-$attribute", entryCodeOverlay["attribute_entry_codes"][attribute]);
  }
}

//Parses the entry overlay to save all the dropdown values for the given attribute
void parseEntryOverlay(List<dynamic> entryOverlay, JsonWidgetRegistry registry, String attributeName){
  for (Map<String, dynamic> overlay in entryOverlay){
    var language = overlay["language"];
    List<dynamic> vals = [];
    //print(attributeName);
    vals.addAll(overlay["attribute_entries"][attributeName].values);
    registry.setValue("dropdown-$attributeName-$language", vals);
  }
}

void parseCardinalityOverlay(Map<String, dynamic> cardinalityOverlay, JsonWidgetRegistry registry){
  for (String attribute in cardinalityOverlay["attribute_cardinality"].keys){
    String minValue = cardinalityOverlay["attribute_cardinality"][attribute].toString().substring(0,1);
    String maxValue = cardinalityOverlay["attribute_cardinality"][attribute].toString().substring(2,cardinalityOverlay["attribute_cardinality"][attribute].toString().length);
    registry.setValue("cardinality-$attribute-min", minValue);
    registry.setValue("cardinality-$attribute-max", maxValue);
  }
}

// Widget getWidgetFromJSON (WidgetData data, BuildContext context){
//   var widget = JsonWidgetData.fromDynamic(data.jsonData["elements"][0], registry: data.registry);
//   return widget!.build(context: context);
// }

//Renders the submitted form basing on the given map of widgets
Widget renderFilledForm (Map<String, dynamic> widgetMap, BuildContext context) {
  var widget = JsonWidgetData.fromDynamic(widgetMap["map"]["elements"][0], registry: widgetMap["registry"]);
  return widget!.build(context: context);
}

//Renders the form to fill basing on the given `WidgetData` object
Widget? renderWidgetData (WidgetData widgetData, BuildContext context) {
  var w = JsonWidgetData.fromDynamic(widgetData.jsonData["elements"][0], registry: widgetData.registry);
  return w?.build(context: context);
}

//Gets the widget data of the form to render
Future<WidgetData> getWidgetData (String json, String issuerId) async{
  WidgetData firstWidgetData = await initialSteps();
  final OcaBundle bundle = await OcaDartPlugin.loadOca(json: json);
  final String ocaBundle = await bundle.toJson();
  final ocaMap = jsonDecode(ocaBundle);
  var jsonData = await getFormFromAttributes(ocaMap, firstWidgetData.registry, issuerId);
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
  registry.registerFunction('returnArrayList', ({args, required registry}) {
    return registry.getValue("array-${args![0]}");
  });
  //registers the function to return the list of languages from the OCA
  registry.registerFunction('returnLanguages', ({args, required registry}) {
    return registry.getValue("languages");
  } );
  //registers the functions to show pickers and validate form
  registry.registerFunctions({
    show_date_picker_fun.key: show_date_picker_fun.body,
    show_time_picker_fun.key: show_time_picker_fun.body,
    show_file_picker_fun.key: show_file_picker_fun.body,
    'addDynamically': ({args, required registry}) => () {
      print("add-${args![2]}");
      if(registry.getValue("items-${args![2]}").length < args[1]){
        args[0]();
      }
      print(registry.values);
    },
    'removeDynamically': ({args, required registry}) => () {
      print("remove-${args![2]}");
      if(registry.getValue("items-${args![2]}").length > args[1]){
        args[0]();
      }
      print(registry.values);
    },
    'validateForm': ({args, required registry}) => () {
      final BuildContext context = registry.getValue(args![0]);
      Map<String, dynamic> values = {};
      Map<String, dynamic> registryValues = registry.values;
      print(registryValues);
      Map<String, dynamic> selectableValues = {};
      Map<String, dynamic> dropdownValues = {};
      Map<String, dynamic> arrayValues = {};
      registryValues.keys.forEach((element) {
        if(element.startsWith('selectable-')){
          selectableValues[element.substring(element.indexOf('selectable-')+ 'selectable-'.length, element.length)] = registryValues[element];
        }else if(element.startsWith('dropdown-')){
          dropdownValues[element] = registryValues[element];
        }else if(element.startsWith('array-')){
          arrayValues[element] = [];
        }
      });

      for(String key in arrayValues.keys.map((e) => e.substring(e.indexOf('array-')+ 'array-'.length, e.length))){
        print(key);
        if(registryValues.keys.contains("items-$key")){
          print("items-$key");
          for (String id in registry.getValue("items-$key").map((e) => e["id"])){
            arrayValues["array-$key"].add(registryValues["edit${toBeginningOfSentenceCase(key)}$id"]);
            //print("edit${toBeginningOfSentenceCase(key)}$id");
          }
          if(arrayValues["array-$key"].isNotEmpty){
            values[key] = arrayValues["array-$key"];
          }
        }
      }
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
            int counter = 0;



            // print("items-$attributeName");
            // if(registryValues.keys.contains("items-$attributeName")){
            //   for (String id in registry.getValue("items-$attributeName").map((e) => e["id"])){
            //     print("edit${toBeginningOfSentenceCase(attributeName)}$id");
            //   }
            // }

            for(String key in arrayValues.keys.map((e) => e.substring(e.indexOf('array-')+ 'array-'.length, e.length))){
              if(attributeName.contains(key)){
                //arrayValues["array-$key"].add(registryValues["edit${toBeginningOfSentenceCase(attributeName)}"]);
                //values[key] = arrayValues["array-$key"];
                counter = 1;
              }
            }
            if(counter == 0){
              values[attributeName] = registryValues[key];
            }
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
  //registers regex validator
  Validator.registerCustomValidatorBuilder(
    MyCustomValidator.type,
    MyCustomValidator.fromDynamic,
  );
  return(WidgetData(registry: registry, jsonData: {}));
}

//returns the values from the submitted form
Map<String, dynamic> returnObtainedValues(){
  return obtainedValues;
}

//returns the stream to know whether the form has been submitted
Stream returnValidationStream(){
  return stream;
}

//returns the schema id from the registry for acdc saving
String returnSchemaId(WidgetData widgetData){
  return widgetData.registry.getValue("schema");
}

String returnMetaDescription(dynamic ocaSchema){
  if(ocaSchema.runtimeType == WidgetData){
    return ocaSchema.registry.getValue("meta");
  }else if(ocaSchema["overlays"]["meta"][0]["description"] != null){
    print("not null");
    return ocaSchema["overlays"]["meta"][0]["description"];
  }
  return "";

}
