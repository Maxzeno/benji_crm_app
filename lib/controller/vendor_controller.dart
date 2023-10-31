// ignore_for_file: unused_element, unused_local_variable, empty_catches

import 'dart:convert';
import 'dart:io';

import 'package:benji_aggregator/controller/error_controller.dart';
import 'package:benji_aggregator/model/my_vendor.dart';
import 'package:benji_aggregator/model/order.dart';
import 'package:benji_aggregator/model/product_model.dart';
import 'package:benji_aggregator/model/vendor_model.dart';
import 'package:benji_aggregator/services/api_url.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../model/business_type_model.dart';
import '../model/create_vendor_model.dart';
import 'user_controller.dart';

class VendorController extends GetxController {
  static VendorController get instance {
    return Get.find<VendorController>();
  }

  bool? isFirst;
  VendorController({this.isFirst});
  var isLoad = false.obs;
  var isLoadCreate = false.obs;
  var vendorList = <VendorModel>[].obs;
  var vendorMyList = <MyVendorModel>[].obs;
  var businessType = <BusinessType>[].obs;
  var vendorProductList = <Product>[].obs;
  var vendorOrderList = <Order>[].obs;

  // vendor pagination
  // var loadNumVendor = 10.obs;
  // var loadedAllVendor = false.obs;
  // var isLoadMoreVendor = false.obs;

  // my vendor pagination
  // var loadNumMyVendor = 10.obs;
  // var loadedAllMyVendor = false.obs;
  // var isLoadMoreMyVendor = false.obs;

  // product pagination
  var loadedAllProduct = false.obs;
  var isLoadMoreProduct = true.obs;
  var loadNumProduct = 10.obs;

  Future<void> scrollListener(scrollController, vendorId) async {
    if (VendorController.instance.loadedAllProduct.value) {
      return;
    }

    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange) {
      VendorController.instance.isLoadMoreProduct.value = true;
      update();
      await VendorController.instance.getVendorProduct(vendorId);
    }
  }

  Future getVendors() async {
    isLoad.value = true;
    late String token;
    String id = UserController.instance.user.value.id.toString();
    var url = "${Api.baseUrl}${Api.vendorList}?agent_id=$id";
    token = UserController.instance.user.value.token;
    try {
      http.Response? response = await HandleData.getApi(url, token);
      var responseData =
          await ApiProcessorController.errorState(response, isFirst ?? true);
      vendorList.value = vendorModelFromJson(responseData);
    } catch (e) {}
    isLoad.value = false;
    update();
  }

  Future getMyVendors() async {
    isLoad.value = true;
    late String token;
    String id = UserController.instance.user.value.id.toString();
    var url = "${Api.baseUrl}${Api.vendorMyList}?agent_id=$id";
    token = UserController.instance.user.value.token;
    try {
      http.Response? response = await HandleData.getApi(url, token);
      var responseData =
          await ApiProcessorController.errorState(response, isFirst ?? true);
      vendorMyList.value = myVendorModelFromJson(responseData);
    } catch (e) {}
    isLoad.value = false;
    update();
  }

  Future getVendorProduct(
    id, {
    bool first = true,
  }) async {
    if (first) {
      loadNumProduct.value = 10;
    }
    if (!first) {
      isLoadMoreProduct.value = true;
    }
    isLoad.value = true;

    var url =
        "${Api.baseUrl}${Api.getVendorProducts}$id?start=${loadNumProduct.value - 10}&end=${loadNumProduct.value}";
    String token = UserController.instance.user.value.token;
    http.Response? response = await HandleData.getApi(url, token);
    loadNumProduct.value += 10;
    var responseData = await ApiProcessorController.errorState(response);
    if (responseData == null) {
      isLoad.value = false;
      if (!first) {
        isLoadMoreProduct.value = false;
      }

      update();
      return;
    }
    List<Product> data = [];
    try {
      data = (jsonDecode(response!.body)['items'] as List)
          .map((e) => Product.fromJson(e))
          .toList();
      vendorProductList.value += data;
    } catch (e) {
      debugPrint(e.toString());
    }
    loadedAllProduct.value = data.isEmpty;
    isLoad.value = false;
    isLoadMoreProduct.value = false;

    update();
  }

  Future listVendorOrder(id, [int? end]) async {
    Future filterProductBySubCat(vendorId, subCatId) async {
      isLoad.value = true;
      late String token;
      update();
      var url =
          "${Api.baseUrl}${Api.listVendorOrders}$id?start=1&end=${end ?? 1}";
      token = UserController.instance.user.value.token;

      try {
        http.Response? response = await HandleData.getApi(url, token);
        var responseData = await ApiProcessorController.errorState(response);
        if (responseData == null) {
          return;
        }
        try {
          var save = (jsonDecode(responseData)['items'] as List)
              .map((e) => Order.fromJson(e));
        } catch (e) {
          if (kDebugMode) {
            print(e);
          }
        }
        update();
      } catch (e) {}
      isLoad.value = false;
      update();
    }
  }

  Future createVendor(SendCreateModel data, bool classify) async {
    isLoadCreate.value = true;
    late String token;
    String id = UserController.instance.user.value.id.toString();
    update();
    var url = Api.baseUrl + Api.createVendor + id;
    token = UserController.instance.user.value.token;

    try {
      http.StreamedResponse? response =
          await HandleData.streamAddVCendor(url, token, data, classify);
      if (response == null) {
        isLoadCreate.value = false;
      } else if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        var jsonData = jsonDecode(res.body);
        ApiProcessorController.successSnack(jsonData);
        isLoadCreate.value = false;
        Get.close(1);
      } else {
        final res = await http.Response.fromStream(response);
        var jsonData = jsonDecode(res.body);
        isLoadCreate.value = false;
      }
      isLoadCreate.value = false;

      update();
    } on SocketException {
      ApiProcessorController.errorSnack("Please connect to the internet");
    } catch (e) {
      ApiProcessorController.errorSnack("An error occurred. ERROR: $e");
    }
    isLoadCreate.value = false;
    update();
  }

  Future createThirdPartyVendor(SendCreateModel data, bool classify) async {
    isLoadCreate.value = true;
    late String token;
    String id = UserController.instance.user.value.id.toString();
    update();
    var url = Api.baseUrl + Api.createVendor + id;
    token = UserController.instance.user.value.token;

    try {
      http.StreamedResponse? response =
          await HandleData.streamAddVCendor(url, token, data, classify);
      if (response == null) {
        isLoadCreate.value = false;
      } else if (response.statusCode == 200) {
        final res = await http.Response.fromStream(response);
        var jsonData = jsonDecode(res.body);
        ApiProcessorController.successSnack(jsonData);
        isLoadCreate.value = false;
        Get.close(1);
      } else {
        final res = await http.Response.fromStream(response);
        var jsonData = jsonDecode(res.body);
        isLoadCreate.value = false;
      }
      isLoadCreate.value = false;

      update();
    } on SocketException {
      ApiProcessorController.errorSnack("Please connect to the internet");
    } catch (e) {
      ApiProcessorController.errorSnack("An error occurred. ERROR: $e");
    }
    isLoadCreate.value = false;
    update();
  }
}
