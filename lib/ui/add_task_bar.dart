// ignore_for_file: prefer_const_constructors, unnecessary_import, avoid_print, prefer_adjacent_string_concatenation

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/controllers/task_controller.dart';
import 'package:todo_app/models/task.dart';

import 'package:todo_app/ui/theme.dart';
import 'package:todo_app/ui/widgets/button.dart';
import 'package:todo_app/ui/widgets/input_field.dart';

import '../controllers/login_controller.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({Key? key}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TaskController _taskController = Get.put(TaskController());
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _loginController = Get.put(LoginController());

  DateTime _selectedDate = DateTime.now();
  String _endTime = DateFormat("HH:mm")
      .format(DateTime.now().add(Duration(minutes: 60)))
      .toString();
  String _startTime = DateFormat("HH:mm").format(DateTime.now()).toString();
  String _kategori = "Kategori Giriniz";
  List<String> kategoriler = [];
  String _selectedRepeat = "Hiçbiri";
  List<String> repeatList = [
    "Hiçbiri",
    "Günlük",
    "Haftalık",
    "Aylık",
  ];
  int _selectedColor = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getCategory();
    _checkUserLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.backgroundColor,
      appBar: _appBar(context),
      body: Container(
        padding: const EdgeInsets.only(left: 20, right: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Yeni To-Do Ekle",
                style: headingStyle,
              ),
              MyInputField(
                title: "Kategori",
                isCategory: true,
                hint: _kategori,
                controller: _categoryController,
                widget: DropdownButton(
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  iconSize: 32,
                  elevation: 4,
                  style: subTitleStyle,
                  underline: Container(height: 0),
                  items:
                      kategoriler.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _kategori = newValue!;
                      _categoryController.text = _kategori;
                    });
                  },
                ),
              ),
              /*MyInputField(
                title: "Category",
                hint: _checkCategory().toString(),
                controller: _categoryController,
              ),*/
              MyInputField(
                title: "Başlık",
                hint: "Başlık giriniz",
                controller: _titleController,
              ),
              MyInputField(
                title: "Not",
                hint: "Açıklama notu giriniz",
                controller: _noteController,
              ),
              MyInputField(
                title: "Tarih",
                hint: DateFormat('dd.MM.yyyy').format(_selectedDate),
                widget: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  color: Colors.grey,
                  onPressed: (() {
                    //print("selamm");
                    _getDateFromUser();
                  }),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: MyInputField(
                      title: "Başlangıç Saati",
                      hint: _startTime,
                      widget: IconButton(
                          onPressed: () {
                            _getTimeFromUser(isStartTime: true);
                          },
                          icon: Icon(
                            Icons.access_time_rounded,
                            color: Colors.grey,
                          )),
                    ),
                  ),
                  SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: MyInputField(
                      title: "Bitiş Saati",
                      hint: _endTime,
                      widget: IconButton(
                          onPressed: () {
                            _getTimeFromUser(isStartTime: false);
                          },
                          icon: Icon(
                            Icons.access_time_rounded,
                            color: Colors.grey,
                          )),
                    ),
                  ),
                ],
              ),
              MyInputField(
                title: "Tekrar",
                hint: _selectedRepeat,
                widget: DropdownButton(
                  icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  iconSize: 32,
                  elevation: 4,
                  style: subTitleStyle,
                  underline: Container(height: 0),
                  items:
                      repeatList.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedRepeat = newValue!;
                    });
                  },
                ),
              ),
              SizedBox(
                height: 18,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _colorPallete(),
                  MyButton(
                      width_val: 120,
                      label: "To-Do Oluştur",
                      onTap: () => _validateDate()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _checkUserLogin() {
    var checklogin = _loginController.googleAccount.value?.id;
    if (checklogin == null) {
      return false;
    } else {
      return true;
    }
  }

  _getCategory() async {
    if (_checkUserLogin() == false) {
      kategoriler = await _taskController.getCategoryFromDb();
      // convert each item to a string by using JSON encoding
      final jsonList = kategoriler.map((item) => jsonEncode(item)).toList();

      // using toSet - toList strategy
      final uniqueJsonList = jsonList.toSet().toList();

      // convert each item back to the original form using JSON decoding
      kategoriler = List<String>.from(
          uniqueJsonList.map((item) => jsonDecode(item)).toList());
      //print("hatirlatma");
      kategoriler.insert(0, "Tümü");
      setState(() {
        kategoriler = kategoriler;
      });
      return kategoriler;
    } else {
      final docRef = await _firestore
          .collection("Users")
          .doc(_loginController.googleAccount.value?.email)
          .collection("Diğerleri");
      await docRef.get().then(
        (result) {
          for (int i = 0; i < result.docs.length; i++) {
            var data = result.docs[i].id;
            kategoriler.add(data);
          }
        },
      );
      setState(() {
        kategoriler = kategoriler;
      });
    }
  }

  _validateDate() {
    if (_titleController.text.isNotEmpty && _noteController.text.isNotEmpty) {
      if (_checkUserLogin() == false) {
        _addTaskToDb();
      } else {
        _addTaskToCloud();
      }
      Get.back();
    } else if (_titleController.text.isEmpty || _noteController.text.isEmpty) {
      Get.snackbar(
        "Hata",
        "Boş alan bıraktınız",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.white,
        colorText: pinkClr,
        icon: Icon(Icons.warning_amber_rounded, color: Colors.red),
      );
    }
  }

  _addTaskToCloud() async {
    print(_loginController.googleAccount.value?.email);
    final docRef = await _firestore
        .collection("Users")
        .doc(_loginController.googleAccount.value?.email);

    docRef.collection("Todolar").doc().set({
      'Kategori': _categoryController.text,
      'Başlık': _titleController.text,
      'Not': _noteController.text,
      'Paylaşılanlar': ["default"],
      'date': DateFormat('dd.MM.yyyy').format(_selectedDate),
      'startTime': _startTime,
      'endTime': _endTime,
      'repeat': _selectedRepeat,
      'color': _selectedColor,
      'isCompleted': 0,
    });
  }

  _addTaskToDb() async {
    int value = await _taskController.addTask(
      task: Task(
        note: _noteController.text,
        title: _titleController.text,
        date: DateFormat('dd.MM.yyyy').format(_selectedDate),
        startTime: _startTime,
        endTime: _endTime,
        category: _categoryController.text,
        //remind: _selectedRemind,
        repeat: _selectedRepeat,
        color: _selectedColor,
        isCompleted: 0,
      ),
    );
    print("Task id ==>" + "$value");
  }

  _colorPallete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Color",
          style: titleStyle,
        ),
        SizedBox(
          height: 8,
        ),
        Wrap(
          children: List<Widget>.generate(3, (int index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  child: _selectedColor == index
                      ? Icon(
                          Icons.done,
                          color: Colors.white,
                          size: 16,
                        )
                      : Container(),
                  radius: 14,
                  backgroundColor: index == 0
                      ? primaryClr
                      : index == 1
                          ? pinkClr
                          : yellowClr,
                ),
              ),
            );
          }),
        )
      ],
    );
  }

  _appBar(BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: context.theme.backgroundColor,
      leading: GestureDetector(
        onTap: () {
          Get.back();
        },
        child: Icon(
          Icons.arrow_back_ios,
          size: 20,
          color: Get.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      // ignore: prefer_const_literals_to_create_immutables
    );
  }

  _getDateFromUser() async {
    DateTime? _pickerDate = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2222));
    if (_pickerDate != null) {
      setState(() {
        _selectedDate = _pickerDate;
        print(_selectedDate);
      });
    } else {
      print("bir şeyler yanlış gitti");
    }
  }

  _getTimeFromUser({required bool isStartTime}) async {
    var pickedTime = await _showTimePicker(isStartTime: isStartTime);
    DateTime onehourlater = DateTime(DateTime.now().year, DateTime.now().month,
        DateTime.now().day, pickedTime.hour, pickedTime.minute);
    String _formatedTime = pickedTime.format(context);
    if (pickedTime == null) {
      print("iptall");
    } else if (isStartTime == true) {
      setState(() {
        _startTime = _formatedTime;
        _endTime = DateFormat("HH:mm")
            .format(onehourlater.add(Duration(minutes: 60)))
            .toString();
      });
    } else if (isStartTime == false) {
      setState(() {
        _endTime = _formatedTime;
      });
    }
  }

  _showTimePicker({required bool isStartTime}) {
    return showTimePicker(
      initialEntryMode: TimePickerEntryMode.input,
      context: context,
      initialTime: TimeOfDay(
        hour: isStartTime
            ? int.parse(_startTime.split(":")[0])
            : int.parse(_startTime.split(":")[0]) == 23
                ? 00
                : int.parse(_startTime.split(":")[0]) + 1,
        minute: int.parse(_startTime.split(":")[1]),
      ),
    );
  }
}
