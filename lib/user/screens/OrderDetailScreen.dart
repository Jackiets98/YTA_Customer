import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:intl/intl.dart';
import 'package:yes_sir/user/components/PaymentScreen.dart';
import '../../main.dart';
import 'package:http/http.dart' as http;
import '../../main/components/BodyCornerWidget.dart';
import '../../main/models/ExtraChargeRequestModel.dart';
import '../../main/models/LoginResponse.dart';
import '../../main/models/OrderListModel.dart';
import '../../main/screens/LoginScreen.dart';
import '../../main/utils/Colors.dart';
import '../../main/utils/Common.dart';
import '../../main/utils/Constants.dart';
import '../../main/utils/Widgets.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../main/models/OrderDetailModel.dart';
import 'CustomTimelineTile.dart';

class OrderDetailScreen extends StatefulWidget {
  static String tag = '/OrderDetailScreen';

  final String? orderId;
  final String? itemCode;
  final String? driverPhoneNum;
  final String? customerPhoneNum;
  final String? pickUpLocation;
  final String? dropOffLocation;
  final String? departedTime;
  final String? deliveredTime;
  final String? status;
  final String? itemDesc;
  final int? amount;
  final String? remarks;
  final int? rating;
  final String? createdAt;
  final String? imei;

  OrderDetailScreen({
    required this.orderId,
    required this.itemCode,
    required this.itemDesc,
    required this.driverPhoneNum,
    required this.customerPhoneNum,
    required this.pickUpLocation,
    required this.dropOffLocation,
    required this.departedTime,
    required this.deliveredTime,
    required this.status,
    required this.amount,
    required this.remarks,
    required this.rating,
    required this.createdAt,
    required this.imei
  });

  @override
  OrderDetailScreenState createState() => OrderDetailScreenState();
}

class OrderDetailScreenState extends State<OrderDetailScreen> {
  UserData? userData;

  OrderData? orderData;
  List<OrderHistory>? orderHistory;
  Payment? payment;
  List<ExtraChargeRequestModel> list = [];
  List<CustomTimelineTile> timelineTiles = [];
  int rating = 0;
  String? userID;
  bool hasRated = false;

  void updateRating(int newRating) {
    setState(() {
      rating = newRating;
      sendRating(newRating);
      hasRated = true;
    });
  }

  @override
  void initState() {
    super.initState();
    afterBuildCreated(() {
      init();
      fetchUserRating();
    });
  }

  Future<void> init() async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    userID = sharedPreferences.getString('id');
    var deviceID = sharedPreferences.getString('androidID');

    LiveStream().on('UpdateLanguage', (p0) {
      setState(() {});
    });
    LiveStream().on('UpdateTheme', (p0) {
      setState(() {});
    });

    if(widget.rating != 0){
      setState(() {
        hasRated = true;
      });
    }

    final url = Uri.parse( mBaseUrl +'userDetail/' + userID!);

    final response = await http.get(
      url,
      headers: headers, // Encode the request body to JSON
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        if(deviceID != responseData['user_device']){
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.clear();
          Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (ctx) => LoginScreen()), (route) => false);

