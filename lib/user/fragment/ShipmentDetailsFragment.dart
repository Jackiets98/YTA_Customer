import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../main/utils/Constants.dart';

class ShipmentDetailsFragment extends StatefulWidget {
  final Map<String, dynamic> shipmentData;

  ShipmentDetailsFragment(this.shipmentData);

  @override
  _ShipmentDetailsFragmentState createState() =>
      _ShipmentDetailsFragmentState();
}

class _ShipmentDetailsFragmentState extends State<ShipmentDetailsFragment> {
  String address = '';
  late String shipmentCode;
  late String itemDescription;
  late List<dynamic> shipmentDetails = [];

  @override
  void initState() {
    super.initState();
    _getAddressFromLatLng();
    _fetchShipmentDetails();
  }

  Future<void> _getAddressFromLatLng() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        double.parse(widget.shipmentData['lat']),
        double.parse(widget.shipmentData['lng']),
      );

      if (placemarks.isNotEmpty) {
        Placemark firstPlacemark = placemarks[0];
        String formattedAddress = '';

        if (firstPlacemark.street != '') {
          formattedAddress += '${firstPlacemark.street}, ';
        }
        if (firstPlacemark.thoroughfare != '') {
          formattedAddress += '${firstPlacemark.thoroughfare}, ';
        }
        if (firstPlacemark.subLocality != '') {
          formattedAddress += '${firstPlacemark.subLocality}, ';
        }
        if (firstPlacemark.locality != '') {
          formattedAddress += '${firstPlacemark.locality}, ';
        }
        if (firstPlacemark.postalCode != '') {
          formattedAddress += '${firstPlacemark.postalCode} ';
        }
        if (firstPlacemark.administrativeArea != '') {
          formattedAddress += '${firstPlacemark.administrativeArea}, ';
        }
        if (firstPlacemark.country != '') {
          formattedAddress += '${firstPlacemark.country}, ';
        }

        formattedAddress = formattedAddress.trimRight().replaceAll(RegExp(r',\s*$'), '');

        setState(() {
          address = formattedAddress;
        });
      }
    } catch (e) {
      print('Error fetching address: $e');
    }
  }

  Future<void> _fetchShipmentDetails() async {
    try {
      String vehicleID = widget.shipmentData['id'].toString();
      String shipmentDetailsUrl = mBaseUrl + 'shipmentCustDetails/' + vehicleID;
      final response = await http.get(Uri.parse(shipmentDetailsUrl));

      if (response.statusCode == 200) {
        shipmentDetails = json.decode(response.body);

        setState(() {});
      } else {
        throw Exception('Failed to load shipment details');
      }
    } catch (e) {
      print('Error fetching shipment details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double lat = double.parse(widget.shipmentData['lat']);
    double lng = double.parse(widget.shipmentData['lng']);

    Color vehicleColor = _convertColor(widget.shipmentData['vehicle_color']);

    bool? engineStatus = widget.shipmentData['engine'];

    Color circleColor;
    if (engineStatus == true) {
      circleColor = Colors.green;
    } else if (engineStatus == false) {
      circleColor = Colors.red;
    } else {
      circleColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white, // Set color of arrow button to white
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Shipment Details',
          style: TextStyle(
            color: Colors.white, // Set color of text to white
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(lat, lng),
                zoom: 12.0,
              ),
              markers: _createMarkers(),
            ),
          ),
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.white,
              alignment: Alignment.topLeft,
              padding: EdgeInsets.only(left: 16.0, top: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildVehiclePlateNo(),
                      SizedBox(width: 25),
                      Icon(Icons.calendar_today, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        _getCurrentDateTime(),
                        style: TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      SizedBox(width: 25),
                      Image.asset(
                        'assets/car-engine.png', // Replace with the actual path to your asset image
                        color: Colors.grey,
                        width: 28,
                        height: 28,// Set the color of the asset image
                      ),
                      SizedBox(width: 4),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Address:',
                    style: TextStyle(
                      fontSize: 14.0,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '$address',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Divider(
                    thickness: 2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'All Shipments:',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16), // Add horizontal padding
                      child: ListView.builder(
                        itemCount: shipmentDetails.length,
                        itemBuilder: (context, index) {
                          var detail = shipmentDetails[index];
                          List<String> suppliers = detail['supplier_name'].split("==");
                          List<String> amounts = detail['amount'].split("==");
                          List<String> colorHexValues = detail['item_color'].split("==");

                          List<Widget> detailsRows = [];

                          for (int i = 0; i < suppliers.length; i++) {
                            Color? color = _convertColor(colorHexValues[i]);

                            detailsRows.add(
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4), // Add vertical and horizontal padding
                                child: Row(
                                  children: [
                                    // Expanded(
                                    //   flex: 1,
                                    //   child: SizedBox( // Wrap itemCodes with SizedBox to provide a fixed width
                                    //     width: 60, // Adjust the width as needed for proper alignment
                                    //     child: Padding(
                                    //       padding: EdgeInsets.only(right: 8), // Add padding between item_code and other text
                                    //       child: Text(
                                    //         "Shipment Details",
                                    //         style: TextStyle(fontWeight: FontWeight.bold), // Make item_code text bold
                                    //         overflow: TextOverflow.ellipsis,
                                    //       ),
                                    //     ),
                                    //   ),
                                    // ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        suppliers[i],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            amounts.length > i ? amounts[i] : '',
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (colorHexValues[i].isNotEmpty) // Check if color is not empty
                                            Row(
                                              children: [
                                                Text(
                                                  getColorName(colorHexValues[i]),
                                                  style: TextStyle(fontSize: 10), // Set text size to 10
                                                ),
                                                SizedBox(width: 4), // Add spacing between text and CircleAvatar
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircleAvatar(
                                                    backgroundColor: color,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return Padding(
                            padding: EdgeInsets.only(bottom: 24), // Add more bottom padding between cards
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${detail['shipment_code']}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _getShipmentCodeColor(detail['delivery_status']),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              '${DateFormat('dd-MM-yyyy, hh:mm:ss a').format(DateTime.parse(detail['created_at']))}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12.0, // Adjust the font size to match a subtitle
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              textAlign: TextAlign.end,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 16), // Add some space below the shipment code and created at
                                    ...detailsRows, // Add the list of detail rows
                                  ],
                                ),
                              ),
                            ),
                          );

                        },
                      ),
                    ),
                  ),







                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehiclePlateNo() {
    Color backgroundColor;

    String vehicleStatus = widget.shipmentData['vehicleStatus'];

    switch (vehicleStatus) {
      case 'Idle':
        backgroundColor = Color(0xFF5470FF);
        break;
      case 'Moving':
        backgroundColor = Color(0xFF37D22A);
        break;
      case 'Stopped':
        backgroundColor = Color(0xFFD22A2A);
        break;
      case 'Offline':
        backgroundColor = Colors.black;
        break;
      default:
        backgroundColor = Colors.grey;
    }

    return Card(
      elevation: 4.0,
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          widget.shipmentData['plate_no'],
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Set<Marker> _createMarkers() {
    return {
      Marker(
        markerId: MarkerId(widget.shipmentData['plate_no']),
        position: LatLng(
          double.parse(widget.shipmentData['lat']),
          double.parse(widget.shipmentData['lng']),
        ),
        infoWindow: InfoWindow(
          title: widget.shipmentData['plate_no'],
        ),
      ),
    };
  }

  Color _convertColor(String hexColor) {
    if (hexColor == '') {
      return Color(0xFF000000); // Return white if hexColor is null
    } else {
      hexColor = hexColor.replaceAll('#', '');
      int colorInt = int.parse(hexColor, radix: 16);
      return Color(0xFF000000 + colorInt);
    }
  }


  String _getCurrentDateTime() {
    DateTime now = DateTime.now();
    String formattedDateTime =
        '${DateFormat('dd-MM-yyyy, hh:mm a').format(now)}';
    return formattedDateTime;
  }

  Color _getShipmentCodeColor(int deliveryStatus) {
    switch (deliveryStatus) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      default:
        return Colors.black;
    }
  }

  String getColorName(String colorHexValue) {
    switch (colorHexValue) {
      case '#ff0000':
        return 'RED';
      case '#0000ff':
        return 'BLUE';
      case '#000000':
        return 'BLACK';
      case '#808080':
        return 'GREY';
      case '#ffff00':
        return 'YELLOW';
      case '#fffff0':
        return 'WHITE';
      default:
        return 'NA';
    }
  }

}
