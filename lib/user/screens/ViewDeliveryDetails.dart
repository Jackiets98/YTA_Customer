import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:nb_utils/nb_utils.dart';
import 'dart:convert';
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as img;

import '../../main/utils/Constants.dart'; // Import the image package

class ViewDeliveryDetails extends StatefulWidget {
  final String id;
  final String destination;

  ViewDeliveryDetails({required this.id, required this.destination});

  @override
  _ViewDeliveryDetailsState createState() => _ViewDeliveryDetailsState();
}

class _ViewDeliveryDetailsState extends State<ViewDeliveryDetails> {
  String? location;
  late String description;
  String? mediaDB;
  String? mediaURL;
  bool isLoading = true;
  VideoPlayerController? videoController;
  GoogleMapController? mapController;
  LatLng? locationLatLng;
  String userAddress = 'Loading...';
  String? destination;

  bool showFullDescription = false;
  LatLng? destinationLatLng;
  BitmapDescriptor? warehouseIcon; // Custom warehouse icon

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });
    fetchOrderDetails();
    loadWarehouseIcon(); // Load the custom warehouse icon
  }

  @override
  void dispose() {
    super.dispose();
    videoController?.dispose();
  }

  void fetchOrderDetails() async {
    final apiUrl = Uri.parse(mBaseUrl + 'viewOrderDetails/${widget.id}');

    try {
      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        location = data['location'];
        description = data['description'];
        mediaDB = data['media'];
        mediaURL = DOMAIN_URL + "/media/" + mediaDB!;

        if (mediaDB!.toLowerCase().contains('.mp4')) {
          videoController = VideoPlayerController.network(mediaURL!);
          await videoController!.initialize();
        }

        locationLatLng = await getLocationCoordinates(location!);
        destinationLatLng = await getLocationCoordinates(widget.destination);

        setState(() {
          isLoading = false;
        });
      } else {
        // Handle API errors
        print('Failed to fetch delivery details: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network or other errors
      print('Error: $e');
    }
  }

  Future<LatLng?> getLocationCoordinates(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      return LatLng(locations[0].latitude, locations[0].longitude);
    } catch (e) {
      print('Error getting location coordinates: $e');
      return null;
    }
  }

  Future<void> loadWarehouseIcon() async {
    final ByteData data = await rootBundle.load('assets/warehouse_icon.png');
    final Uint8List bytes = data.buffer.asUint8List();

    // Decode the image
    final img.Image? image = img.decodeImage(Uint8List.fromList(bytes));

    // Resize the image to your desired width and height
    final img.Image resizedImage = img.copyResize(image!, width: 128, height: 128);

    // Encode the resized image back to bytes
    final Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));

    warehouseIcon = BitmapDescriptor.fromBytes(resizedBytes);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View Delivery Details'),
      ),
      body: isLoading
          ? Center(
        child: SpinKitWanderingCubes(
          color: Color(0xFF253280),
          size: 50.0,
        ),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (videoController != null)
              Container(
                height: 325, // Adjust the height as needed
                child: AspectRatio(
                  aspectRatio: 16 / 9, // Adjust the aspect ratio as needed
                  child: VideoPlayerWidget(videoController: videoController!),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey, // Border color
                    width: 1.0, // Border width
                  ),
                ),
                child: Image.network(
                  mediaURL!,
                  width: double.infinity,
                  height: 325, // Adjust the height as needed
                  fit: BoxFit.cover,
                ),
              ),

            SizedBox(height: 16),

            if (description != null && description.isNotEmpty)
              Container(
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey, // Border color
                    width: 1.0, // Border width
                  ),
                  borderRadius: BorderRadius.circular(8.0), // Border radius
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description',
                        style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                      ),
                      SizedBox(height: 10),
                      Text(
                        showFullDescription
                            ? description // Show the full description if the state variable is true
                            : (description.length > 100
                            ? (showFullDescription
                            ? description
                            : description.substring(0, 100) + '...')
                            : description), // Trim the description if it's too long
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.justify,
                        maxLines: showFullDescription ? null : 2, // Limit to 2 lines if not expanded
                        overflow: showFullDescription ? null : TextOverflow.ellipsis, // Hide "..." if not expanded
                      ),
                      if (description.length > 100)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              showFullDescription = !showFullDescription;
                            });
                          },
                          child: Text(showFullDescription ? 'View Less' : 'View More...'),
                        ),
                    ],
                  ),
                ),
              ),
            SizedBox(height: 16),

            // Check if locationLatLng and destinationLatLng are valid before displaying the map
            if (locationLatLng != null && destinationLatLng != null)
              Container(
                height: 200,
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: locationLatLng!,
                    zoom: 15,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    mapController = controller;
                  },
                  markers: {
                    Marker(
                      markerId: MarkerId("Delivery Location"),
                      position: locationLatLng!,
                      infoWindow: InfoWindow(
                        title: 'Delivery Location',
                      ),
                    ),
                    Marker(
                      markerId: MarkerId("Destination Location"),
                      position: destinationLatLng!,
                      infoWindow: InfoWindow(
                        title: 'Destination Location',
                      ),
                      icon: warehouseIcon!, // Use the custom warehouse icon here
                    ),
                  },
                ),
              )
            else
              Text('Invalid location data'), // Display a message for invalid location data
          ],
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController? videoController;

  VideoPlayerWidget({required this.videoController});

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  @override
  void initState() {
    super.initState();
    widget.videoController!.initialize().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.videoController!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          VideoPlayer(widget.videoController!),
          if (!widget.videoController!.value.isInitialized)
            CircularProgressIndicator()
          else if (widget.videoController!.value.isPlaying)
            IconButton(
              icon: Icon(Icons.pause),
              onPressed: () {
                setState(() {
                  widget.videoController!.pause();
                });
              },
            )
          else
            IconButton(
              icon: Icon(Icons.play_arrow),
              onPressed: () {
                setState(() {
                  widget.videoController!.play();
                });
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    widget.videoController!.dispose();
  }
}
