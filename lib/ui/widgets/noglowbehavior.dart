import 'package:flutter/material.dart';

class NoGlowBehavior extends ScrollBehavior {
  @override
  // ignore: override_on_non_overriding_member
  Widget buildViewPortChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }

}