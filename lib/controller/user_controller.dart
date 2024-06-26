// ignore_for_file: empty_catches

import 'dart:convert';
import 'dart:developer';

import 'package:benji_aggregator/app/auth/login.dart';
import 'package:benji_aggregator/controller/api_processor_controller.dart';
import 'package:benji_aggregator/main.dart';
import 'package:benji_aggregator/model/user_model.dart';
import 'package:benji_aggregator/services/api_url.dart';
import 'package:benji_aggregator/services/helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../app/overview/overview.dart';

class UserController extends GetxController {
  static UserController get instance {
    return Get.find<UserController>();
  }

  var isLoading = false.obs;
  var user = UserModel.fromJson(null).obs;

  @override
  void onInit() {
    setUserSync();
    super.onInit();
  }

  Future checkAuth() async {
    if (await isAuthorized()) {
      Get.offAll(
        () => const OverView(),
        fullscreenDialog: true,
        curve: Curves.easeIn,
        routeName: "OverView",
        predicate: (route) => false,
        popGesture: false,
        transition: Transition.cupertinoDialog,
      );
    } else {
      Get.offAll(() => const Login());
    }
  }

  Future<void> saveUser(String user, String token) async {
    Map data = jsonDecode(user);
    data['token'] = token;

    await prefs.setString('user', jsonEncode(data));
    setUserSync();
  }

  void setUserSync() {
    String? userData = prefs.getString('user');
    bool? isVisibleCash = prefs.getBool('isVisibleCash');
    if (userData == null) {
      user.value = UserModel.fromJson(null);
    } else {
      Map<String, dynamic> userObj =
          (jsonDecode(userData) as Map<String, dynamic>);
      userObj['isVisibleCash'] = isVisibleCash;
      user.value = UserModel.fromJson(userObj);
    }
    update();
  }

  Future<bool> deleteUser() async {
    return await prefs.remove('user');
  }

  getUser() async {
    isLoading.value = true;
    update();

    final user = UserController.instance.user.value;
    http.Response? responseUserData = await HandleData.getApi(
        '${Api.baseUrl}/agents/getAgent/${user.id}', user.token);
    if (responseUserData?.statusCode != 200) {
      ApiProcessorController.errorSnack("Failed to refresh");
      isLoading.value = false;
      update();
      return;
    }
    log("User profile retrieved");
    UserController.instance.saveUser(responseUserData!.body, user.token);
    isLoading.value = false;
    update();
  }
}
