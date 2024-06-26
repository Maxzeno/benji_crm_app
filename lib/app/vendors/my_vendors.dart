import 'package:benji_aggregator/app/vendors/my_vendor_detail.dart';
import 'package:benji_aggregator/controller/vendor_controller.dart';
import 'package:benji_aggregator/model/my_vendor_model.dart';
import 'package:benji_aggregator/src/components/card/empty.dart';
import 'package:benji_aggregator/src/components/container/my_vendor_container.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../src/skeletons/vendors_list_skeleton.dart';
import '../../src/utils/constants.dart';
import '../../theme/colors.dart';

class MyVendors extends StatefulWidget {
  const MyVendors({super.key});

  @override
  State<MyVendors> createState() => _MyVendorsState();
}

class _MyVendorsState extends State<MyVendors> {
//===================== Navigation ==========================\\
  void toVendorDetailPage(MyVendorModel data) => Get.to(
        () => MyVendorDetailPage(vendor: data),
        duration: const Duration(milliseconds: 300),
        fullscreenDialog: true,
        curve: Curves.easeIn,
        routeName: "VendorDetails",
        preventDuplicates: true,
        popGesture: true,
        transition: Transition.downToUp,
      );

  @override
  Widget build(BuildContext context) {
    return GetBuilder<VendorController>(
      initState: (state) => VendorController.instance.getMyVendors(),
      builder: (controller) {
        return SizedBox(
          child: Column(
            children: [
              controller.isLoad.value
                  ? const VendorsListSkeleton()
                  : controller.vendorMyList.isEmpty
                      ? const EmptyCard()
                      : Column(
                          children: [
                            ListView.separated(
                              separatorBuilder: (context, index) =>
                                  kHalfSizedBox,
                              itemCount: controller.vendorMyList.length,
                              addAutomaticKeepAlives: true,
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              itemBuilder: (context, index) => InkWell(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: ShapeDecoration(
                                    color: kPrimaryColor,
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
                                    onTap: () => toVendorDetailPage(
                                      controller.vendorMyList[index],
                                    ),
                                    vendor: controller.vendorMyList[index],
                                  ),
                                ),
                              ),
                            ),
                            kSizedBox,
                            controller.isLoadMoreVendor.value
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: kAccentColor,
                                    ),
                                  )
                                : controller.loadedAllVendor.value
                                    ? Container(
                                        margin: const EdgeInsets.only(
                                            top: 20, bottom: 20),
                                        height: 5,
                                        width: 5,
                                        decoration: ShapeDecoration(
                                          shape: const CircleBorder(),
                                          color: kPageSkeletonColor,
                                        ),
                                      )
                                    : InkWell(
                                        onTap: controller.loadMoreVendor,
                                        child: const Text('Load more'),
                                      )
                          ],
                        ),
            ],
          ),
        );
      },
    );
  }
}
