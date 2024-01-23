import 'package:benji_aggregator/controller/withdraw_controller.dart';
import 'package:benji_aggregator/src/components/card/empty.dart';
import 'package:benji_aggregator/src/components/section/bank_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/colors.dart';
import '../../providers/constants.dart';

class SelectBankBody extends StatefulWidget {
  final banks = Get.put(WithdrawController());

  SelectBankBody({super.key});

  @override
  State<SelectBankBody> createState() => _SelectBankBodyState();
}

class _SelectBankBodyState extends State<SelectBankBody> {
  @override
  void initState() {
    isTyping = false;

    super.initState();
  }

  @override
  void dispose() {
    selectedBankName.dispose();
    super.dispose();
  }

  //==================  CONTROLLERS ==================\\
  final scrollController = ScrollController();
  final bankQueryEC = TextEditingController();

  //================== ALL VARIABLES ==================\\
  final selectedBankName = ValueNotifier<String?>(null);
  final selectedBankCode = ValueNotifier<String?>(null);

  //================== BOOL VALUES ==================\\
  bool? isTyping;
  bool refreshing = false;

  //================== FUNCTIONS ==================\\

  selectBank(index) async {
    final newBankName = WithdrawController.instance.listOfBanks[index].name;
    final newBankCode = WithdrawController.instance.listOfBanks[index].code;

    selectedBankName.value = newBankName;
    selectedBankCode.value = newBankCode;

    bankQueryEC.text = newBankName;

    final result = {'name': newBankName, 'code': newBankCode};

    Get.back(result: result);
  }

  Future<void> handleRefresh() async {
    await WithdrawController.instance.listBanks();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: handleRefresh,
      child: SafeArea(
        child: Column(
          children: [
            // Padding(
            //   padding: const EdgeInsets.all(10),
            //   child: SearchBar(
            //     controller: bankQueryEC,
            //     hintText: "Search bank",
            //     backgroundColor: MaterialStatePropertyAll(
            //         Theme.of(context).scaffoldBackgroundColor),
            //     elevation: const MaterialStatePropertyAll(0),
            //     leading: FaIcon(
            //       FontAwesomeIcons.magnifyingGlass,
            //       color: kAccentColor,
            //       size: 20,
            //     ),
            //     // onChanged: onChanged,
            //     padding: const MaterialStatePropertyAll(EdgeInsets.all(10)),
            //     shape: MaterialStatePropertyAll(RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(10),
            //     )),
            //     side:
            //         MaterialStatePropertyAll(BorderSide(color: kLightGreyColor)),
            //   ),
            // ),
            Expanded(
              child: Scrollbar(
                controller: scrollController,
                child: GetBuilder<WithdrawController>(
                  initState: (state) => WithdrawController.instance.listBanks(),
                  builder: (banks) {
                    return banks.listOfBanks.isEmpty
                        ? const EmptyCard(
                            emptyCardMessage:
                                "There are no banks listed right now",
                          )
                        : banks.listOfBanks.isEmpty || banks.isLoad.value
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: kAccentColor,
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(10),
                                itemCount: banks.listOfBanks.length,
                                separatorBuilder: (context, index) => kSizedBox,
                                itemBuilder: (context, index) {
                                  final bankName =
                                      banks.listOfBanks[index].name;
                                  // Check if the bankName contains the search query
                                  if (bankName.toLowerCase().contains(
                                      bankQueryEC.text.toLowerCase())) {
                                    return BankListTile(
                                      onTap: () => selectBank(index),
                                      bank: bankName,
                                    );
                                  } else {
                                    // Return an empty container for banks that do not match the search
                                    return Container();
                                  }
                                },
                              );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
