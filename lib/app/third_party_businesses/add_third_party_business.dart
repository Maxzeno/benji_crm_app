// ignore_for_file: unused_local_variable, use_build_context_synchronously, unused_field, invalid_use_of_protected_member

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:benji_aggregator/controller/shopping_location_controller.dart';
import 'package:benji_aggregator/src/components/input/my_item_drop_down_menu.dart';
import 'package:benji_aggregator/src/utils/web_map.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controller/api_processor_controller.dart';
import '../../controller/business_controller.dart';
import '../../controller/category_controller.dart';
import '../../controller/form_controller.dart';
import '../../controller/latlng_detail_controller.dart';
import '../../controller/user_controller.dart';
import '../../controller/withdraw_controller.dart';
import '../../model/third_party_vendor_model.dart';
import '../../services/api_url.dart';
import '../../src/components/appbar/my_appbar.dart';
import '../../src/components/button/my_elevatedButton.dart';
import '../../src/components/input/message_textformfield.dart';
import '../../src/components/input/my_blue_textformfield.dart';
import '../../src/components/input/my_dropdown_menu.dart';
import '../../src/components/input/my_maps_textformfield.dart';
import '../../src/components/input/number_textformfield.dart';
import '../../src/components/section/location_list_tile.dart';
import '../../src/googleMaps/autocomplete_prediction.dart';
import '../../src/googleMaps/places_autocomplete_response.dart';
import '../../src/responsive/responsive_constant.dart';
import '../../src/utils/constants.dart';
import '../../src/utils/keys.dart';
import '../../src/utils/network_utils.dart';
import '../../theme/colors.dart';
import '../google_maps/get_location_on_map.dart';
import '../withdrawal/select_bank.dart';

class AddThirdPartyBusiness extends StatefulWidget {
  final ThirdPartyVendorModel? vendor;
  const AddThirdPartyBusiness({super.key, this.vendor});

  @override
  State<AddThirdPartyBusiness> createState() => _AddThirdPartyBusinessState();
}

class _AddThirdPartyBusinessState extends State<AddThirdPartyBusiness> {
  //==========================================================================================\\
  @override
  void initState() {
    super.initState();
    var vendorId = widget.vendor!.id.toString();
    var agentId = UserController.instance.user.value.id.toString();

    log("Vendor ID: $vendorId");
    log("Agent ID: $agentId");
    CategoryController.instance.getCategory();
    scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

//==========================================================================================\\

  //===================== ALL VARIABLES =======================\\
  String? shopImage;
  String? shopType;
  String? shopTypeHint;
  String bankCode = "";
  List<AutocompletePrediction> placePredictions = [];
  final selectedLocation = ValueNotifier<String?>(null);
  final LatLngDetailController latLngDetailController =
      LatLngDetailController.instance;
  String? latitude;
  String? longitude;
  bool isTyping = false;

  //======================================== GLOBAL KEYS ==============================================\\
  final _formKey = GlobalKey<FormState>();

  //===================== BOOL VALUES =======================\\
  bool isScrollToTopBtnVisible = false;
  bool accountNumberFieldIsEnabled = false;
  bool accountTypeFieldIsEnabled = false;
  bool isOpenOnSunday = false;
  bool isOpenOnMonday = false;
  bool isOpenOnTuesday = false;
  bool isOpenOnWednesday = false;
  bool isOpenOnThursday = false;
  bool isOpenOnFriday = false;
  bool isOpenOnSaturday = false;

  //============================================== CONTROLLERS =================================================\\
  final scrollController = ScrollController();
  final businessNameEC = TextEditingController();
  final businessBioEC = TextEditingController();
  final vendorBusinessTypeEC = TextEditingController();
  final addressEC = TextEditingController();
  final businessLGAEC = TextEditingController();
  final accountNameEC = TextEditingController();
  final accountNumberEC = TextEditingController();
  final accountTypeEC = TextEditingController();
  final accountBankEC = TextEditingController();
  final businessIdEC = TextEditingController();
  final countryEC = TextEditingController();
  final stateEC = TextEditingController();
  final cityEC = TextEditingController();

  //=================================== FOCUS NODES ====================================\\
  final businessNameFN = FocusNode();
  final businessBioFN = FocusNode();
  final vendorBusinessTypeFN = FocusNode();
  final businessLGAFN = FocusNode();
  final addressFN = FocusNode();
  final accountNameFN = FocusNode();
  final accountNumberFN = FocusNode();
  final accountTypeFN = FocusNode();
  final accountBankFN = FocusNode();

  final businessIdFN = FocusNode();

  //============================================= FUNCTIONS ===============================================\\

//=========================== IMAGE PICKER ====================================\\

  final ImagePicker _picker = ImagePicker();
  final ImagePicker _pickerCover = ImagePicker();
  XFile? selectedLogoImage;
  XFile? selectedCoverImage;
  //================================== function ====================================\\
  pickLogoImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
    );
    if (image != null) {
      selectedLogoImage = image;
      // Get.back();
      setState(() {});
    }
  }

  pickCoverImage(ImageSource source) async {
    final XFile? image = await _pickerCover.pickImage(
      source: source,
    );
    if (image != null) {
      selectedCoverImage = image;
      // Get.back();
      setState(() {});
    }
  }

  //Google Maps
  setLocation(index) async {
    final newLocation = placePredictions[index].description!;
    selectedLocation.value = newLocation;

    setState(() {
      addressEC.text = newLocation;
    });

    List location = await parseLatLng(newLocation);
    latitude = location[0];
    longitude = location[1];
  }

