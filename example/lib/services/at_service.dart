import 'dart:io';

import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:update_notification_example/utils/app_constants.dart';
import 'package:at_commons/at_commons.dart' as at_commons;
import 'package:path_provider/path_provider.dart' as path_provider;

class AtService {
  static final AtService _singleton = AtService._internal();

  AtService._internal();
  static final KeyChainManager _keyChainManager = KeyChainManager.getInstance();

  factory AtService.getInstance() {
    return _singleton;
  }
  String? _atsign;

  Future<AtClientPreference> getAtClientPreference() async {
    Directory appDocumentDirectory =
        await path_provider.getApplicationSupportDirectory();
    String path = appDocumentDirectory.path;
    AtClientPreference _atClientPreference = AtClientPreference()
      ..isLocalStoreRequired = true
      ..commitLogPath = path
      ..namespace = AppConstants.appNamespace
      ..rootDomain = AppConstants.rootDomain
      ..hiveStoragePath = path;
    return _atClientPreference;
  }

  Map<String?, AtClientService> atClientServiceMap =
      <String, AtClientService>{};

  AtClient? _getAtClientForAtsign({String? atsign}) {
    atsign ??= _atsign;
    if (atClientServiceMap.containsKey(atsign)) {
      return AtClientManager.getInstance().atClient;
    }
    return null;
  }

  ///Fetches atsign from device keychain.
  Future<String?> getAtSign() async {
    return _keyChainManager.getAtSign();
  }

  Future<bool> put({String? key, dynamic value}) async {
    at_commons.AtKey atKey = at_commons.AtKey()..key = key;
    // ..metadata = metaData;
    return _getAtClientForAtsign()!.put(atKey, value);
  }

  Future<bool> delete({String? key}) async {
    at_commons.AtKey atKey = at_commons.AtKey()..key = key;
    return _getAtClientForAtsign()!.delete(atKey);
  }

  Future<List<String>> get() async {
    return _getAtClientForAtsign()!.getKeys(regex: AppConstants.regex);
  }

  Future<bool> makeAtsignPrimary(String atsign) async {
    atsign = formatAtSign(atsign)!;
    return _keyChainManager.makeAtSignPrimary(atsign);
  }

  ///Returns null if [atsign] is null else the formatted [atsign].
  ///[atsign] must be non-null.
  String? formatAtSign(String? atsign) {
    if (atsign == null) {
      return null;
    }
    atsign = atsign.trim().toLowerCase().replaceAll(' ', '');
    atsign = !atsign.startsWith('@') ? '@' + atsign : atsign;
    return atsign;
  }
}
