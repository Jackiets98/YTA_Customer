import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main/utils/Constants.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import '../components/RotatingLoadingWidget.dart';
import 'ShipmentDetailsFragment.dart';
import 'package:intl/intl.dart';


class HomeFragment extends StatefulWidget {
  @override
  _HomeFragmentState createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment> {
  String selectedCategory = 'ALL';
  List<dynamic> shipmentData = [];
  Set<String> displayedPlateNumbers = Set();
  late StreamController<List<dynamic>> _shipmentStreamController;

  Stream<List<dynamic>> get shipmentStream => _shipmentStreamController.stream;

  @override
  void initState() {
    super.initState();
    _shipmentStreamController =
    StreamController<List<dynamic>>.broadcast(); // Use broadcast for multiple subscribers
    fetchAndProcessData(); // Initial data fetch
  }

  @override
  void dispose() {
    _shipmentStreamController.close();
    super.dispose();
  }

  Future<void> fetchAndProcessData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? obtainedID = prefs.getString('id');
      String? deviceID = prefs.getString('androidID');

      final String apiUrl = mBaseUrl + 'vehicleCustDetails/' + obtainedID!;
      final Map<String, String> headers = {
        'Content-Type': 'application/json',
        // Add any additional headers if required
      };

      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        List<dynamic> shipments = json.decode(response.body)['shipments'];
        if (!_shipmentStreamController.isClosed) {
          _shipmentStreamController.add(shipments); // Add fetched data to the stream
        } else {
          // Handle the case where the stream controller is already closed
          print('Stream controller is closed, unable to add data');
        }
      } else {
        throw Exception('Failed to load shipment data');
      }
    } catch (e) {
      if (!_shipmentStreamController.isClosed) {
        _shipmentStreamController.addError(e); // Add error to the stream
      } else {
        // Handle the case where the stream controller is already closed
        print('Stream controller is closed, unable to add error');
      }
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
    return Scaffold(
      backgroundColor: Color(0xFFE9E9E9),
      body: RefreshIndicator(
        onRefresh: () => fetchAndProcessData(),
        child: Container(
          color: Color(0xFFE9E9E9),
          child: SingleChildScrollView(
            child: StreamBuilder<List<dynamic>>(
              stream: shipmentStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height / 3,),
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('Currently No Orders', style: TextStyle(fontSize: 20)),
                  );
                } else {
                  List<dynamic> shipmentData = snapshot.data!;

                  // Create a map to hold the shipment data for each plate number
                  Map<String, dynamic> uniqueShipmentsMap = {};

                  // Loop through each shipment
                  for (var shipment in shipmentData) {
                    String plateNo = shipment['plate_no'];
                    dynamic deliveryStatusValue = shipment['delivery_status']; // Use dynamic type for flexibility
                    int? deliveryStatus;
                    if (deliveryStatusValue is int) {
                      deliveryStatus = deliveryStatusValue; // If it's an integer, assign it directly
                    } else if (deliveryStatusValue is String) {
                      deliveryStatus = int.tryParse(deliveryStatusValue); // Try parsing the string to an integer
                    }

                    // Check if the shipment's delivery status is 1 or if there's no existing shipment for this plate number
                    if (deliveryStatus == 1 || uniqueShipmentsMap[plateNo] == null) {
                      uniqueShipmentsMap[plateNo] = shipment;
                    }
                  }

                  // Convert the map values back to a list
                  List<dynamic> uniqueShipments = uniqueShipmentsMap.values.toList();

                  return Column(
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
                            buildCategoryItem('ALL', Color(0xFFFFD02A), shipmentData),
                            buildCategoryItem('MOVING', Color(0xFF37D22A), shipmentData),
                            buildCategoryItem('IDLE', Color(0xFF5470FF), shipmentData),
                            buildCategoryItem('STOPPED', Color(0xFFD22A2A), shipmentData),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: uniqueShipments.length,
                        itemBuilder: (context, index) {
                          dynamic currentShipment = uniqueShipments[index];
                          if ((selectedCategory == 'ALL' || currentShipment['vehicleStatus'].toUpperCase() == selectedCategory)) {
                            if (currentShipment['lat'] != null &&
                                currentShipment['lng'] != null) {
                              return FutureBuilder<String>(
                                future: getCityFromCoordinates(
                                    double.parse(currentShipment['lat']),
                                    double.parse(currentShipment['lng'])),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.done) {
                                    if (snapshot.hasData) {
                                      return buildShipmentCard(
                                          currentShipment, snapshot.data!);
                                    } else if (snapshot.hasError) {
                                      return Text('Error: ${snapshot.error}');
                                    }
                                  }
                                  return SizedBox();
                                },
                              );
                            } else {
                              return buildShipmentCard(
                                  currentShipment, 'Unknown');
                            }
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }





  @override
  Widget buildShipmentCard(dynamic shipment, String city) {
    List<String> descriptionParts = (shipment['item_description'] ?? '').split('==');
    List<String> amountParts = (shipment['amount'] ?? '').split('==');
    List<String>? colorParts = (shipment['item_color'] ?? '').split('==');
    int? deliveryStatus = shipment['delivery_status'] as int?;
    String createdAt = DateFormat('dd-MM-yyyy, hh:mm:ss a').format(DateTime.parse(shipment['created_at'] ?? ''));


    // Check if all required fields are null
    bool noShipmentDetails = descriptionParts.isEmpty && amountParts.isEmpty && (colorParts == null || colorParts.isEmpty);

    // Check if there are shipment details available
    bool hasShipments = deliveryStatus != null && deliveryStatus == 1 && !noShipmentDetails;

    // Determine text color based on the selected category and vehicle status
    Color textColor;
    if (selectedCategory == 'ALL') {
      switch (shipment['vehicleStatus'].toUpperCase()) {
        case 'MOVING':
          textColor = Color(0xFF37D22A);
          break;
        case 'IDLE':
          textColor = Color(0xFF5470FF);
          break;
        case 'STOPPED':
          textColor = Color(0xFFD22A2A);
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
          textColor = Color(0xFF5470FF);
          break;
        case 'STOPPED':
          textColor = Color(0xFFD22A2A);
          break;
        default:
          textColor = Colors.black;
          break;
      }
    }

    // Widget list for color circles and total amounts
    List<Widget> colorWidgets = [];
    int totalQuantity = 0;

    if (hasShipments) {
      // Calculate total sum of amounts
      totalQuantity = amountParts.map((amount) => int.tryParse(amount) ?? 0).fold(0, (prev, amount) => prev + amount);

      // Map to accumulate total amounts for each color category
      Map<String, int> colorAmountMap = {};
      for (int i = 0; i < colorParts!.length; i++) {
        String color = colorParts[i];
        if (color.isNotEmpty) {
          int amount = int.tryParse(amountParts[i]) ?? 0;
          colorAmountMap[color] = (colorAmountMap[color] ?? 0) + amount;
        }
      }

      colorAmountMap.forEach((color, totalAmount) {
        colorWidgets.add(
          Row(
            children: [
              SizedBox(
                width: 8,
                height: 8,
                child: CircleAvatar(
                  backgroundColor: Color(int.parse("0xff" + color.substring(1))),
                ),
              ),
              SizedBox(width: 4), // Add horizontal spacing
              Text(totalAmount.toString()),
            ],
          ),
        );
        colorWidgets.add(SizedBox(width: 8));
      });
    }

    // Add vertical padding between rows in the details section
    List<Widget> detailsRows = [];
    if (hasShipments) {
      detailsRows.add(
        Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
            'Delivering Details:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );

      // Iterate over each shipment detail
      for (int i = 0; i < descriptionParts.length; i++) {
        detailsRows.add(
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    descriptionParts[i],
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        amountParts.length > i ? amountParts[i] : '',
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (colorParts != null &&
                          colorParts.length > i &&
                          colorParts[i].isNotEmpty)
                        SizedBox(
                          width: 8,
                          height: 8,
                          child: CircleAvatar(
                            backgroundColor: Color(int.parse(
                                "0xff" + colorParts[i].substring(1))),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } else {
      // Display a message indicating no shipment details
      detailsRows.add(
        Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'No Shipments Available',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center, // Align the text to the center
          ),
        ),
      );
    }


    return GestureDetector(
      onTap: () {
        // Navigate to ShipmentDetailsFragment when card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ShipmentDetailsFragment(shipment)),
        );
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
                  color: textColor, // Use the textColor variable here
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
                    Text('${shipment['plate_no']}',
                      style: TextStyle(fontWeight: FontWeight.bold),),
                    FittedBox( // Use FittedBox to fit the child within available space
                      child: Text(
                        createdAt, // Use the createdAt time here
                        style: TextStyle(
                          color: Colors.grey, // Adjust text color as needed
                          fontSize: 12, // Adjust font size as needed
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
                        Text(
                          '${shipment['vehicleStatus']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20), // Add some space between the status and city
                    RichText(
                      text: TextSpan(
                        text: 'Location: ',
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black, // Optional: adjust the color as needed
                        ),
                        children: <TextSpan>[
                          TextSpan(
                            text: city,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Optional: adjust the color as needed
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Display the city
                    Container(
                      height: 4, // Increase the height for a thicker divider
                      color: Colors.grey[100], // Adjust color as needed
                    ),// Add a divider below the city
                    SizedBox(height: 8),
                    ...detailsRows, // Use detailsRows here
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align the children to the left and right edges of the row
                      children: [
                        Row(
                          children: colorWidgets,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Add padding to the container
                          decoration: BoxDecoration(
                            color: Colors.lightBlueAccent, // Set the background color
                            borderRadius: BorderRadius.circular(4), // Add border radius
                          ),
                          child: Text(
                            'Total: $totalQuantity',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), // Set font color to white
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }




  Widget buildCategoryItem(String category, Color color, List<dynamic> data) {
    // Calculate the total number of unique plates for the current category
    Set<String> uniquePlateNumbers = Set();
    for (var shipment in data) {
      String plateNo = shipment['plate_no'];
      if (category == 'ALL' || shipment['vehicleStatus'].toUpperCase() == category) {
        uniquePlateNumbers.add(plateNo);
      }
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
              '$category - ${uniquePlateNumbers.length}',
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
