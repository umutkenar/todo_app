import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:todo_app/ui/home_page.dart';
import 'package:todo_app/controllers/login_controller.dart';

import 'theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        padding: const EdgeInsets.only(top: 4),
        height: MediaQuery.of(context).size.height * 0.32,
        color: Colors.grey[100],
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 100, bottom: 50),
              child: const Image(
                image: AssetImage('images/appicon.png'),
                width: 300,
              ),
            ),
            Text(
              "To-Do+",
              style: GoogleFonts.badScript(
                textStyle: const TextStyle(
                  fontSize: 65,
                  fontWeight: FontWeight.w600,
                  color: Color.fromRGBO(123, 84, 200, 1),
                ),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await Get.to(() => const HomePage());
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                height: 55,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: const Color(0xFFff4667),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFff4667),
                ),
                child: Center(
                  child: Text(
                    "Kayıt olmadan devam et",
                    style: titleStyle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 15,
            ),
            GestureDetector(
              onTap: () async {
                await controller.login();
                print(controller.googleAccount.value?.displayName ?? 'null');
                Get.to(const HomePage());
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                height: 55,
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 2,
                    color: const Color(0xFFFFB746),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  color: const Color(0xFFFFB746),
                ),
                child: Center(
                  child: Text(
                    "Google ile giriş yap",
                    style: titleStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 45,
            ),
          ],
        ),
      ),
    );
  }
}