// select bank
  selectBank() async {
    await WithdrawController.instance.getBanks();
    final result = await Get.to(
      () => const SelectBank(),
      routeName: 'SelectBank',
      duration: const Duration(milliseconds: 300),
      fullscreenDialog: true,
      curve: Curves.easeIn,
      preventDuplicates: true,
      popGesture: true,
      transition: Transition.downToUp,
    );
    if (result != null) {
      final newBankName = result['name'];
      final newBankCode = result['code'];

      setState(() {
        accountBankEC.text = newBankName;
        bankCode = newBankCode;
        accountNumberFieldIsEnabled = true;
      });
    }
  }

  void placeAutoComplete(String query) async {
    Uri uri = Uri.https(
        "maps.googleapis.com",
        '/maps/api/place/autocomplete/json', //unencoder path
        {
          "input": query, //query params
          "key": googlePlacesApiKey, //google places api key
        });

    String? response = await NetworkUtility.fetchUrl(uri);
    PlaceAutocompleteResponse result =
        PlaceAutocompleteResponse.parseAutoCompleteResult(response!);
    if (result.predictions != null) {
      setState(() {
        placePredictions = result.predictions!;
      });
    }
  }

  void getLocationOnMap() async {
    var result = await Get.to(
      () => const GetLocationOnMap(),
      routeName: 'GetLocationOnMap',
      duration: const Duration(milliseconds: 300),
      fullscreenDialog: true,
      curve: Curves.easeIn,
      preventDuplicates: true,
      popGesture: true,
      transition: Transition.rightToLeft,
    );
    final LatLngDetailController latLngDetailController =
        LatLngDetailController.instance;

    if (latLngDetailController.isNotEmpty()) {
      setState(() {
        latitude = latLngDetailController.latLngDetail.value[0];
        longitude = latLngDetailController.latLngDetail.value[1];
        addressEC.text = latLngDetailController.latLngDetail.value[2];
        latLngDetailController.setEmpty();
      });
    }

    log("LATLNG: $latitude,$longitude");
    log(addressEC.text);
  }

  //========================== Save data ==================================\\
  Future<void> saveChanges() async {
    if (await checkXFileSize(selectedLogoImage)) {
      ApiProcessorController.errorSnack('Business logo image is too large');
      return;
    }
    if (await checkXFileSize(selectedCoverImage)) {
      ApiProcessorController.errorSnack('Business cover image is too large');
      return;
    }
    log("accountType: ${accountTypeEC.text}");
    log("shop_type: ${vendorBusinessTypeEC.text}");
    if (selectedLogoImage == null) {
      ApiProcessorController.errorSnack("Please select a business logo");
      return;
    }
    if (selectedCoverImage == null) {
      ApiProcessorController.errorSnack("Please select a cover image");
      return;
    }
    if (latitude == null || longitude == null) {
      ApiProcessorController.errorSnack("Please select an address");
      return;
    }
    if (shopType == null &&
        vendorBusinessTypeEC.text.isEmpty &&
        shopType!.isEmpty) {
      ApiProcessorController.errorSnack("Please select a type of business");
      return;
    }
    if (countryEC.text.isEmpty) {
      ApiProcessorController.errorSnack("Please choose a country");
      return;
    }
    if (stateEC.text.isEmpty) {
      ApiProcessorController.errorSnack("Please choose a state");
      return;
    }
    if (cityEC.text.isEmpty) {
      ApiProcessorController.errorSnack("Please choose a city");
      return;
    }

    Map data = {
      "address": addressEC.text,
      "latitude": latitude,
      "longitude": longitude,
      "accountBank": accountBankEC.text,
      "accountName": accountNameEC.text,
      "accountNumber": accountNumberEC.text,
      "accountType": accountTypeEC.text,
      // "country": countryValue.contains("Nigeria") ? "NG" : "",
      "country": countryEC.text,
      "state": stateEC.text,
      "city": cityEC.text,
      "lga": businessLGAEC.text,
      "businessId": businessIdEC.text,
      "shop_name": businessNameEC.text,
      "monOpeningHours":
          isOpenOnMonday ? mondayOpeningTimeOfDay.format(context) : "CLOSED",
      "monClosingHours":
          isOpenOnMonday ? mondayClosingTimeOfDay.format(context) : "CLOSED",
      "tueOpeningHours":
          isOpenOnTuesday ? tuesdayOpeningTimeOfDay.format(context) : "CLOSED",
      "tueClosingHours":
          isOpenOnTuesday ? tuesdayClosingTimeOfDay.format(context) : "CLOSED",
      "wedOpeningHours": isOpenOnWednesday
          ? "CLOSED"
          : wednesdayOpeningTimeOfDay.format(context),
      "wedClosingHours": isOpenOnWednesday
          ? wednesdayClosingTimeOfDay.format(context)
          : "CLOSED",
      "thursOpeningHours": isOpenOnThursday
          ? thursdayOpeningTimeOfDay.format(context)
          : "CLOSED",
      "thursClosingHours": isOpenOnThursday
          ? thursdayClosingTimeOfDay.format(context)
          : "CLOSED",
      "friOpeningHours":
          isOpenOnFriday ? fridayOpeningTimeOfDay.format(context) : "CLOSED",
      "friClosingHours":
          isOpenOnFriday ? fridayClosingTimeOfDay.format(context) : "CLOSED",
      "satOpeningHours": isOpenOnSaturday
          ? saturdayOpeningTimeOfDay.format(context)
          : "CLOSED",
      "satClosingHours": isOpenOnSaturday
          ? saturdayClosingTimeOfDay.format(context)
          : "CLOSED",
      "sunWeekOpeningHours":
          isOpenOnSunday ? sundayOpeningTimeOfDay.format(context) : "CLOSED",
      "sunWeekClosingHours":
          isOpenOnSunday ? sundayClosingTimeOfDay.format(context) : "CLOSED",
      "businessBio": businessBioEC.text,
      "shop_type": vendorBusinessTypeEC.text,
    };

    log("This is the data: $data");

    log("shop_image: ${selectedLogoImage?.path}");
    log("coverImage: ${selectedCoverImage?.path}");

    var vendorId = widget.vendor?.id.toString();
    var agentId = UserController.instance.user.value.id.toString();

    log("Vendor ID: $vendorId");
    log("Agent ID: $agentId");

    String url =
        "${Api.baseUrl}${Api.agentCreateVendorBusiness}$vendorId/$agentId";

    log(url);

    await FormController.instance.postAuthstream2(
      url,
      data,
      {
        'shop_image': selectedLogoImage,
        'coverImage': selectedCoverImage,
      },
      'agentCreateVendorBusiness',
    );
    if (FormController.instance.status.toString().startsWith('20')) {
      await BusinessController.instance.refreshData(vendorId!, agentId);
      // await PushNotificationController.showNotification(
      //   title: "Success.",
      //   body: "Your business profile has been successfully updated.",
      // );

      Get.close(1);
    }
  }

  //=========================== WIDGETS ====================================\\
  uploadBusinessLogo() => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            "Upload Business Logo",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          kSizedBox,
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        pickLogoImage(ImageSource.camera);
                        Get.close(0);
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                            side: const BorderSide(
                              width: 0.5,
                              color: kGreyColor1,
                            ),
                          ),
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.camera,
                            color: kAccentColor,
                          ),
                        ),
                      ),
                    ),
                    kHalfSizedBox,
                    const Text("Camera"),
                  ],
                ),
                kWidthSizedBox,
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        pickLogoImage(ImageSource.gallery);
                        Get.close(0);
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                            side: const BorderSide(
                              width: 0.5,
                              color: kGreyColor1,
                            ),
                          ),
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.image,
                            color: kAccentColor,
                          ),
                        ),
                      ),
                    ),
                    kHalfSizedBox,
                    const Text("Gallery"),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  uploadBusinessCoverImage() => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            "Upload Cover Image",
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          kSizedBox,
          Padding(
            padding: const EdgeInsets.only(left: 10, bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        pickCoverImage(ImageSource.camera);
                        Get.close(0);
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                            side: const BorderSide(
                              width: 0.5,
                              color: kGreyColor1,
                            ),
                          ),
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.camera,
                            color: kAccentColor,
                          ),
                        ),
                      ),
                    ),
                    kHalfSizedBox,
                    const Text("Camera"),
                  ],
                ),
                kWidthSizedBox,
                Column(
                  children: [
                    InkWell(
                      onTap: () {
                        pickCoverImage(ImageSource.gallery);
                        Get.close(0);
                      },
                      borderRadius: BorderRadius.circular(100),
                      child: Container(
                        height: 60,
                        width: 60,
                        decoration: ShapeDecoration(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                            side: const BorderSide(
                              width: 0.5,
                              color: kGreyColor1,
                            ),
                          ),
                        ),
                        child: const Center(
                          child: FaIcon(
                            FontAwesomeIcons.image,
                            color: kAccentColor,
                          ),
                        ),
                      ),
                    ),
                    kHalfSizedBox,
                    const Text("Gallery"),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  //===================== Scroll to Top ==========================\\
  Future<void> _scrollToTop() async {
    await scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    setState(() {
      isScrollToTopBtnVisible = false;
    });
  }

  Future<void> _scrollListener() async {
    if (scrollController.position.pixels >= 100 &&
        isScrollToTopBtnVisible != true) {
      setState(() {
        isScrollToTopBtnVisible = true;
      });
    }
    if (scrollController.position.pixels < 100 &&
        isScrollToTopBtnVisible == true) {
      setState(() {
        isScrollToTopBtnVisible = false;
      });
    }
  }

  //Time of Day variables
  //Opening Time
  TimeOfDay sundayOpeningTimeOfDay = const TimeOfDay(hour: 08, minute: 00);
  TimeOfDay mondayOpeningTimeOfDay = const TimeOfDay(hour: 08, minute: 00);
  TimeOfDay tuesdayOpeningTimeOfDay = const TimeOfDay(hour: 08, minute: 00);
  TimeOfDay wednesdayOpeningTimeOfDay = const TimeOfDay(hour: 08, minute: 00);
  TimeOfDay thursdayOpeningTimeOfDay = const TimeOfDay(hour: 08, minute: 00);
  TimeOfDay fridayOpeningTimeOfDay = const TimeOfDay(hour: 08, minute: 00);
  TimeOfDay saturdayOpeningTimeOfDay = const TimeOfDay(hour: 08, minute: 00);

  //Closing time
  TimeOfDay sundayClosingTimeOfDay = const TimeOfDay(hour: 17, minute: 00);
  TimeOfDay mondayClosingTimeOfDay = const TimeOfDay(hour: 17, minute: 00);
  TimeOfDay tuesdayClosingTimeOfDay = const TimeOfDay(hour: 17, minute: 00);
  TimeOfDay wednesdayClosingTimeOfDay = const TimeOfDay(hour: 17, minute: 00);
  TimeOfDay thursdayClosingTimeOfDay = const TimeOfDay(hour: 17, minute: 00);
  TimeOfDay fridayClosingTimeOfDay = const TimeOfDay(hour: 17, minute: 00);
  TimeOfDay saturdayClosingTimeOfDay = const TimeOfDay(hour: 17, minute: 00);

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;

    return GestureDetector(
      onTap: (() => FocusManager.instance.primaryFocus?.unfocus()),
      child: Scaffold(
        appBar: MyAppBar(
          title: "Add Business",
          elevation: 0,
          actions: const [],
          backgroundColor: kPrimaryColor,
        ),
        bottomNavigationBar: GetBuilder<FormController>(
            init: FormController(),
            builder: (saving) {
              return Container(
                color: kPrimaryColor,
                padding: const EdgeInsets.all(kDefaultPadding),
                child: MyElevatedButton(
                  onPressed: (() async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();
                      saveChanges();
                    }
                  }),
                  isLoading: saving.isLoad.value,
                  title: "Save",
                ),
              );
            }),
        floatingActionButton: isScrollToTopBtnVisible
            ? FloatingActionButton(
                onPressed: _scrollToTop,
                mini: deviceType(media.width) > 2 ? false : true,
                backgroundColor: kAccentColor,
                foregroundColor: kPrimaryColor,
                enableFeedback: true,
                mouseCursor: SystemMouseCursors.click,
                tooltip: "Scroll to top",
                hoverColor: kAccentColor,
                hoverElevation: 50.0,
                child: const FaIcon(FontAwesomeIcons.chevronUp, size: 18),
              )
            : const SizedBox(),
        body: SafeArea(
            child: Scrollbar(
          controller: scrollController,
          child: ListView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(kDefaultPadding),
            children: [
              const Text(
                "Business content",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                "This is visible to users",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kAccentColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              kSizedBox,
              DottedBorder(
                color: kLightGreyColor,
                borderPadding: const EdgeInsets.all(3),
                padding: const EdgeInsets.all(kDefaultPadding / 2),
                borderType: BorderType.RRect,
                radius: const Radius.circular(20),
                child: Column(
                  children: [
                    selectedLogoImage == null
                        ? Container(
                            padding: const EdgeInsets.all(kDefaultPadding),
                            decoration: const ShapeDecoration(
                              shape: CircleBorder(
                                side: BorderSide(
                                  width: 0.50,
                                  color: kGreyColor1,
                                ),
                              ),
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.image,
                                color: kAccentColor,
                              ),
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: kTransparentColor,
                            radius: 60,
                            child: Center(
                              child: SizedBox(
                                height: 120,
                                width: 120,
                                child: kIsWeb
                                    ? Image.network(
                                        selectedLogoImage!.path,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        fit: BoxFit.cover,
                                        File(
                                          selectedLogoImage!.path,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          elevation: 20,
                          barrierColor: kBlackColor.withOpacity(0.8),
                          showDragHandle: true,
                          useSafeArea: true,
                          isDismissible: true,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(kDefaultPadding),
                            ),
                          ),
                          enableDrag: true,
                          builder: ((builder) => uploadBusinessLogo()),
                        );
                      },
                      splashColor: kAccentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Text(
                          'Upload business logo',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kAccentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    kSizedBox,
                    selectedCoverImage == null
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            height: deviceType(media.width) > 2 ? 200 : 120,
                            decoration: ShapeDecoration(
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  width: 0.50,
                                  color: Color(0xFFE6E6E6),
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Center(
                              child: Image.asset(
                                "assets/icons/image-upload.png",
                              ),
                            ),
                          )
                        : kIsWeb
                            ? Container(
                                padding: const EdgeInsets.all(20),
                                height: deviceType(media.width) > 2 ? 200 : 120,
                                decoration: ShapeDecoration(
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      width: 0.50,
                                      color: Color(0xFFE6E6E6),
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Center(
                                  child:
                                      Image.network(selectedCoverImage!.path),
                                ),
                              )
                            : Container(
                                height: 200,
                                decoration: ShapeDecoration(
                                  image: DecorationImage(
                                    image: FileImage(
                                        File(selectedCoverImage!.path)),
                                    fit: BoxFit.cover,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    side: const BorderSide(
                                      width: 0.50,
                                      color: Color(0xFFE6E6E6),
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          elevation: 20,
                          barrierColor: kBlackColor.withOpacity(0.8),
                          showDragHandle: true,
                          useSafeArea: true,
                          isDismissible: true,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(kDefaultPadding),
                            ),
                          ),
                          enableDrag: true,
                          builder: ((builder) => uploadBusinessCoverImage()),
                        );
                      },
                      splashColor: kAccentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: const Text(
                          'Upload cover image',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: kAccentColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              kSizedBox,
              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Business Name",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    kSizedBox,
                    MyBlueTextFormField(
                      controller: businessNameEC,
                      validator: (value) {
                        if (value == null || value == '') {
                          businessNameFN.requestFocus();

                          return "Field cannot be empty";
                        }
                        if (value.toString().length < 2) {
                          "Please enter a valid name";
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      focusNode: businessNameFN,
                      hintText: "Name of the business",
                      textInputType: TextInputType.text,
                    ),
                    kSizedBox,
                    const Text(
                      "Business Identification Number/CAC Number",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    kSizedBox,
                    NumberTextFormField(
                      controller: businessIdEC,
                      validator: (value) {
                        if (value == null || value == '') {
                          return "Field cannot be empty";
                        } else if (value.toString().length < 14) {
                          return "Must be 14 characters";
                        }
                        return null;
                      },
                      maxlength: 14,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSaved: (value) {
                        businessIdEC.text = value!;
                      },
                      textInputAction: TextInputAction.next,
                      focusNode: businessIdFN,
                      hintText: "Enter your registered business number",
                    ),
                    kSizedBox,
                    const Text(
                      "Type of Business",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    kSizedBox,
                    GetBuilder<CategoryController>(
                      init: CategoryController(),
                      initState: (state) {
                        CategoryController.instance.getCategory();
                      },
                      builder: (controller) {
                        return MyDropDownMenu(
                          controller: vendorBusinessTypeEC,
                          hintText: "E.g Restaurant, Auto Dealer, etc",
                          enableSearch: true,
                          dropdownMenuEntries:
                              controller.category.value.isEmpty &&
                                      controller.isLoad.value
                                  ? [
                                      const DropdownMenuEntry(
                                        value: 'Loading...',
                                        label: 'Loading...',
                                        enabled: false,
                                      )
                                    ]
                                  : controller.category
                                      .map(
                                        (item) => DropdownMenuEntry(
                                          value: item.id,
                                          label: item.name,
                                        ),
                                      )
                                      .toList(),
                        );
                      },
                    ),
                    kSizedBox,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            "Business hours".toUpperCase(),
                            style: const TextStyle(
                              fontSize: 20,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        kSizedBox,

                        const Text(
                          "Sunday",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isOpenOnSunday
                                  ? "Open".toUpperCase()
                                  : "Closed".toUpperCase(),
                              style: const TextStyle(
                                color: kTextBlackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            kHalfWidthSizedBox,
                            Switch(
                              value: isOpenOnSunday,
                              activeColor: kSuccessColor,
                              onChanged: (value) {
                                setState(() {
                                  isOpenOnSunday = !isOpenOnSunday;
                                });
                              },
                            ),
                          ],
                        ),
                        isOpenOnSunday ? kHalfSizedBox : const SizedBox(),
                        isOpenOnSunday
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sundayOpeningTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 08,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                sundayOpeningTimeOfDay = value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  kHalfWidthSizedBox,
                                  const Text(
                                    "to",
                                    style: TextStyle(
                                      color: kTextBlackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  kHalfWidthSizedBox,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sundayClosingTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 17,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                sundayClosingTimeOfDay = value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),

                        const Text(
                          "Monday",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isOpenOnMonday
                                  ? "Open".toUpperCase()
                                  : "Closed".toUpperCase(),
                              style: const TextStyle(
                                color: kTextBlackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            kHalfWidthSizedBox,
                            Switch(
                              value: isOpenOnMonday,
                              activeColor: kSuccessColor,
                              onChanged: (value) {
                                setState(() {
                                  isOpenOnMonday = !isOpenOnMonday;
                                });
                              },
                            ),
                          ],
                        ),
                        isOpenOnMonday ? kHalfSizedBox : const SizedBox(),
                        isOpenOnMonday
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mondayOpeningTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 08,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                mondayOpeningTimeOfDay = value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  kHalfWidthSizedBox,
                                  const Text(
                                    "to",
                                    style: TextStyle(
                                      color: kTextBlackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  kHalfWidthSizedBox,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mondayClosingTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 17,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                mondayClosingTimeOfDay = value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        const Text(
                          "Tuesday",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isOpenOnTuesday
                                  ? "Open".toUpperCase()
                                  : "Closed".toUpperCase(),
                              style: const TextStyle(
                                color: kTextBlackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            kHalfWidthSizedBox,
                            Switch(
                              value: isOpenOnTuesday,
                              activeColor: kSuccessColor,
                              onChanged: (value) {
                                setState(() {
                                  isOpenOnTuesday = !isOpenOnTuesday;
                                });
                              },
                            ),
                          ],
                        ),
                        isOpenOnTuesday ? kHalfSizedBox : const SizedBox(),
                        isOpenOnTuesday
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tuesdayOpeningTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 08,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                tuesdayOpeningTimeOfDay = value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  kHalfWidthSizedBox,
                                  const Text(
                                    "to",
                                    style: TextStyle(
                                      color: kTextBlackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  kHalfWidthSizedBox,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tuesdayClosingTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 17,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                tuesdayClosingTimeOfDay = value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        const Text(
                          "Wednesday",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isOpenOnWednesday
                                  ? "Open".toUpperCase()
                                  : "Closed".toUpperCase(),
                              style: const TextStyle(
                                color: kTextBlackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            kHalfWidthSizedBox,
                            Switch(
                              value: isOpenOnWednesday,
                              activeColor: kSuccessColor,
                              onChanged: (value) {
                                setState(() {
                                  isOpenOnWednesday = !isOpenOnWednesday;
                                });
                              },
                            ),
                          ],
                        ),
                        isOpenOnWednesday ? kHalfSizedBox : const SizedBox(),
                        isOpenOnWednesday
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wednesdayOpeningTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 08,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                wednesdayOpeningTimeOfDay =
                                                    value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  kHalfWidthSizedBox,
                                  const Text(
                                    "to",
                                    style: TextStyle(
                                      color: kTextBlackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  kHalfWidthSizedBox,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        wednesdayClosingTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 17,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                wednesdayClosingTimeOfDay =
                                                    value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        const Text(
                          "Thursday",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isOpenOnThursday
                                  ? "Open".toUpperCase()
                                  : "Closed".toUpperCase(),
                              style: const TextStyle(
                                color: kTextBlackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            kHalfWidthSizedBox,
                            Switch(
                              value: isOpenOnThursday,
                              activeColor: kSuccessColor,
                              onChanged: (value) {
                                setState(() {
                                  isOpenOnThursday = !isOpenOnThursday;
                                });
                              },
                            ),
                          ],
                        ),
                        isOpenOnThursday ? kHalfSizedBox : const SizedBox(),
                        isOpenOnThursday
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        thursdayOpeningTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 08,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                thursdayOpeningTimeOfDay =
                                                    value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  kHalfWidthSizedBox,
                                  const Text(
                                    "to",
                                    style: TextStyle(
                                      color: kTextBlackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  kHalfWidthSizedBox,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        thursdayClosingTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 17,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                thursdayClosingTimeOfDay =
                                                    value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        const Text(
                          "Friday",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isOpenOnFriday
                                  ? "Open".toUpperCase()
                                  : "Closed".toUpperCase(),
                              style: const TextStyle(
                                color: kTextBlackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            kHalfWidthSizedBox,
                            Switch(
                              value: isOpenOnFriday,
                              activeColor: kSuccessColor,
                              onChanged: (value) {
                                setState(() {
                                  isOpenOnFriday = !isOpenOnFriday;
                                });
                              },
                            ),
                          ],
                        ),
                        isOpenOnFriday ? kHalfSizedBox : const SizedBox(),
                        isOpenOnFriday
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fridayOpeningTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 08,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                fridayOpeningTimeOfDay = value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  kHalfWidthSizedBox,
                                  const Text(
                                    "to",
                                    style: TextStyle(
                                      color: kTextBlackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  kHalfWidthSizedBox,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        fridayClosingTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 17,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                fridayClosingTimeOfDay = value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        const Text(
                          "Saturday",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              isOpenOnSaturday
                                  ? "Open".toUpperCase()
                                  : "Closed".toUpperCase(),
                              style: const TextStyle(
                                color: kTextBlackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            kHalfWidthSizedBox,
                            Switch(
                              value: isOpenOnSaturday,
                              activeColor: kSuccessColor,
                              onChanged: (value) {
                                setState(() {
                                  isOpenOnSaturday = !isOpenOnSaturday;
                                });
                              },
                            ),
                          ],
                        ),
                        isOpenOnSaturday ? kHalfSizedBox : const SizedBox(),
                        isOpenOnSaturday
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        saturdayOpeningTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 08,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                saturdayOpeningTimeOfDay =
                                                    value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  kHalfWidthSizedBox,
                                  const Text(
                                    "to",
                                    style: TextStyle(
                                      color: kTextBlackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  kHalfWidthSizedBox,
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        saturdayClosingTimeOfDay
                                            .format(context)
                                            .toString(),
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(
                                          color: kTextBlackColor,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          showTimePicker(
                                            context: context,
                                            initialTime: const TimeOfDay(
                                              hour: 17,
                                              minute: 00,
                                            ),
                                          ).then((value) {
                                            if (value != null) {
                                              setState(() {
                                                saturdayClosingTimeOfDay =
                                                    value;
                                              });
                                            }
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.all(2),
                                        ),
                                        child: const Text(
                                          "Change",
                                          style: TextStyle(
                                            color: kAccentColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : const SizedBox(),
                        kSizedBox,

                        // Account section
                        const Text(
                          'Bank Name',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        kHalfSizedBox,
                        GetBuilder<WithdrawController>(
                          builder: (controller) {
                            return InkWell(
                              onTap: controller.listOfBanks.isEmpty &&
                                      controller.isLoad.value
                                  ? null
                                  : selectBank,
                              borderRadius: BorderRadius.circular(20),
                              child: MyBlueTextFormField(
                                controller: accountBankEC,
                                isEnabled: false,
                                textInputAction: TextInputAction.next,
                                focusNode: accountBankFN,
                                onChanged: (value) {},
                                hintText: controller.listOfBanks.isEmpty &&
                                        controller.isLoad.value
                                    ? "Loading..."
                                    : "Select a bank",
                                suffixIcon: const FaIcon(
                                  FontAwesomeIcons.chevronDown,
                                  size: 20,
                                  color: kAccentColor,
                                ),
                                textInputType: TextInputType.name,
                                validator: (value) {
                                  if (value == null ||
                                      value!.isEmpty ||
                                      accountBankEC.text.isEmpty) {
                                    return "Select a bank";
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  setState(() {
                                    accountBankEC.text = value!;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                        kSizedBox,
                        const Text(
                          'Account Number',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        kHalfSizedBox,
                        NumberTextFormField(
                          controller: accountNumberEC,
                          focusNode: accountNumberFN,
                          enabled: accountNumberFieldIsEnabled,
                          hintText: accountNumberFieldIsEnabled
                              ? "Enter the account number here"
                              : "Select a bank first",
                          textInputAction: TextInputAction.next,
                          maxlength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (value) {
                            if (value.length >= 10) {
                              WithdrawController.instance.validateBankNumbers(
                                accountNumberEC.text,
                                bankCode,
                              );
                              setState(() {
                                accountTypeFieldIsEnabled = true;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value == '') {
                              accountNumberFN.requestFocus();
                              return "Enter your account number";
                            }
                            if (accountNumberEC.text.isNotEmpty &&
                                accountNumberEC.text.length < 10) {
                              return "Must be at least 10 characters";
                            }
                            return null;
                          },
                          onSaved: (value) {},
                        ),
                        GetBuilder<WithdrawController>(
                          builder: (controller) {
                            if (controller.isLoadValidateAccount.value) {
                              return Text(
                                'Loading...',
                                style: TextStyle(
                                  color: kAccentColor.withOpacity(0.8),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            }
                            if (accountNumberEC.text.length < 10) {
                              return const Text('');
                            }
                            accountNameEC.text = WithdrawController.instance
                                .validateAccount.value.responseBody.accountName;
                            log("This is the account name: ${accountNameEC.text}");
                            return Text(
                              controller.validateAccount.value.requestSuccessful
                                  ? controller.validateAccount.value
                                      .responseBody.accountName
                                  // : controller.validateAccount.value
                                  //     .responseBody.accountName,
                                  : 'Bank Name not found',
                              style: TextStyle(
                                color: controller
                                        .validateAccount.value.requestSuccessful
                                    ? kSuccessColor
                                    : kAccentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                        kSizedBox,
                        const Text(
                          "Account type",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        kSizedBox,
                        MyDropDownMenu(
                          controller: accountTypeEC,
                          enabled: accountTypeFieldIsEnabled,
                          hintText: !accountTypeFieldIsEnabled
                              ? "Enter your account number"
                              : "Savings, current, etc",
                          dropdownMenuEntries: !accountTypeFieldIsEnabled
                              ? const [
                                  DropdownMenuEntry(
                                    value: 'disabled',
                                    label: 'Please enter your account number',
                                    enabled: false,
                                  ),
                                ]
                              : const [
                                  DropdownMenuEntry(
                                    value: 'savings',
                                    label: 'Savings',
                                    enabled: true,
                                  ),
                                  DropdownMenuEntry(
                                    value: 'current',
                                    label: 'Current',
                                    enabled: true,
                                  ),
                                ],
                        ),

                        kSizedBox,

                        //  Address and location
                        const Text(
                          'Country',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        kSizedBox,
                        GetBuilder<ShoppingLocationController>(
                          initState: (state) => ShoppingLocationController
                              .instance
                              .getShoppingLocationCountries(),
                          builder: (controller) => ItemDropDownMenu(
                            onSelected: (value) {
                              controller.getShoppingLocationState(value);
                              countryEC.text = value!.toString();
                              setState(() {});
                            },
                            itemEC: countryEC,
                            hintText: "Choose country",
                            dropdownMenuEntries:
                                controller.isLoadCountry.value &&
                                        controller.country.isEmpty
                                    ? [
                                        const DropdownMenuEntry(
                                            value: 'Loading...',
                                            label: 'Loading...',
                                            enabled: false),
                                      ]
                                    : controller.country.isEmpty
                                        ? [
                                            const DropdownMenuEntry(
                                                value: 'EMPTY',
                                                label: 'EMPTY',
                                                enabled: false),
                                          ]
                                        : controller.country
                                            .map(
                                              (item) => DropdownMenuEntry(
                                                value: item.countryCode,
                                                label: item.countryName,
                                              ),
                                            )
                                            .toList(),
                          ),
                        ),
                        kSizedBox,
                        const Text(
                          "Select state",
                          style: TextStyle(
                            fontSize: 17.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        kHalfSizedBox,
                        GetBuilder<ShoppingLocationController>(
                          builder: (controller) => ItemDropDownMenu(
                            onSelected: (value) {
                              stateEC.text = value!.toString();
                              controller.getShoppingLocationCity(value);
                              setState(() {});
                            },
                            itemEC: stateEC,
                            hintText: "Choose state",
                            dropdownMenuEntries: countryEC.text.isEmpty
                                ? [
                                    const DropdownMenuEntry(
                                        value: 'Select Country',
                                        label: 'Select Country',
                                        enabled: false),
                                  ]
                                : controller.isLoadState.value &&
                                        controller.state.isEmpty
                                    ? [
                                        const DropdownMenuEntry(
                                            value: 'Loading...',
                                            label: 'Loading...',
                                            enabled: false),
                                      ]
                                    : controller.state.isEmpty
                                        ? [
                                            const DropdownMenuEntry(
                                                value: 'EMPTY',
                                                label: 'EMPTY',
                                                enabled: false),
                                          ]
                                        : controller.state
                                            .map(
                                              (item) => DropdownMenuEntry(
                                                value: item.stateCode,
                                                label: item.stateName,
                                              ),
                                            )
                                            .toList(),
                          ),
                        ),
                        kSizedBox,
                        const Text(
                          "Select city",
                          style: TextStyle(
                            fontSize: 17.6,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        kHalfSizedBox,
                        GetBuilder<ShoppingLocationController>(
                          builder: (controller) => ItemDropDownMenu(
                            onSelected: (value) {
                              cityEC.text = value!.toString();
                              setState(() {});
                            },
                            itemEC: cityEC,
                            hintText: "Choose city",
                            dropdownMenuEntries: stateEC.text.isEmpty
                                ? [
                                    const DropdownMenuEntry(
                                        value: 'Select State',
                                        label: 'Select State',
                                        enabled: false),
                                  ]
                                : controller.isLoadCity.value &&
                                        controller.city.isEmpty
                                    ? [
                                        const DropdownMenuEntry(
                                            value: 'Loading...',
                                            label: 'Loading...',
                                            enabled: false),
                                      ]
                                    : controller.city.isEmpty
                                        ? [
                                            const DropdownMenuEntry(
                                                value: 'EMPTY',
                                                label: 'EMPTY',
                                                enabled: false),
                                          ]
                                        : controller.city
                                            .map(
                                              (item) => DropdownMenuEntry(
                                                value: item.cityCode,
                                                label: item.cityName,
                                              ),
                                            )
                                            .toList(),
                          ),
                        ),
                        kSizedBox,
                        const Text(
                          "Local Government Area",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        kSizedBox,
                        MyBlueTextFormField(
                          controller: businessLGAEC,
                          validator: (value) {
                            if (value == null || value == '') {
                              businessLGAFN.requestFocus();

                              return "Field cannot be empty";
                            }
                            if (value.toString().length < 2) {
                              "Please enter a valid value";
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          focusNode: businessLGAFN,
                          hintText: "Enter the LGA",
                          textInputType: TextInputType.text,
                        ),
                        kSizedBox,
                        const Text(
                          "Address",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        kHalfSizedBox,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location on Google maps',
                              style: TextStyle(
                                color: kTextBlackColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            kHalfSizedBox,
                            MyMapsTextFormField(
                              controller: addressEC,
                              validator: (value) {
                                if (value == null || value == "") {
                                  addressFN.requestFocus();
                                  return "Enter a location";
                                }
                                if (latitude == null || longitude == null) {
                                  addressFN.requestFocus();
                                  return "Please select a location so we can get the coordinates";
                                }
                                return null;
                              },
                              onChanged: (value) {
                                placeAutoComplete(value);
                                setState(() {
                                  selectedLocation.value = value;
                                  isTyping = true;
                                });

                                log(
                                  "ONCHANGED VALUE: ${selectedLocation.value}",
                                );
                              },
                              textInputAction: TextInputAction.done,
                              focusNode: addressFN,
                              hintText: "Search a location",
                              textInputType: TextInputType.text,
                              prefixIcon: const Padding(
                                padding: EdgeInsets.all(kDefaultPadding),
                                child: FaIcon(
                                  FontAwesomeIcons.locationDot,
                                  color: kAccentColor,
                                  size: 18,
                                ),
                              ),
                            ),
                            kSizedBox,
                            Divider(
                              height: 10,
                              thickness: 2,
                              color: kLightGreyColor,
                            ),
                            ElevatedButton.icon(
                              onPressed: getLocationOnMap,
                              icon: const FaIcon(
                                FontAwesomeIcons.locationArrow,
                                color: kAccentColor,
                                size: 18,
                              ),
                              label: const Text("Locate on map"),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: kLightGreyColor,
                                foregroundColor: kTextBlackColor,
                                fixedSize: Size(media.width, 40),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            Divider(
                              height: 10,
                              thickness: 2,
                              color: kLightGreyColor,
                            ),
                            const Text(
                              "Suggestions:",
                              style: TextStyle(
                                color: kTextBlackColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            kHalfSizedBox,
                            SizedBox(
                              height: () {
                                if (isTyping == false) {
                                  return 0.0;
                                }
                                if (isTyping == true) {
                                  return 150.0;
                                }
                              }(),
                              child: Scrollbar(
                                controller: scrollController,
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(),
                                  shrinkWrap: true,
                                  itemCount: placePredictions.length,
                                  itemBuilder: (context, index) =>
                                      LocationListTile(
                                    onTap: () => setLocation(index),
                                    location:
                                        placePredictions[index].description ??
                                            '',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        kSizedBox,

                        // business bio
                        const Text(
                          "Business description",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        kSizedBox,
                        MyMessageTextFormField(
                          controller: businessBioEC,
                          validator: (value) {
                            if (value == null || value == '') {
                              businessBioFN.requestFocus();
                              return "Field cannot be empty";
                            } else {
                              return null;
                            }
                          },
                          onSaved: (value) {},
                          textInputAction: TextInputAction.newline,
                          focusNode: businessBioFN,
                          hintText: "Business description",
                          maxLines: 10,
                          keyboardType: TextInputType.multiline,
                          maxLength: 1000,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )),
      ),
    );
  }
}
