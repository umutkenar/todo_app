// ignore_for_file: prefer_const_constructors, unnecessary_import, unused_field, prefer_typing_uninitialized_variables

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/controllers/task_controller.dart';
import 'package:todo_app/services/notifcation_service.dart';
import 'package:todo_app/services/theme_services.dart';
import 'package:todo_app/ui/add_task_bar.dart';
import 'package:todo_app/ui/theme.dart';
import 'package:todo_app/ui/widgets/button.dart';
import 'package:todo_app/ui/widgets/firestore_tasks.dart';
import 'package:todo_app/ui/widgets/noglowbehavior.dart';

import '../controllers/login_controller.dart';
import '../models/task.dart';
import 'widgets/task_tile.dart';

class CompletedTasks extends StatefulWidget {
  const CompletedTasks({Key? key}) : super(key: key);

  @override
  State<CompletedTasks> createState() => _CompletedTasks();
}

class _CompletedTasks extends State<CompletedTasks> {
  List<String> kategoriler = ["none"];
  String _kategori = "Tümü";
  final _taskController = Get.put(TaskController());
  final _loginController = Get.put(LoginController());
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var notifyHelper;
  @override
  void initState() {
    super.initState();
    notifyHelper = NotifyHelper();
    notifyHelper.initializeNotification();
    notifyHelper.requestIOSPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(context),
      backgroundColor: context.theme.backgroundColor,
      body: Column(
        children: [
          ScrollConfiguration(
            behavior: NoGlowBehavior(),
            child: _checkUserLogin() == false
                ? _showTasks()
                : FutureBuilder<List<Widget>>(
                    future: _showTasksFromCloud(),
                    builder: (context, AsyncSnapshot<List<Widget>> snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          children: snapshot.data ?? [Container()],
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    }),
          ),
        ],
      ),
    );
  }

  Future<List<Widget>> _showTasksFromCloud() async {
    var counter;
    List<dynamic> degerler = [];
    List<Widget> cardlar = [];
    List<String> catS = [];
    final docRef = await _firestore
        .collection("Users")
        .doc(_loginController.googleAccount.value?.email)
        .collection("Todolar");
    await docRef.get().then(
      (result) {
        counter = result.docs.length;

        for (int i = 0; i < counter; i++) {
          degerler.addAll(result.docs[i].data().values.toList());
          kategoriler.add(degerler[2]);
          print(result.docs[i].id);
          if (degerler[7] == 1) {
            cardlar.add(
              AnimationConfiguration.staggeredList(
                position: i,
                child: SlideAnimation(
                  child: FadeInAnimation(
                      child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          _showLoginBottomSheet(result.docs[i].id);
                        },
                        child: FireStoreTasks(degerler),
                      ),
                    ],
                  )),
                ),
              ),
            );
          }
          degerler = [];
        }
      },
    );
    return cardlar;
  }

  _showLoginBottomSheet(String todo_id) {
    final docRef = _firestore
        .collection("Users")
        .doc(_loginController.googleAccount.value!.email)
        .collection("Todolar")
        .doc(todo_id);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 4),
        height: MediaQuery.of(context).size.height * 0.32,
        color: Get.isDarkMode ? darkGreyClr : Colors.white,
        child: Column(
          children: [
            Container(
              height: 6,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
            SizedBox(height: 50),
            _bottomSheetButton(
                label: "To-Do Tamamlanmadı",
                onTap: () {
                  docRef.update({'isCompleted': 0});
                  setState(() {});
                  Get.back();
                },
                clr: primaryClr,
                context: context),
            SizedBox(
              height: 20,
            ),
            _bottomSheetButton(
                label: "Kapat",
                onTap: () {
                  Get.back();
                },
                clr: Colors.red[300]!,
                context: context,
                isClose: true),
            SizedBox(
              height: 30,
            ),
          ],
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

  _showTasks() {
    return Expanded(
      child: Obx(() {
        return ListView.builder(
            itemCount: _taskController.taskList.length,
            itemBuilder: (_, index) {
              Task task = _taskController.taskList[index];
              if (task.isCompleted == 1) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  child: SlideAnimation(
                    child: FadeInAnimation(
                        child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            _showBottomSheet(context, task);
                          },
                          child: TaskTile(task),
                        ),
                      ],
                    )),
                  ),
                );
              } else if (task == null) {
                return Text(
                  'Tamamlanmış bir görev yok!',
                  style: titleStyle,
                );
              } else {
                return Container();
              }
            });
      }),
    );
  }

  _bottomSheetButton({
    required String label,
    required Function()? onTap,
    required Color clr,
    bool isClose = false,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 55,
        width: MediaQuery.of(context).size.width * 0.9,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: isClose == true
                ? Get.isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[300]!
                : clr,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isClose == true ? Colors.transparent : clr,
        ),
        child: Center(
          child: Text(
            label,
            style: isClose
                ? titleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold)
                : titleStyle.copyWith(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  _showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 4),
        height: MediaQuery.of(context).size.height * 0.32,
        color: Get.isDarkMode ? darkGreyClr : Colors.white,
        child: Column(
          children: [
            Container(
              height: 6,
              width: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
            Spacer(),
            task.isCompleted == 1
                ? _bottomSheetButton(
                    label: "To-Do Tamamlanmadı",
                    onTap: () {
                      _taskController.markTaskUncompleted(task.id!);
                      Get.back();
                    },
                    clr: primaryClr,
                    context: context)
                : _bottomSheetButton(
                    label: "To-Do Tamamlandı",
                    onTap: () {
                      _taskController.markTaskCompleted(task.id!);
                      Get.back();
                    },
                    clr: primaryClr,
                    context: context),
            _bottomSheetButton(
                label: "To-Do'yu sil",
                onTap: () {
                  _taskController.delete(task);
                  Get.back();
                },
                clr: Colors.red[300]!,
                context: context),
            SizedBox(
              height: 20,
            ),
            _bottomSheetButton(
                label: "Kapat",
                onTap: () {
                  Get.back();
                },
                clr: Colors.red[300]!,
                context: context,
                isClose: true),
            SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  _getCategory() async {
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
}
