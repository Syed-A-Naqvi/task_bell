import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'dart:async'; // For Timer
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../settings/settings_view.dart';

class WorldTimesPage extends StatefulWidget {
  const WorldTimesPage({super.key});

  @override
  State<WorldTimesPage> createState() => _WorldTimesPageState();
}

class _WorldTimesPageState extends State<WorldTimesPage> with WidgetsBindingObserver {
  final List<Map<String, dynamic>> _worldTimes = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // To detect app lifecycle changes
    _loadCities();
    _startAutoUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // This method is called when the app's lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When the app is resumed, refresh the UI
      setState(() {});
    }
  }

  void _startAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {}); // Update the UI every second
    });
  }

  Future<void> _addCity(String city) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final String timezone = await _findTimezone(city);
      if (timezone.isEmpty) {
        throw Exception('Timezone not found');
      }

      final DateTime initialDatetime = await _fetchWorldTime(timezone);
      final DateTime referenceTimestamp = DateTime.now();

      setState(() {
        _worldTimes.add({
          'city': city,
          'timezone': timezone,
          'initialDatetime': initialDatetime.toIso8601String(),
          'referenceTimestamp': referenceTimestamp.toIso8601String(),
        });
      });

      _saveCities(); // Save the updated list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.cityNotFound} $city')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _findTimezone(String city) async {
    final response = await http.get(Uri.parse('http://worldtimeapi.org/api/timezone'));
    if (response.statusCode == 200) {
      final List<dynamic> timezones = jsonDecode(response.body);
      final sanitizedCity = city.toLowerCase().replaceAll(' ', '_');
      for (String timezone in timezones) {
        if (timezone.toLowerCase().contains(sanitizedCity)) {
          return timezone;
        }
      }
    }
    return '';
  }


  Future<DateTime> _fetchWorldTime(String timezone) async {
    final url = 'http://worldtimeapi.org/api/timezone/$timezone';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final datetimeStr = data['datetime']; // e.g., '2024-11-30T20:24:00.123456+00:00'
      final utcDatetime = DateTime.parse(datetimeStr);

      final utcOffsetStr = data['utc_offset']; // e.g., '+01:00'

      // Parse the UTC offset
      final offsetSign = utcOffsetStr.substring(0, 1);
      final offsetHours = int.parse(utcOffsetStr.substring(1, 3));
      final offsetMinutes = int.parse(utcOffsetStr.substring(4, 6));

      Duration offsetDuration = Duration(
        hours: offsetHours,
        minutes: offsetMinutes,
      );

      if (offsetSign == '-') {
        offsetDuration = -offsetDuration;
      }

      // Apply offset to UTC datetime to get local datetime
      final localDatetime = utcDatetime.add(offsetDuration);

      return localDatetime;
    } else {
      throw Exception('Failed to load time data');
    }
  }

  Future<void> _refreshTimes() async {
    setState(() {
      _isLoading = true;
    });
    try {
      for (int i = 0; i < _worldTimes.length; i++) {
        final timezone = _worldTimes[i]['timezone'];
        final initialDatetime = await _fetchWorldTime(timezone);
        final referenceTimestamp = DateTime.now();

        _worldTimes[i]['initialDatetime'] = initialDatetime.toIso8601String();
        _worldTimes[i]['referenceTimestamp'] = referenceTimestamp.toIso8601String();
      }
      _saveCities(); // Save updated times
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.failFetchTime)),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeCity(int index) {
    setState(() {
      _worldTimes.removeAt(index);
    });
    _saveCities(); // Save the updated list
  }

  String _formatDateTime(Map<String, dynamic> cityInfo) {
    final initialDatetime = DateTime.parse(cityInfo['initialDatetime']);
    final referenceTimestamp = DateTime.parse(cityInfo['referenceTimestamp']);
    final elapsed = DateTime.now().difference(referenceTimestamp);
    final currentTime = initialDatetime.add(elapsed);

    return DateFormat('yyyy-MM-dd hh:mm:ss a').format(currentTime);
  }

  Future<void> _saveCities() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> cityDataList = _worldTimes.map((cityInfo) {
      return jsonEncode({
        'city': cityInfo['city'],
        'timezone': cityInfo['timezone'],
        'initialDatetime': cityInfo['initialDatetime'],
        'referenceTimestamp': cityInfo['referenceTimestamp'],
      });
    }).toList();
    await prefs.setStringList('savedCities', cityDataList);
  }

  Future<void> _loadCities() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? cityDataList = prefs.getStringList('savedCities');
    if (cityDataList != null) {
      for (String cityData in cityDataList) {
        Map<String, dynamic> cityInfo = jsonDecode(cityData);
        setState(() {
          _worldTimes.add({
            'city': cityInfo['city'],
            'timezone': cityInfo['timezone'],
            'initialDatetime': cityInfo['initialDatetime'],
            'referenceTimestamp': cityInfo['referenceTimestamp'],
          });
        });
      }
    }
  }

  // New method to extract country from timezone
  String _getCountryFromTimezone(String timezone) {
    // Here we can use a predefined mapping or a package for accurate country names
    // For simplicity, we'll extract the continent as the country
    final parts = timezone.split('/');
    if (parts.length >= 2) {
      final continent = parts[0].replaceAll('_', ' ');
      return continent;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.worldTimes),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshTimes,
            tooltip: AppLocalizations.of(context)!.refreshTimes,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.restorablePushNamed(context, SettingsView.routeName);
            },
          )
        ],
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: '${AppLocalizations.of(context)!.enterCity} ${AppLocalizations.of(context)!.cityExamplePhrase}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    if (_searchController.text.isNotEmpty) {
                      _addCity(_searchController.text.trim());
                      _searchController.clear();
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: _worldTimes.isEmpty
                ? Center(child: Text(AppLocalizations.of(context)!.noCities))
                : ListView.builder(
              itemCount: _worldTimes.length,
              itemBuilder: (context, index) {
                final cityInfo = _worldTimes[index];
                final formattedTime = _formatDateTime(cityInfo);
                final country = _getCountryFromTimezone(cityInfo['timezone']);
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    // Removed the leading icon
                    title: Text(
                      cityInfo['city'],
                      style: const TextStyle(
                        fontSize: 24, // Increased font size
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedTime,
                          style: const TextStyle(
                            fontSize: 20, // Made time display larger
                          ),
                        ),
                        if (country.isNotEmpty)
                          Text(
                            country,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _removeCity(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
