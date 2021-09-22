# update_notification

* This flutter package will alert app users to update the application.
* With the help of an alert pop-up, users can easily navigate to the respective stores(App Store or play Store) to update the app.

## UI
The UI of the alert dialog is simply a card.

Screenshots:

<img src="https://raw.githubusercontent.com/d2itechnology/at_newversion_notification/main/screenshots/both.png?token=AUJGZABAX3TJOUFYSYZY4ATBHGZHW"/>

## Installation
Add update_notification as [a dependency in your `pubspec.yaml` file.](https://flutter.io/using-packages/)
```
dependencies:
  update_notification: ^1.0.1
```
## Usage
* In main.dart (or any) file, first create an instance of the `UpdateNotification` class in your `initState()` method.

   `final UpdateNotification updateNotification = UpdateNotification();`

* Pass the application package name in `andoidAppId`, `iOSAppId`.

* Pass application minimum version value in `minimumVersion` parameter. This parameter is used to force people to update application, any user having version less than the specified version will be forced to update application

* Call showAlertDialog method-
  `updateNotification.showAlertDialog(context: context);`

* If updated app version is available on stores, application will get a popup on launch of application and an option to Update. On click of update button user will be directed to the respective stores(App store or play store).

## Example
```
 import 'package:flutter/cupertino.dart';
 import 'package:flutter/material.dart';
 import '/update_notification.dart';

 class Example extends StatefulWidget {
   const Example({Key? key}) : super(key: key);

   @override
   _ExampleState createState() => _ExampleState();
 }

 class _ExampleState extends State<Example> {
   @override
   void initState() {
     super.initState();

     final UpdateNotification updateNotification =
         UpdateNotification(
             iOSAppId: 'com.google.myride',
             androidAppId: 'com.google.rever',
             minimumVersion: '1.0.0');

     showDialog(updateNotification);
   }

   void showDialog(UpdateNotification updateVersion) {
     updateVersion.showAlertDialog(context: context);
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       body: Container(),
     );
   }
 }
 ```




