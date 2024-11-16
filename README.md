## Task Bell - Mobile Alarm System

An effective local alarm system for shift workers and busy individuals.

### Implemented Functionality

1. Multiple Screens/Navigation
  - Alarm page
  - Timer page
  - Stopwatch page
  - Settings page

2. Dialogs and Pickers
  - Most pages implement these, for example when creating an alarm creates a dialog containing several pickers 

3. Notifications
  - Notifications when alarm goes off
  - Notification when invalid data is entered

4. Snackbars
  - When enabling an alarm, showing when it is scheduled for (relative time)
  - Basic feedback/error reporting (e.g. fetching data from cloud)

5. Local Storage
  - All changes are stored locally in an SQLite database

6. Cloud Storage
  - Syncing between devices is supported using the cloud upload and cloud download in the app bar

7. HTTP Requests
  - Can press the Music note icon in the app bar to paste a youtube video link. The video's audio will be downloaded and saved. This can then be used for the alarm sound when creating a new alarm

### How to use

#### Alarms & Timers
To create the initial alarms or folders, press the floating action button in the bottom middle of the screen. The dialog that pops up has two tabs, allowing the choice between creating an alarm or folder.

For creating an alarm, you will need to fill in an alarm name, as well as what days of the week the alarm should go off on. After that, press "Select Time" to choose the time of day the alarm will go off on. This will open a new dialog.

Once everything has been filled out, you can press Create. This will then prompt the user to select an audio file to play when the alarm goes off. Alarm sounds can be downloaded through the app with the Music Note icon in the app bar.

These same instructions apply for Timers, with the only difference being that when selecting the time, it doesn't refer to time of day, but rather a time offset from when the alarm was enabled

#### Stopwatch

This has all the basically functionality you would expect from a stopwatch. It can be started, stopped, restarted, reset, and keeps track of lap times.

Laps are displayed below the stopwatch, with the lap number and time.





### Planned Core Functionality

1. **Alarm Groups**

  - supports a hierarchical alarm grouping structure
  - alarm settings can be made group local or cascading to all child groups
  - specific groups or alarms can be set independently and be made 'immune' of parent settings

2.  **Calendar Suppport**
  - Alarms/groups support a variety of pre-set or user-defined recurrence patterns
  - Calendar UI will synchronize with current date and display set alarms/groups

3. **Alarm Disable Tasks**
  - QR code scanning
  - take image of specific location in the home

4. **Location-Based Alarm Activation**
  - groups/alarms can be activated or deactivated based on geolocation in place of date/time recurrence patters

4. **Stopwatch and Timer Support**
  - multiple simultaneous timers
  - visible stopwatch laps
