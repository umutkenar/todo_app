import 'dart:convert';

import 'package:get/get.dart';
import 'package:todo_app/controllers/task_controller.dart';

class GetCategory {
  final TaskController _taskController = Get.put(TaskController());
  List<String> kategoriler = [];
  List<String> main() {
    getCategory();
    getStringList();
    return kategoriler;
  }

  Future<List<String>> getCategory() async {
    kategoriler = await _taskController.getCategoryFromDb();
    // convert each item to a string by using JSON encoding
    final jsonList = kategoriler.map((item) => jsonEncode(item)).toList();
    // using toSet - toList strategy
    final uniqueJsonList = jsonList.toSet().toList();

    // convert each item back to the original form using JSON decoding
    kategoriler = List<String>.from(
        uniqueJsonList.map((item) => jsonDecode(item)).toList());
    print(kategoriler);
    return kategoriler;
  }

  void getStringList() async {
    var tempList = await getCategory();
// Or use setState to assign the tempList to myList
    kategoriler = tempList;
  }
}
