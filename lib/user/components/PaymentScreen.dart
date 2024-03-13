import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../main/components/BodyCornerWidget.dart';
import '../../main/models/PaymentGatewayListModel.dart';
import '../../main/utils/Colors.dart';
import '../../main/utils/Common.dart';
import '../../main/utils/Constants.dart';
import '../../main/utils/Widgets.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../main.dart';

class GoogleMapScreen extends StatefulWidget {
  static String tag = '/PaymentScreen';

  final String imei;

  GoogleMapScreen({required this.imei});

  @override
  GoogleMapScreenState createState() => GoogleMapScreenState();
}

class GoogleMapScreenState extends State<GoogleMapScreen> {
  bool isDisabled = false;
  bool isLoading = false;
  String? lat;
  String? lng;

  @override
  void initState() {
    setState(() {
      isLoading = true;
    });
      fetchGPSData();
    super.initState();

  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  Future<void> fetchGPSData() async {
    final String url = 'https://app.yessirgps.com/api/get-gps-data-json/${widget.imei!}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // Parse the JSON response
        Map<String, dynamic> data = json.decode(response.body);

        // Extract the latitude and longitude from the response
        lat = data['lat'] as String?;
        lng = data['lng'] as String?;

        print(lat);
        print(lng);
        // Handle the location data (e.g., update the map or do further processing)
        // updateMap(lat, lng);
        setState(() {
          isLoading = false;
        });
      } else {
        // Handle errors, such as when the IMEI is not found or the API is down
        print('Failed to fetch GPS data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Location')),
      body: isLoading
          ? Scaffold(
        backgroundColor: Color(0xFF253280),
        body: Center(
          child: SpinKitWanderingCubes(
            color: Colors.white,
          ),
        ),
      )
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(double.parse(lat!), double.parse(lng!)),
          zoom: 15.0,
        ),
        markers: Set<Marker>.from([
          Marker(
            markerId: MarkerId("YourMarkerID"),
            position: LatLng(double.parse(lat!), double.parse(lng!)),
            infoWindow: InfoWindow(title: "Your Location"),
          ),
        ]),
      ),
    );
  }
}
