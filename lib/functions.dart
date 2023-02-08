import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:json_dynamic_widget/json_dynamic_widget.dart';
import 'package:http/http.dart' as http;

Future<Map<dynamic, dynamic>> getMapData(String path) async{
  final String mapString = await rootBundle.loadString(path);
  var mapData = await json.decode(mapString);
  return mapData;
}

void parseCells(List cellsList, template, layout){
  Map<dynamic, dynamic> cells = cellsList[0];
  for(var key in cells.keys){
    List keys = cells[key];
    parseTree(template, keys, keys.length, layout);
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
  for (Map<String, dynamic> attribute in attributes){
    Map<String, dynamic> labels = attribute["args"]["labels"];
    for (MapEntry<String, dynamic> label in labels.entries) {
      registry.setValue("${attribute["name"]}-${label.key}", label.value);
    }
    registry.setValue("currentLanguage", labels.entries.first.key);
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