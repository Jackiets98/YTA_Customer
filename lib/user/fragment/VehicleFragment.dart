import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main/utils/Constants.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../components/RotatingLoadingWidget.dart';
import 'ShipmentDetailsFragment.dart';
import 'package:intl/intl.dart';


class VehicleFragment extends StatefulWidget {
  @override
  _VehicleFragmentState createState() => _VehicleFragmentState();
}

class _VehicleFragmentState extends State<VehicleFragment> {
  String selectedCategory = 'ALL';
  List<dynamic> shipmentData = [];
  bool isLoading = true;
  int completedTasks = 0;

  @override
  void initState() {
    super.initState();
    fetchAndProcessData(); // Initial data fetch
  }

  @override
  void dispose() {
    super.dispose();
  }





  Future<void> fetchAndProcessData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? obtainedID = prefs.getString('id');
      String? deviceID = prefs.getString('androidID');

      final String apiUrl = mBaseUrl + 'getDeviceList';
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        // Add any additional headers if required
      };

      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> allVehicles = json.decode(response.body);
        setState(() {
          shipmentData = allVehicles;
        });
      } else {
        throw Exception('Failed to load shipment data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      // Handle error
    }finally {
      // Set isLoading to false after the fetch is complete
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> getCityFromCoordinates(double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks = await geocoding.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        // Check for subLocality
        if (placemarks.first.subLocality != '' && placemarks.first.subLocality!.isNotEmpty) {
          return placemarks.first.subLocality!;
        }
        // Check for locality
        else if (placemarks.first.locality != '' && placemarks.first.locality!.isNotEmpty) {
          return placemarks.first.locality!;
        }
        // Check for administrativeArea
        else if (placemarks.first.administrativeArea != '' && placemarks.first.administrativeArea!.isNotEmpty) {
          return placemarks.first.administrativeArea!;
        }
        // Check for country
        else if (placemarks.first.country != '' && placemarks.first.country!.isNotEmpty) {
          return placemarks.first.country!;
        }

      }
    } catch (e) {
      print('Error retrieving city: $e');
    }
    return 'Unknown';
  }


  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(
      backgroundColor: Color(0xFF253280),
      body: Center(
        child: SpinKitWanderingCubes(
          color: Colors.white,
        ),
      ),
    )
        : Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: Color(0xFFE9E9E9),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    buildCategoryItem('ALL', Color(0xFFFFD02A)),
                    buildCategoryItem('MOVING', Color(0xFF37D22A)),
                    buildCategoryItem('IDLE', Color(0xFF5470FF)),
                    buildCategoryItem('STOPPED', Color(0xFFD22A2A)),
                  ],
                ),
              ),
              SizedBox(height: 20),
              shipmentData.isNotEmpty
                  ? ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: shipmentData.length,
                itemBuilder: (context, index) {
                  dynamic currentShipment = shipmentData[index];
                  if (selectedCategory == 'ALL' || currentShipment['newStatus'] == selectedCategory) {
                    if (currentShipment['lat'] != null && currentShipment['lng'] != null) {
                      return FutureBuilder<String>(
                        future: getCityFromCoordinates(
                          double.parse(currentShipment['lat']),
                          double.parse(currentShipment['lng']),
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done) {
                            if (snapshot.hasData) {
                              return buildShipmentCard(currentShipment, snapshot.data!);
                            } else if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                          }
                          // If the future hasn't completed yet or if there's no data available,
                          // return a SizedBox.shrink() to indicate that there's no loading widget
                          return SizedBox.shrink();
                        },
                      );
                    } else {
                      return buildShipmentCard(currentShipment, 'Unknown');
                    }
                  } else {
                    return SizedBox.shrink();
                  }
                },
              )
                  : Text(
                'Currently No Orders',
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget buildShipmentCard(dynamic shipment, String city) {
    // Determine text color based on the selected category and vehicle status
    Color textColor;
    String status = shipment['status'];
    String engineStatus = shipment['engine'];
    var batteryStatus = shipment['battery'];

    if (selectedCategory == 'ALL') {
      switch (status) {
        case '行驶':
          textColor = Color(0xFF37D22A);
          break;
        case '静止':
          textColor = engineStatus == 'ON' ? Color(0xFF5470FF) : Color(0xFFD22A2A);
          break;
        default:
          textColor = Colors.black;
          break;
      }
    } else {
      // Set text color based on the selected category
      switch (selectedCategory) {
        case 'MOVING':
          textColor = Color(0xFF37D22A);
          break;
        case 'IDLE':
          textColor = engineStatus == 'ON' ? Color(0xFF5470FF) : Colors.black;
          break;
        case 'STOPPED':
          textColor = (engineStatus == 'OFF' && batteryStatus != null) ? Color(0xFFD22A2A) : Colors.black;
          break;
        default:
          textColor = Colors.black;
          break;
      }
    }

    // Get the current date and time
    DateTime now = DateTime.now();

    // Format the current date and time
    String formattedDateTime = DateFormat('dd-MM-yyyy, hh:mm:ss a').format(now);

    return GestureDetector(
      onTap: () {
        null;
      },
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor,
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(Icons.local_shipping, size: 36, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 50, top: 4, right: 5, bottom: 8),
              child: ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${shipment['plateNo']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    FittedBox(
                      child: Text(
                        formattedDateTime,
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Speed: ${shipment['speed']} km/h'),
                        shipment['battery'] != null ? Text('Battery: ${shipment['battery']} V') :  Text('Offline'),
                      ],
                    ),
                    SizedBox(height: 10,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if(shipment['status'] == "行驶")Text(
                          'Moving',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if(shipment['status'] == "静止" && shipment['engine'] == "ON")Text(
                          'Idle',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if(shipment['status'] == "静止" && shipment['engine'] == "OFF")Text(
                          'Stopped',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if(shipment['status'] == "离线")Text(
                          'Offline',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        // Text(
                        //   '${shipment['battery']}',
                        //   ),
                      ],
                    ),
                    SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        text: 'Location: ',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: city,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 4,
                      color: Colors.grey[100],
                    ),
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }






  Widget buildCategoryItem(String category, Color color) {
    String status = ' ';
    String engineStatus;
    int categoryCount = 0;

    // Map the category to status and engine status
    switch (category) {
      case 'ALL':
        status = 'ALL';
        engineStatus = ''; // Empty string means it's not filtering based on engine status
        categoryCount = shipmentData.length;
        break;
      case 'MOVING':
        status = '行驶';
        engineStatus = 'ON'; // Empty string means it's not filtering based on engine status
        categoryCount = shipmentData.where((shipment) => shipment['status'] == status && shipment['engine'] == engineStatus).length;
        break;
      case 'IDLE':
        status = '静止';
        engineStatus = 'ON';
        categoryCount = shipmentData.where((shipment) => shipment['status'] == status && shipment['engine'] == engineStatus).length;
        break;
      case 'STOPPED':
        engineStatus = 'OFF';
        categoryCount = shipmentData.where((shipment) => (shipment['status'] == '静止' || shipment['status'] == '离线') && shipment['engine'] == engineStatus).length;
        break;
      default:
        status = 'ALL';
        engineStatus = '';
    }


    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: selectedCategory == category ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Text(
              '$category - ',
              style: TextStyle(
                color: selectedCategory == category ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              categoryCount.toString(),
              style: TextStyle(
                color: selectedCategory == category ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

