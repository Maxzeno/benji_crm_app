import 'package:benji_aggregator/src/utils/constants.dart';

class BankModel {
  final String name;
  final String code;
  final String ussdTemplate;
  final String baseUssdCode;
  final String transferUssdTemplate;
  final String bankId;
  final String nipBankCode;

  BankModel({
    required this.name,
    required this.code,
    required this.ussdTemplate,
    required this.baseUssdCode,
    required this.transferUssdTemplate,
    required this.bankId,
    required this.nipBankCode,
  });

  factory BankModel.fromJson(Map<String, dynamic>? json) {
    json ??= {};
    return BankModel(
      name: json['name'] ?? notAvailable,
      code: json['code'] ?? notAvailable,
      ussdTemplate: json['ussdTemplate'] ?? notAvailable,
      baseUssdCode: json['baseUssdCode'] ?? notAvailable,
      transferUssdTemplate: json['transferUssdTemplate'] ?? notAvailable,
      bankId: json['bankId'] ?? notAvailable,
      nipBankCode: json['nipBankCode'] ?? notAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'ussdTemplate': ussdTemplate,
        'baseUssdCode': baseUssdCode,
        'transferUssdTemplate': transferUssdTemplate,
        'bankId': bankId,
        'nipBankCode': nipBankCode,
      };

  static List<BankModel> listFromJson(List<Map<String, dynamic>> jsonList) {
    return jsonList.map((json) => BankModel.fromJson(json)).toList();
  }
}
