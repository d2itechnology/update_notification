import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart';
import 'package:package_info/package_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class AppVersionStatus {
  /// The current version of the app.
  final String currentVersion;

  /// The most recent version of the app in the store.
  final String storeVersion;

  /// A link to the app store page where the app can be updated.
  final String appStoreLink;

  /// The release notes for the store version of the app.
  final String? releaseNotes;

  AppVersionStatus._({
    required this.currentVersion,
    required this.storeVersion,
    required this.appStoreLink,
    this.releaseNotes,
  });

  bool get canVersionUpdate {
    // assume version strings can be of the form aa.bb.cc
    // this implementation correctly compares local 1.8.0 to store 1.7.4
    try {
      final currentFields = currentVersion.split('.');
      final storeFields = storeVersion.split('.');
      String currentPad = '';
      String storePad = '';
      for (int i = 0; i < storeFields.length; i++) {
        currentPad = currentPad + currentFields[i].padLeft(3, '0');
        storePad = storePad + storeFields[i].padLeft(3, '0');
      }

      if (currentPad.compareTo(storePad) < 0)
        return true;
      else
        return false;
    } catch (e) {
      return currentVersion.compareTo(storeVersion).isNegative;
    }
  }

  // assume minimum version strings can be of the form aa.bb.cc

  bool isMinVersion(String minVersion) {
    // this implementation correctly compares minimum version to current version
    try {
      final minimumFields = minVersion.split('+')[0].split('.');
      final currentFields = currentVersion.split('.');
      String currentPad = '';
      String minimumPad = '';
      for (int i = 0; i < currentFields.length; i++) {
        currentPad = currentPad + currentFields[i].padLeft(3, '0');
        minimumPad = minimumPad + minimumFields[i].padLeft(3, '0');
      }

      if (currentPad.compareTo(minimumPad) < 0)
        return true;
      else
        return false;
    } catch (e) {
      return currentVersion.compareTo(minVersion).isNegative;
    }
  }
}

class UpdateNotification {
  final String? iOSAppId;
  final String? androidAppId;
  final String? minimumVersion; // pass minimumVersion like aa.bb.cc

  UpdateNotification(
      {this.iOSAppId, this.androidAppId, required this.minimumVersion});

  /// This checks the version status, then displays a platform-specific alert
  /// onClick buttons can dismiss the update alert, or go to the app store.

  showAlertDialog({required BuildContext context}) async {
    final AppVersionStatus? versionStatus = await getAppVersionStatus();
    if (minimumVersion != null) {
      // Check if current version is less than minimum version
      if (minimumVersion!.isNotEmpty &&
          versionStatus != null &&
          versionStatus.isMinVersion(minimumVersion!)) {
        showRequiredUpdateAlertDialog(
            context: context, appVersionStatus: versionStatus);
      } else {
        // Check if current version is less than play store/app store version
        if (versionStatus != null && versionStatus.canVersionUpdate) {
          showOptionalUpdateAlertDialog(
              context: context, appVersionStatus: versionStatus);
        }
      }
    }
  }

