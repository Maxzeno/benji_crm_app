// ignore_for_file: camel_case_types, file_names

import 'package:flutter/material.dart';

import '../../src/components/button/my_elevatedButton.dart';
import '../../src/utils/constants.dart';

class SuccessfulScreen extends StatelessWidget {
  final String text;

  final String elevatedButtonTitle;
  final Function() buttonAction;
  const SuccessfulScreen({
    super.key,
    required this.text,
    required this.elevatedButtonTitle,
    required this.buttonAction,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(
            top: kDefaultPadding,
            left: kDefaultPadding,
            right: kDefaultPadding,
          ),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.vertical,
            children: [
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                        "assets/animations/successful/successful-payment.gif",
                      ),
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(
                height: kDefaultPadding * 2,
              ),
              SizedBox(
                width: 307,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(
                      0xFF676565,
                    ),
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.36,
                  ),
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.3,
              ),
              MyElevatedButton(
                title: elevatedButtonTitle,
                onPressed: buttonAction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
