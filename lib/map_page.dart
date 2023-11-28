import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapPage extends StatefulWidget {
  final LatLng fromLatLng;
  final LatLng toLatLng;
  final LatLng location1;
  final LatLng location2;
  final LatLng currentLatLng;

  MapPage({
    required this.fromLatLng,
    required this.toLatLng,
    required this.location1,
    required this.location2,
    required this.currentLatLng,
  });

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  late LatLng _lastKnownPosition;
  LatLng? _driverLocation;

  final databaseReference = FirebaseDatabase.instance.ref();

  @override
  void initState() {
    super.initState();

    _lastKnownPosition = widget.currentLatLng;
    _markers
      ..add(Marker(markerId: MarkerId('from'), position: widget.fromLatLng))
      ..add(Marker(markerId: MarkerId('to'), position: widget.toLatLng))
      ..add(Marker(markerId: MarkerId('location1'), position: widget.location1))
      ..add(
          Marker(markerId: MarkerId('location2'), position: widget.location2));

    _createPolylines();
    // Listen for changes in the driver's location
    databaseReference.child('location').onValue.listen((event) {
      if (event.snapshot.value != null) {
        var data = Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          _driverLocation = LatLng(data['latitude'], data['longitude']);
          // Update the markers set with the new driverLocation
          _updateMarkers();
        });
      } else {
        setState(() {
          _driverLocation = null;
          // Update the markers set without the driverLocation
          _updateMarkers();
        });
      }
    });
  }

  // Update the markers set based on current locations
  void _updateMarkers() {
    _markers.clear();
    _markers
      ..add(Marker(markerId: MarkerId('from'), position: widget.fromLatLng))
      ..add(Marker(markerId: MarkerId('to'), position: widget.toLatLng))
      ..add(Marker(markerId: MarkerId('location1'), position: widget.location1))
      ..add(
          Marker(markerId: MarkerId('location2'), position: widget.location2));

    // Add driverLocation marker if it's not null
    if (_driverLocation != null) {
      _markers.add(Marker(
        markerId: MarkerId('driverLocation'),
        position: _driverLocation!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Driver Location'),
      ));
    }
  }

  Future<void> _createPolylines() async {
    await _getDirectionsForHardcodedPolyline();
    await _getDirections();
  }

  Future<void> _getDirections() async {
    String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${widget.fromLatLng.latitude},${widget.fromLatLng.longitude}&'
        'destination=${widget.toLatLng.latitude},${widget.toLatLng.longitude}&'
        'mode=transit&'
        'transit_mode=bus&'
        'alternatives=true&'
        'key='; // Replace YOUR_API_KEY with your actual API key

    http.Response response = await http.get(Uri.parse(url));
    Map values = jsonDecode(response.body);

    print('Directions API Response: $values');

    if (values['routes'].isNotEmpty) {
      List<dynamic> routes = values['routes'];
      _showRouteOptions(routes);
      String polylinePoints = routes[0]['overview_polyline']['points'];
      List<LatLng> polylineCoordinates =
          _convertToLatLng(_decodePolyline(polylinePoints));

      setState(() {
        // Add the blue polyline
        _polylines.add(
          Polyline(
            polylineId: PolylineId('selectedRoute'),
            visible: true,
            points: polylineCoordinates,
            color: Colors.blue,
          ),
        );
      });
    }
  }

  Future<void> _getDirectionsForHardcodedPolyline() async {
    String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${widget.location1.latitude},${widget.location1.longitude}&'
        'destination=${widget.location2.latitude},${widget.location2.longitude}&'
        'mode=transit&'
        'transit_mode=bus&'
        'alternatives=true&'
        'key='; // Replace YOUR_API_KEY with your actual API key

    http.Response response = await http.get(Uri.parse(url));
    Map values = jsonDecode(response.body);

    print('Directions API Response for Hardcoded Polyline: $values');

    if (values['routes'].isNotEmpty) {
      List<dynamic> routes = values['routes'];
      String polylinePointsblack = routes[0]['overview_polyline']['points'];
      List<LatLng> polylineCoordinatesBlack =
          _convertToLatLng(_decodePolyline(polylinePointsblack));

      setState(() {
        // Add the black polyline
        _polylines.add(
          Polyline(
            polylineId: PolylineId('hardcodedPolyline'),
            visible: true,
            points: polylineCoordinatesBlack,
            color: Colors.black,
          ),
        );
      });
    }
  }

  void _showRouteOptions(List<dynamic> routes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose a Route'),
          content: Column(
            children: <Widget>[
              for (int i = 0; i < routes.length; i++)
                ListTile(
                  title: Text('Route ${i + 1}'),
                  subtitle: Text(
                    'Duration: ${routes[i]['legs'][0]['duration']['text']}, '
                    'Distance: ${routes[i]['legs'][0]['distance']['text']}',
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _displayChosenRoute(routes[i]);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _displayChosenRoute(dynamic chosenRoute) {
    String polylinePoints = chosenRoute['overview_polyline']['points'];
    List<LatLng> polylineCoordinates =
        _convertToLatLng(_decodePolyline(polylinePoints));

    setState(() {
      // Add the blue polyline
      _polylines.add(
        Polyline(
          polylineId: PolylineId('selectedRoute'),
          visible: true,
          points: polylineCoordinates,
          color: Colors.blue,
        ),
      );
    });
  }

  List<LatLng> _convertToLatLng(List points) {
    List<LatLng> result = <LatLng>[];
    for (int i = 0; i < points.length; i++) {
      if (i % 2 != 0) {
        result.add(LatLng(points[i - 1], points[i]));
      }
    }
    return result;
  }

  List _decodePolyline(String polyline) {
    var list = polyline.codeUnits;
    var lList = [];
    int index = 0;
    int len = polyline.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;

      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);

      if (result & 1 == 1) {
        result = ~result;
      }
      var result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);

    for (var i = 2; i < lList.length; i++) lList[i] += lList[i - 2];

    return lList;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.fromLatLng,
          zoom: 15,
        ),
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true, // Enable the "My Location" button
        myLocationButtonEnabled: true, // Enable the "My Location" layer
        onMapCreated: (GoogleMapController controller) {
          // Optional: You can use the controller to interact with the map
        },
      ),
    );
  }
}
