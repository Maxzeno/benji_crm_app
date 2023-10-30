import 'dart:async';

import 'package:benji_aggregator/app/add_vendor/add_vendor.dart';
import 'package:benji_aggregator/app/my_vendors/my_vendor_detail.dart';
import 'package:benji_aggregator/controller/vendor_controller.dart';
import 'package:benji_aggregator/model/my_vendor.dart';
import 'package:benji_aggregator/src/components/appbar/my_appbar.dart';
import 'package:benji_aggregator/src/components/container/myvendor_container.dart';
import 'package:benji_aggregator/src/components/section/my_liquid_refresh.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '../../src/providers/constants.dart';
import '../../src/skeletons/vendors_list_skeleton.dart';
import '../../theme/colors.dart';

class MyVendors extends StatefulWidget {
  const MyVendors({super.key});

  @override
  State<MyVendors> createState() => _MyVendorsState();
}

class _MyVendorsState extends State<MyVendors> {
  //=======================================================================\\
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    // _animationController.dispose();
    scrollController.dispose();
  }

//============================================== ALL VARIABLES =================================================\\
  late bool loadingScreen;
  bool vendorStatus = true;

  // bool _isScrollToTopBtnVisible = false;

//============================================== CONTROLLERS =================================================\\
  final scrollController = ScrollController();
  // late AnimationController _animationController;

//============================================== FUNCTIONS =================================================\\

//===================== Handle refresh ==========================\\

  Future<void> _handleRefresh() async {
    setState(() {
      loadingScreen = true;
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    setState(() {
      loadingScreen = false;
    });
  }

// //============================= Scroll to Top ======================================//
//   void _scrollToTop() {
//     _animationController.reverse();
//     scrollController.animateTo(0,
//         duration: const Duration(seconds: 1), curve: Curves.fastOutSlowIn);
//   }

//   void _scrollListener() {
//     //========= Show action button ========//
//     if (scrollController.position.pixels >= 200) {
//       _animationController.forward();
//       setState(() => _isScrollToTopBtnVisible = true);
//     }
//     //========= Hide action button ========//
//     else if (scrollController.position.pixels < 200) {
//       _animationController.reverse();
//       setState(() => _isScrollToTopBtnVisible = true);
//     }
//   }

//=============================== See more ========================================\\
  void _seeMoreOnlineVendors() {}
  void _seeMoreOfflineVendors() {}

//===================== Navigation ==========================\\

  void _toVendorDetailsPage(myVendorModel data) => Get.to(
        () => MyVendorDetailsPage(
          vendor: data,
        ),
        duration: const Duration(milliseconds: 300),
        fullscreenDialog: true,
        curve: Curves.easeIn,
        routeName: "VendorDetails",
        preventDuplicates: true,
        popGesture: true,
        transition: Transition.downToUp,
      );

  void _toAddVendor() => Get.to(
        () => const AddVendor(),
        duration: const Duration(milliseconds: 300),
        fullscreenDialog: true,
        curve: Curves.easeIn,
        routeName: "AddVendor",
        preventDuplicates: true,
        popGesture: true,
        transition: Transition.downToUp,
      );

  // void toMyVendorsPage() => Get.to(
  //       () => const MyVendors(),
  //       duration: const Duration(milliseconds: 300),
  //       fullscreenDialog: true,
  //       curve: Curves.easeIn,
  //       routeName: "MyVendors",
  //       preventDuplicates: true,
  //       popGesture: true,
  //       transition: Transition.downToUp,
  //     );

  // void showSearchField() =>
  //     showSearch(context: context, delegate: CustomSearchDelegate());

  @override
  Widget build(BuildContext context) {
    return MyLiquidRefresh(
      onRefresh: _handleRefresh,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _toAddVendor,
          elevation: 20.0,
          mouseCursor: SystemMouseCursors.click,
          tooltip: "Add a vendor",
          backgroundColor: kAccentColor,
          foregroundColor: kPrimaryColor,
          child: const FaIcon(FontAwesomeIcons.plus),
        ),
        appBar: MyAppBar(
          title: "My Vendors",
          elevation: 0,
          actions: const [],
          backgroundColor: kPrimaryColor,
        ),
        body: SafeArea(
          maintainBottomViewPadding: true,
          child: GetBuilder<VendorController>(
            initState: (state) async {
              await VendorController.instance.getMyVendors();
            },
            builder: (controller) {
              return Scrollbar(
                controller: scrollController,
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    kDefaultPadding,
                    0,
                    kDefaultPadding,
                    kDefaultPadding,
                  ),
                  children: [
                    kSizedBox,
                    controller.isLoad.value
                        ? const VendorsListSkeleton()
                        : ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: kDefaultPadding / 2),
                            itemCount: controller.vendorMyList.length,
                            addAutomaticKeepAlives: true,
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (context, index) => InkWell(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                  decoration: ShapeDecoration(
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    shadows: const [
                                      BoxShadow(
                                        color: Color(0x0F000000),
                                        blurRadius: 24,
                                        offset: Offset(0, 4),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: MyVendorContainer(
                                    onTap: () => _toVendorDetailsPage(
                                        controller.vendorMyList[index]),
                                    vendor: controller.vendorMyList[index],
                                  )),
                            ),
                          ),
                    kSizedBox,
                    vendorStatus
                        ? TextButton(
                            onPressed: _seeMoreOnlineVendors,
                            child: Text(
                              "See more",
                              style: TextStyle(color: kAccentColor),
                            ),
                          )
                        : TextButton(
                            onPressed: _seeMoreOfflineVendors,
                            child: Text(
                              "See more",
                              style: TextStyle(color: kAccentColor),
                            ),
                          ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}