          // Handle registration error
          Fluttertoast.showToast(
            msg: "Your account has been login from another device.",
            toastLength: Toast.LENGTH_SHORT, // Duration for which the toast message will be displayed
            gravity: ToastGravity.BOTTOM, // Position of the toast message
            timeInSecForIosWeb: 1, // Only for iOS and web
            backgroundColor: Colors.black.withOpacity(0.7), // Background color of the toast
            textColor: Colors.white, // Text color of the toast
            fontSize: 16.0, // Font size of the text
          );
        }else {
          fetchOrderTimelines();
        }
      } else {
        // Handle HTTP request error
        Fluttertoast.showToast(
          msg: "There is an error occurred.",
          toastLength: Toast.LENGTH_SHORT, // Duration for which the toast message will be displayed
          gravity: ToastGravity.BOTTOM, // Position of the toast message
          timeInSecForIosWeb: 1, // Only for iOS and web
          backgroundColor: Colors.black.withOpacity(0.7), // Background color of the toast
          textColor: Colors.white, // Text color of the toast
          fontSize: 16.0, // Font size of the text
        );
      }
    } else {
      // Handle HTTP request error
      Fluttertoast.showToast(
        msg: "Something Went Wrong",
        toastLength: Toast.LENGTH_SHORT, // Duration for which the toast message will be displayed
        gravity: ToastGravity.BOTTOM, // Position of the toast message
        timeInSecForIosWeb: 1, // Only for iOS and web
        backgroundColor: Colors.black.withOpacity(0.7), // Background color of the toast
        textColor: Colors.white, // Text color of the toast
        fontSize: 16.0, // Font size of the text
      );
    }
  }

  Future<void> fetchOrderTimelines() async {
    final shipmentId = widget.orderId; // Assuming that the order ID matches the shipment ID.
    final apiUrl = Uri.parse(mBaseUrl + 'orderTimelines/$shipmentId');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final driverTimelines = data['driver_timelines'];

        // Call the function to build timeline tiles
        buildTimelineTiles(driverTimelines);

        setState(() {}); // Update the UI
      } else {
        // Handle API errors
        print('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or other errors
      print('Error: $e');
    }
  }

  Future<void> sendRating(int rating) async {
    final url = Uri.parse('https://app.yessirgps.com/api/store-rating/${widget.orderId}');
    final response = await http.post(
      url,
      body: {'rating': rating.toString()}, // Convert rating to a string
    );

    if (response.statusCode == 200) {
      print('Rating sent successfully to Laravel.');
      Fluttertoast.showToast(
        msg: "Thank you for your rating!",
        toastLength: Toast.LENGTH_SHORT, // Duration for which the toast message will be displayed
        gravity: ToastGravity.BOTTOM, // Position of the toast message
        timeInSecForIosWeb: 1, // Only for iOS and web
        backgroundColor: Colors.black.withOpacity(0.7), // Background color of the toast
        textColor: Colors.white, // Text color of the toast
        fontSize: 16.0, // Font size of the text
      );
    } else {
      print('Failed to send rating to Laravel.');
    }
  }

  Future<void> fetchUserRating() async {
    final url = Uri.parse('https://app.yessirgps.com/api/get-rating/${widget.orderId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // Parse the rating from the API response
      final userRating = int.parse(response.body);
      setState(() {
        rating = userRating;
      });
    } else {
      print('Failed to fetch user rating from Laravel.');
    }
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  void buildTimelineTiles(List<dynamic> driverTimelines) {
    timelineTiles.clear();
    if (driverTimelines != null) {
      for (var timeline in driverTimelines) {
        final isPast = true; // Customize this based on your logic

        // Check if the 'location' and 'created_at' keys exist and are not null
        final location = timeline['location'] != null
            ? timeline['location'] as String
            : 'Location not found';
        final createdAt = timeline['created_at'] != null
            ? timeline['created_at'] as String
            : 'Time not available';
        final id = timeline['id'] != null
            ? timeline['id'] as String
            : 'ID not available';

        final tile = CustomTimelineTile(
          isFirst: timeline == driverTimelines.first,
          isLast: timeline == driverTimelines.last,
          isPast: isPast,
          location: location,
          createdAt: createdAt,
          id: id,
          dropOffLocation: widget.dropOffLocation!,
        );

        timelineTiles.add(tile);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    afterBuildCreated(() {
      // appStore.setLoading(false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        finish(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Order Details')),
        body: BodyCornerWidget(
          child: Stack(
            children: [
              // orderData != null?
              Stack(
                children: [
                  SingleChildScrollView(
                    padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(language.orderId, style: boldTextStyle(size: 20)),
                            // Text('#${orderData!.id}', style: boldTextStyle(size: 20)),
                            Text(widget.itemCode!, style: boldTextStyle(size: 20)),
                          ],
                        ),
                        16.height,
                        // Text('${language.createdAt} ${printDate(orderData!.date.toString())}', style: secondaryTextStyle()),
                        Text('${language.createdAt} ${widget.createdAt!}', style: secondaryTextStyle()),
                        Divider(height: 30, thickness: 1),
                        Column(
                          children: [
                            Row(
                              children: [
                                ImageIcon(AssetImage('assets/icons/ic_pick_location.png'), size: 24, color: colorPrimary),
                                16.width,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${widget.departedTime == null ? 'Not Picked Yet' : '${language.pickedAt} ${widget.departedTime}'}', style: secondaryTextStyle()).paddingOnly(bottom: 8),
                                    Text('${widget.pickUpLocation}', style: primaryTextStyle()),
                                    // if (orderData!.pickupPoint!.contactNumber != null)
                                    //   Row(
                                    //     children: [
                                    //       Icon(Icons.call, color: Colors.green, size: 18).onTap(() {
                                    //         commonLaunchUrl('tel:${orderData!.pickupPoint!.contactNumber}');
                                    //       }),
                                    //       8.width,
                                    //       Text('${orderData!.pickupPoint!.contactNumber}', style: secondaryTextStyle()),
                                    //     ],
                                    //   ).paddingOnly(top: 8),
                                    Row(
                                      children: [
                                        Icon(Icons.call, color: Colors.green, size: 18).onTap(() {
                                          commonLaunchUrl('tel:${widget.driverPhoneNum}');
                                        }),
                                        8.width,
                                        Text('${widget.driverPhoneNum}', style: secondaryTextStyle()),
                                      ],
                                    ).paddingOnly(top: 8),
                                    // if (orderData!.pickupDatetime == null && orderData!.pickupPoint!.endTime != null && orderData!.pickupPoint!.startTime != null)
                                    //   Text('${language.note} ${language.courierWillPickupAt} ${DateFormat('dd MMM yyyy').format(DateTime.parse(orderData!.pickupPoint!.startTime!).toLocal())} ${language.from} ${DateFormat('hh:mm').format(DateTime.parse(orderData!.pickupPoint!.startTime!).toLocal())} ${language.to} ${DateFormat('hh:mm').format(DateTime.parse(orderData!.pickupPoint!.endTime!).toLocal())}',
                                    //           style: secondaryTextStyle())
                                    //       .paddingOnly(top: 8),
                                    //   Text('${language.note} ${language.courierWillPickupAt} ${DateFormat('dd MMM yyyy').format(DateTime.parse('2023-09-12 08:00:00').toLocal())} ${language.from} ${DateFormat('hh:mm').format(DateTime.parse('2023-09-12 08:00:00').toLocal())} ${language.to} ${DateFormat('hh:mm').format(DateTime.parse('2023-09-12 12:00:00').toLocal())}',
                                    //       style: secondaryTextStyle())
                                    //       .paddingOnly(top: 8),
                                    // if (orderData!.pickupPoint!.description.validate().isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8.0),
                                      child: ReadMoreText(
                                        // '${language.remark}: ${orderData!.pickupPoint!.description.validate()}',
                                        widget.remarks != null ?'${language.remark}: ${widget.remarks}':'${language.remark}: No Remarks',
                                        trimLines: 3,
                                        style: primaryTextStyle(size: 14),
                                        colorClickableText: colorPrimary,
                                        trimMode: TrimMode.Line,
                                        trimCollapsedText: language.showMore,
                                        trimExpandedText: language.showLess,
                                      ),
                                    ),
                                  ],
                                ).expand(),
                              ],
                            ),
                            16.height,
                            Row(
                              children: [
                                ImageIcon(AssetImage('assets/icons/ic_delivery_location.png'), size: 24, color: colorPrimary),
                                16.width,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // if (orderData!.deliveryDatetime != null)
                                    Text('${widget.deliveredTime == null ? 'Not Delivered Yet' : '${language.deliveredAt} ${widget.deliveredTime}'}', style: secondaryTextStyle()).paddingOnly(bottom: 8),
                                    Text('${widget.dropOffLocation}', style: primaryTextStyle()),
                                    // if (orderData!.deliveryPoint!.contactNumber != null)
                                    Row(
                                      children: [
                                        Icon(Icons.call, color: Colors.green, size: 18).onTap(() {
                                          commonLaunchUrl('tel:${widget.customerPhoneNum}');
                                        }),
                                        8.width,
                                        Text('${widget.customerPhoneNum}', style: secondaryTextStyle()),
                                      ],
                                    ).paddingOnly(top: 8),
                                    // if (orderData!.deliveryDatetime == null && orderData!.deliveryPoint!.endTime != null && orderData!.deliveryPoint!.startTime != null)
                                    Text('${language.note} ${language.courierWillDeliverAt}${DateFormat('dd MMM yyyy').format(DateTime.parse('2023-09-12 14:00:00').toLocal())} ${language.from} ${DateFormat('hh:mm').format(DateTime.parse('2023-09-12 14:00:00').toLocal())} ${language.to} ${DateFormat('hh:mm').format(DateTime.parse('2023-09-12 18:00:00').toLocal())}',
                                        style: secondaryTextStyle())
                                        .paddingOnly(top: 8),
                                    // if (orderData!.deliveryPoint!.description.validate().isNotEmpty)
                                    //   Padding(
                                    //     padding: EdgeInsets.only(top: 8.0),
                                    //     child: ReadMoreText(
                                    //       '${language.remark}: ${orderData!.deliveryPoint!.description.validate()}',
                                    //       trimLines: 3,
                                    //       style: primaryTextStyle(size: 14),
                                    //       colorClickableText: colorPrimary,
                                    //       trimMode: TrimMode.Line,
                                    //       trimCollapsedText: language.showMore,
                                    //       trimExpandedText: language.showLess,
                                    //     ),
                                    //   ),
                                  ],
                                ).expand(),
                              ],
                            ),
                          ],
                        ),
                        // Align(
                        //   alignment: Alignment.topRight,
                        //   child: AppButton(
                        //     elevation: 0,
                        //     color: Colors.transparent,
                        //     padding: EdgeInsets.all(6),
                        //     shapeBorder: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(defaultRadius),
                        //       side: BorderSide(color: colorPrimary),
                        //     ),
                        //     child: Row(
                        //       mainAxisSize: MainAxisSize.min,
                        //       children: [
                        //         Text(language.viewHistory, style: primaryTextStyle(color: colorPrimary)),
                        //         Icon(Icons.arrow_right, color: colorPrimary),
                        //       ],
                        //     ),
                        //     onTap: () {
                        //       OrderHistoryScreen(orderHistory: orderHistory.validate()).launch(context);
                        //     },
                        //   ),
                        // ),
                        Divider(height: 30, thickness: 1),
                        Text(language.parcelDetails, style: boldTextStyle(size: 16)),
                        12.height,
                        Container(
                          decoration: BoxDecoration(color: appStore.isDarkMode ? scaffoldSecondaryDark : colorPrimary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: boxDecorationWithRoundedCorners(
                                        borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor, width: appStore.isDarkMode ? 0.2 : 1), backgroundColor: Colors.transparent),
                                    padding: EdgeInsets.all(8),
                                    child: Image.asset(parcelTypeIcon('Box'.validate()), height: 24, width: 24, color: Colors.grey),
                                  ),
                                  8.width,
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${widget.itemDesc}'.validate(), style: boldTextStyle()),
                                      4.height,
                                      Text('2.0 ton', style: secondaryTextStyle()),
                                    ],
                                  ).expand(),
                                ],
                              ),
                              Divider(height: 30),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Number of item', style: primaryTextStyle()),
                                  Text('${widget.amount}', style: primaryTextStyle()),
                                ],
                              ),
                            ],
                          ),
                        ),
                        24.height,
                        16.height,
                        widget.status! == '1' ?
                          Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            children: [
                              commonButton('View Live Location', () {
                                GoogleMapScreen(imei: widget.imei!).launch(context);
                              }, width: context.width()),
                              8.height,
                            ],
                          ),
                        ): SizedBox(height: 1,),
                        Column(
                          children: [
                            if (timelineTiles.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Order Timelines',
                                  style: boldTextStyle(size: 21),
                                ),
                              ),
                            ListView.builder(
                              itemCount: timelineTiles.length,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                return timelineTiles[index];
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 30,),
                        if (widget.status! == '2')
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(0, 10, 0, 20),
                                child: Text(
                                  'Rate This Delivery',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return GestureDetector(
                                    onTap: () => hasRated? null:updateRating(index + 1),
                                    child: Icon(
                                      rating >= index + 1 ? Icons.star : Icons.star_border,
                                      color: rating >= index + 1 ? Colors.yellow : Colors.grey,
                                      size: 40,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          )
                        else
                        // Show a SizedBox in all other cases
                          SizedBox()
                      ],
                    ),
                  ),
                  // Align(
                  //   alignment: Alignment.bottomCenter,
                  //   child: commonButton('Complete Order', () {
                  //     ReturnOrderScreen(orderData!).launch(context);
                  //   }, width: context.width())
                  //       .paddingAll(16),
                  // ),
                ],
              ),
              // : SizedBox(),
              Observer(builder: (context) => loaderWidget().visible(appStore.isLoading)),
            ],
          ),
        ),
      ),
    );
  }
}
