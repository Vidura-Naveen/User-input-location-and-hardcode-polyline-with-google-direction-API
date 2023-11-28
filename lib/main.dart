// import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapgpt2/firebase_options.dart';
import 'map_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MaterialApp(home: LocationInputPage()));
}

class LocationInputPage extends StatefulWidget {
  @override
  _LocationInputPageState createState() => _LocationInputPageState();
}

class _LocationInputPageState extends State<LocationInputPage> {
  final TextEditingController _fromController = TextEditingController();
  final TextEditingController _toController = TextEditingController();
// Define variables to store the coordinates
  LatLng location1 = LatLng(7.0859203, 80.0335639);
  LatLng location2 = LatLng(7.87533540646052, 80.65118935530958);

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      // Handle denied permission
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Location Permission Required'),
            content: Text('Please enable location services to use this app.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter Locations')),
      body: Column(
        children: <Widget>[
          TextField(
            controller: _fromController,
            decoration: InputDecoration(labelText: 'From'),
          ),
          TextField(
            controller: _toController,
            decoration: InputDecoration(labelText: 'To'),
          ),
          ElevatedButton(
            child: Text('Show Map'),
            onPressed: () async {
              try {
                if (_fromController.text.isEmpty ||
                    _toController.text.isEmpty) {
                  throw Exception('Please enter both From and To locations');
                }

                List<Location> fromLocations =
                    await locationFromAddress(_fromController.text);
                List<Location> toLocations =
                    await locationFromAddress(_toController.text);

                LatLng fromLatLng = LatLng(
                    fromLocations[0].latitude, fromLocations[0].longitude);
                LatLng toLatLng =
                    LatLng(toLocations[0].latitude, toLocations[0].longitude);
// Fetch the current device location
                Position currentPosition =
                    await Geolocator.getCurrentPosition();
                LatLng currentLatLng =
                    LatLng(currentPosition.latitude, currentPosition.longitude);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapPage(
                      fromLatLng: fromLatLng,
                      toLatLng: toLatLng,
                      location1: location1, // Pass location1
                      location2: location2,
                      currentLatLng: currentLatLng,
                    ),
                  ),
                );
              } catch (e) {
                // Handle the exception
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Error'),
                      content: Text(e.toString()),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('OK'),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