  Future<AppVersionStatus?> getAppVersionStatus() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (Platform.isAndroid) {
      return _getAndroidVersion(packageInfo);
    } else if (Platform.isIOS) {
      return _getIOSVersion(packageInfo);
    } else {
      printDebugText(
          'The target platform "${Platform.operatingSystem}" is not supported this package');
    }
  }

  void printDebugText(String s) {}

  /// Android info is fetched by parsing the html of the app store page.
  Future<AppVersionStatus?> _getAndroidVersion(PackageInfo packageInfo) async {
    final id = androidAppId ?? packageInfo.packageName;
    final uri =
        Uri.https("play.google.com", "/store/apps/details", {"id": "$id"});
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      debugPrint('Can\'t find an app in the Play Store with the id: $id');
      return null;
    }
    final document = parse(response.body);

    final additionalInfoElements = document.getElementsByClassName('hAyfc');
    final versionElement = additionalInfoElements.firstWhere(
      (elm) => elm.querySelector('.BgcNfc')!.text == 'Current Version',
    );
    final storeVersion = versionElement.querySelector('.htlgb')!.text;

    final sectionElements = document.getElementsByClassName('W4P4ne');
    final releaseNotesElement = sectionElements.firstWhere(
      (elm) => elm.querySelector('.wSaTQd')!.text == 'What\'s New',
    );
    final releaseNotes = releaseNotesElement
        .querySelector('.PHBdkd')
        ?.querySelector('.DWPxHb')
        ?.text;

    return AppVersionStatus._(
      currentVersion: packageInfo.version,
      storeVersion: storeVersion,
      appStoreLink: uri.toString(),
      releaseNotes: releaseNotes,
    );
  }

  Future<AppVersionStatus?> _getIOSVersion(PackageInfo packageInfo) async {
    final id = iOSAppId ?? packageInfo.packageName;
    final parameters = {"bundleId": "$id"};

    var uri = Uri.https("itunes.apple.com", "/lookup", parameters);
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      debugPrint('Failed to query iOS App Store');
      return null;
    }

    final jsonObjData = json.decode(response.body);
    final List results = jsonObjData['results'];
    if (results.isEmpty) {
      debugPrint('Can\'t find an app in the App Store with the id: $id');
      return null;
    }
    return AppVersionStatus._(
      currentVersion: packageInfo.version,
      storeVersion: jsonObjData['results'][0]['version'],
      appStoreLink: jsonObjData['results'][0]['trackViewUrl'],
      releaseNotes: jsonObjData['results'][0]['releaseNotes'],
    );
  }

  void showRequiredUpdateAlertDialog(
      {required BuildContext context,
      required AppVersionStatus appVersionStatus,
      String alertTitle = 'Update Available',
      String? alertText,
      String updateBtn = 'Update',
      bool allowDismissible = false,
      VoidCallback? dismissAction}) async {
    final alertTitleWidget = Text(alertTitle);
    final alertTextWidget =
        Text(alertText ?? 'Please update the app to continue');

    final updateBtnTxtWidget = Text(updateBtn);
    final updateAction = () {
      _launchAppStore(appVersionStatus.appStoreLink);
    };

    List<Widget> actions = [
      Platform.isAndroid
          ? TextButton(
              child: updateBtnTxtWidget,
              onPressed: updateAction,
            )
          : CupertinoDialogAction(
              child: updateBtnTxtWidget,
              onPressed: updateAction,
            ),
    ];

    showDialog(
      context: context,
      barrierDismissible: allowDismissible,
      builder: (BuildContext context) {
        return WillPopScope(
            child: Platform.isAndroid
                ? AlertDialog(
                    title: alertTitleWidget,
                    content: alertTextWidget,
                    actions: actions,
                  )
                : CupertinoAlertDialog(
                    title: alertTitleWidget,
                    content: alertTextWidget,
                    actions: actions,
                  ),
            onWillPop: () => Future.value(allowDismissible));
      },
    );
  }

  void showOptionalUpdateAlertDialog(
      {required BuildContext context,
      required AppVersionStatus appVersionStatus,
      String alertTitle = 'Update Available',
      String? alertText,
      String updateBtn = 'Update',
      bool allowDismissible = true,
      String dismissBtn = 'Later',
      VoidCallback? dismissAction}) async {
    final alertTitleWidget = Text(alertTitle);
    final alertTextWidget = Text(
      alertText ??
          'You can now update this app from ${appVersionStatus.currentVersion} to ${appVersionStatus.storeVersion} version',
    );

    final updateBtnTxtWidget = Text(updateBtn);
    final updateAction = () {
      _launchAppStore(appVersionStatus.appStoreLink);
      if (allowDismissible) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    };

    List<Widget> actions = [
      Platform.isAndroid
          ? TextButton(
              child: updateBtnTxtWidget,
              onPressed: updateAction,
            )
          : CupertinoDialogAction(
              child: updateBtnTxtWidget,
              onPressed: updateAction,
            ),
    ];

    if (allowDismissible) {
      final dismissButtonTextWidget = Text(dismissBtn);
      dismissAction = dismissAction ??
          () => Navigator.of(context, rootNavigator: true).pop();
      actions.add(
        Platform.isAndroid
            ? TextButton(
                child: dismissButtonTextWidget,
                onPressed: dismissAction,
              )
            : CupertinoDialogAction(
                child: dismissButtonTextWidget,
                onPressed: dismissAction,
              ),
      );
    }

    showDialog(
      context: context,
      barrierDismissible: allowDismissible,
      builder: (BuildContext context) {
        return WillPopScope(
            child: Platform.isAndroid
                ? AlertDialog(
                    title: alertTitleWidget,
                    content: alertTextWidget,
                    actions: actions,
                  )
                : CupertinoAlertDialog(
                    title: alertTitleWidget,
                    content: alertTextWidget,
                    actions: actions,
                  ),
            onWillPop: () => Future.value(allowDismissible));
      },
    );
  }

  /// Launches the Google Play Store and Apple App Store for the app

  void _launchAppStore(String appStoreLink) async {
    debugPrint(appStoreLink);
    if (await canLaunch(appStoreLink)) {
      await launch(appStoreLink);
    } else {
      throw 'Could not launch appStoreLink';
    }
  }
}
