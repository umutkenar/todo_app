// ignore_for_file: prefer_const_constructors, unnecessary_import, unused_field, prefer_typing_uninitialized_variables

import 'dart:convert';
import 'dart:io';

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
import 'package:todo_app/ui/completed_tasks.dart';
import 'package:todo_app/controllers/login_controller.dart';
import 'package:todo_app/ui/login_screen.dart';
import 'package:todo_app/ui/sharedtasks.dart';
import 'package:todo_app/ui/theme.dart';
import 'package:todo_app/ui/widgets/button.dart';
import 'package:todo_app/ui/widgets/firestore_tasks.dart';
import 'package:todo_app/ui/widgets/noglowbehavior.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../models/task.dart';
import 'widgets/task_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> kategoriler = ["Paylaşılanlar", "Proje", "Tümü"];
  String _kategori = "Tümü";
  final TextEditingController _sharedMailController = TextEditingController();
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
    initializeDateFormatting();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      backgroundColor: context.theme.backgroundColor,
      body: Column(
        children: [
          _addTaskBar(),
          _addCategoryBar(),
          SizedBox(
            height: 10,
          ),
          ScrollConfiguration(
            behavior: NoGlowBehavior(),
            child: _checkUserLogin() == false
                ? _showTasks()
                : Obx(() {
                    return FutureBuilder<List<Widget>>(
                        future: _showTasksFromCloud(),
                        builder:
                            (context, AsyncSnapshot<List<Widget>> snapshot) {
                          if (snapshot.hasData) {
                            return Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                    children: snapshot.data ?? [Container()]),
                              ),
                            );
                          } else {
                            return const CircularProgressIndicator();
                          }
                        });
                  }),
          ),
        ],
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

          if (_kategori == "Tümü" && degerler[7] == 0) {
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
          } else if (degerler[2] == _kategori) {
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
          for (int i = 0; i < kategoriler.length; i++) {
            if (kategoriler[i] == degerler[2]) {
              break;
            } else {
              kategoriler.add(degerler[2]);
            }
          }
          degerler = [];
        }
      },
    );
    return cardlar;
  }

  _showTasks() {
    return Expanded(
      child: Obx(() {
        return ListView.builder(
            itemCount: _taskController.taskList.length,
            itemBuilder: (_, index) {
              Task task = _taskController.taskList[index];

              if (task.repeat == 'Günlük') {
                DateTime date =
                    DateFormat("HH:mm").parse(task.startTime.toString());
                var myTime = DateFormat("HH:mm").format(date);
                notifyHelper.scheduledNotification(
                    int.parse(myTime.toString().split(":")[0]),
                    int.parse(myTime.toString().split(":")[1]),
                    task);
              }
              if (_kategori == "Tümü" && task.isCompleted == 0) {
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
              } else if (task.category == _kategori) {
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

  _showLoginBottomSheet(String todo_id) {
    final docRef = _firestore
        .collection("Users")
        .doc(_loginController.googleAccount.value!.email)
        .collection("Todolar")
        .doc(todo_id);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 4),
        height: MediaQuery.of(context).size.height * 0.38,
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
            _bottomSheetButton(
                label: "To-Do Tamamlandı",
                onTap: () {
                  docRef.update({'isCompleted': 1});
                  setState(() {});
                  Get.back();
                },
                clr: primaryClr,
                context: context),
            _bottomSheetButton(
                label: "To-Do Paylaş",
                onTap: () {
                  Get.back();
                  _displayTextInputDialog(context, todo_id);
                },
                clr: yellowClr,
                context: context),
            _bottomSheetButton(
                label: "To-Do'yu sil",
                onTap: () {
                  docRef.delete();
                  setState(() {});
                  Get.back();
                },
                clr: pinkClr,
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

  late String codeDialog;
  late String valueText;
  Future<void> _displayTextInputDialog(
      BuildContext context, String todo_id) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Todo Paylaş'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  valueText = value;
                });
              },
              controller: _sharedMailController,
              decoration: InputDecoration(hintText: "Mail giriniz"),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text('İptal'),
                style: ElevatedButton.styleFrom(primary: pinkClr),
                onPressed: () {
                  Get.back();
                },
              ),
              ElevatedButton(
                child: Text('Paylaş'),
                style: ElevatedButton.styleFrom(
                  primary: primaryClr,
                ),
                onPressed: () {
                  _shareTodo(todo_id, _sharedMailController.text);
                  Get.back();
                  setState(() {});
                },
              ),
            ],
          );
        });
  }

  _shareTodo(String todo_id, String sharedMail) {
    final shareRef = _firestore
        .collection("Users")
        .doc(sharedMail)
        .collection("Paylaşılanlar")
        .doc();
    final docRef = _firestore
        .collection("Users")
        .doc(_loginController.googleAccount.value!.email)
        .collection("Todolar");

    docRef.get().then((value) => {
          for (int i = 0; i < value.docs.length; i++)
            {
              if (todo_id == value.docs[i].id)
                {
                  shareRef.set(value.docs[i].data()),
                }
            }
        });
    List<dynamic> mailler = [];
    mailler.add(sharedMail);
    docRef.doc(todo_id).update({'Paylaşılanlar': FieldValue.delete()});
    docRef
        .doc(todo_id)
        .update({'Paylaşılanlar': FieldValue.arrayUnion(mailler)});
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
                      setState(() {});
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
    if (_checkUserLogin() == false) {
      kategoriler = await _taskController.getCategoryFromDb();
      // convert each item to a string by using JSON encoding
      final jsonList = kategoriler.map((item) => jsonEncode(item)).toList();

      // using toSet - toList strategy
      final uniqueJsonList = jsonList.toSet().toList();

      // convert each item back to the original form using JSON decoding
      kategoriler = List<String>.from(
          uniqueJsonList.map((item) => jsonDecode(item)).toList());

      kategoriler.insert(0, "Tümü");
      setState(() {
        kategoriler = kategoriler;
      });
      return kategoriler;
    }
  }

  _addCategoryBar() {
    _getCategory();

    return Container(
      margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
      decoration: BoxDecoration(
        color: primaryClr,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MyButton(width_val: 120, label: _kategori, onTap: null),
          Container(
            margin: EdgeInsets.only(right: 15),
            child: DropdownButton(
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.white),
              iconSize: 32,
              elevation: 4,
              style: subTitleStyle,
              underline: Container(height: 0),
              items: kategoriler.map<DropdownMenuItem<String>>((String value) {
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
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  _addTaskBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMd().format(DateTime.now()),
                style: subHeadingStyle,
              ),
              Text(
                "Bugün",
                style: headingStyle,
              ),
            ],
          ),
          Container(
            margin: EdgeInsets.only(left: 70),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: primaryClr,
            ),
            width: 60,
            height: 60,
            child: IconButton(
              iconSize: 30,
              icon: const Icon(Icons.add),
              tooltip: 'Yeni To-Do Ekle',
              color: Colors.white,
              onPressed: () async {
                await Get.to(() => AddTaskPage());
                _taskController.getTasks();
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: primaryClr,
            ),
            width: 60,
            height: 60,
            child: IconButton(
              color: Colors.white,
              iconSize: 30,
              icon: const Icon(Icons.check),
              tooltip: 'Tamamlanan To-Do\'lar',
              onPressed: () async {
                await Get.to(() => CompletedTasks());
                _taskController.getTasks();
              },
            ),
          ),
        ],
      ),
    );
  }

  _appBar() {
    String src = _loginController.googleAccount.value?.photoUrl ?? '';
    String name = _loginController.googleAccount.value?.displayName ?? '';
    return AppBar(
      elevation: 0,
      backgroundColor: context.theme.backgroundColor,
      leading: GestureDetector(
        onTap: () {
          ThemeService().switchTheme();
          /*notifyHelper.displayNotification(
            title: "Uygulamanın teması değiştirildi!",
            body: Get.isDarkMode ? "Açık Tema Aktif" : "Koyu Tema Aktif",
          );*/
          //notifyHelper.scheduledNotification();
        },
        child: Icon(
          Get.isDarkMode ? Icons.wb_sunny_outlined : Icons.nightlight_round,
          size: 20,
          color: Get.isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      // ignore: prefer_const_literals_to_create_immutables
      actions: [
        SizedBox(
          width: 80,
        ),
        Spacer(),
        Center(
            child: Text(
          name,
          style: headingStyle.copyWith(fontSize: 20),
        )),
        Spacer(),
        GestureDetector(
          onTap: () {
            _showAccountInfo();
          },
          child: CircleAvatar(
            radius: 30.0,
            child: src == ''
                ? Image.asset('images/profile.png')
                : ClipOval(child: Image.network(src)),
            backgroundColor: Colors.transparent,
          ),
        ),
        SizedBox(width: 20),
      ],
    );
  }

  _showAccountInfo() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.only(top: 4),
        height: MediaQuery.of(context).size.height * 0.34,
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
            _loginController.googleAccount.value == null
                ? _bottomSheetButton(
                    label: "Giriş Yap",
                    onTap: () {
                      Get.to(LoginScreen());
                    },
                    clr: primaryClr,
                    context: context)
                : _bottomSheetButton(
                    label: "Çıkış Yap",
                    onTap: () {
                      _loginController.logout();
                      Get.to(LoginScreen());
                    },
                    clr: primaryClr,
                    context: context),
            SizedBox(
              height: 20,
            ),
            _loginController.googleAccount.value == null
                ? Container()
                : _bottomSheetButton(
                    label: "Paylaşılanlar",
                    onTap: () {
                      Get.to(SharedTasks());
                    },
                    clr: pinkClr,
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
}
