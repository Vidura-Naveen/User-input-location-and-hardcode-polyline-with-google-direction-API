import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

class DriverPage extends StatefulWidget {
  @override
  _DriverPageState createState() => _DriverPageState();
}

class _DriverPageState extends State<DriverPage> {
  final databaseReference = FirebaseDatabase.instance.ref();
  bool isSharingLocation = false;

  void startSharingLocation() async {
    // Check for location permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        // Handle the case when the user denies permission
        _showPopup('Location permission denied.');
        return;
      }
    }

    setState(() {
      isSharingLocation = true;
    });

    // Start continuous location updates
    updateLocation();
    _showPopup('Sharing location started.');
  }

  void stopSharingLocation() {
    setState(() {
      isSharingLocation = false;
    });

    // Stop location updates or perform any necessary cleanup
    // For simplicity, we can set the location to null in the database
    databaseReference.child('location').set(null);
    _showPopup('Sharing location stopped.');
  }

  void updateLocation() async {
    // Add logic to continuously update and share the location
    while (isSharingLocation) {
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // Update the Firebase Realtime Database with the current location.
        databaseReference.child('location').set(
            {'latitude': position.latitude, 'longitude': position.longitude});

        // Simulate continuous updates by adding a delay
        await Future.delayed(Duration(seconds: 10));
      } catch (e) {
        // Handle the exception
        print('Error getting location: $e');
      }
    }
  }

  void _showPopup(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Location Sharing"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Driver Page'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: startSharingLocation,
              child: Text('Start Sharing Location'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: stopSharingLocation,
              child: Text('Stop Sharing Location'),
            ),
          ],
        ),
      ),
    );
  }
}
