import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:task_bell/src/services/alarm_permissions.dart';
import 'package:task_bell/src/world_times/world_times_page.dart';

import 'sample_feature/sample_item_details_view.dart';
import 'sample_feature/sample_item_list_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'alarm_clock/alarm_clock_page.dart';
import 'timer/timer_page.dart';
import 'stopwatch/stopwatch_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  MyAppState createState() => MyAppState();
}


/// The Widget that configures your application.
class MyAppState extends State<MyApp> {

  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    AlarmClockPage(),
    TimerPage(),
    StopwatchPage(),
    WorldTimesPage()
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();

    AlarmPermissions.checkNotificationPermission();
    AlarmPermissions.checkExternalStoragePermission();
    AlarmPermissions.checkExactAlarmPermission();
  }

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: widget.settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(

          // Turning the red debug banner off (default is true)
          // I don't want to see the red debug banner in the top right corner
          debugShowCheckedModeBanner: false,

          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
            Locale('fr'),
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: widget.settingsController.themeMode,

          home: Scaffold(
            body: _pages[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: const Icon(Icons.alarm),
                  // quaternary is necessary because AppLocalization is not initialized yet
                  // For more language support, this would become super messy
                  label: Platform.localeName.contains('fr') ? 'Alarme' : 'Alarm Clock',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.timer),
                  label: Platform.localeName.contains('fr') ? 'Minuteur' : 'Timer',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.timer),
                  label: Platform.localeName.contains('fr') ? 'Chronomètre' : 'Stopwatch',
                  // label: AppLocalizations.of(context)!.stopwatch,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.public),
                  label: Platform.localeName.contains('fr') ? 'Temps du Monde' : 'World Times',
                )
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Colors.blue,
              unselectedItemColor: Colors.grey,
              backgroundColor: Colors.white,
            ),
          ),

          // Define a function to handle named routes in order to support
          // Flutter web url navigation and deep linking.
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case SettingsView.routeName:
                    return SettingsView(controller: widget.settingsController);
                  case SampleItemDetailsView.routeName:
                    return const SampleItemDetailsView();
                  case SampleItemListView.routeName:
                  default:
                    return const SampleItemListView();
                }
              },
            );
          },
        );
      },
    );
  }
}
