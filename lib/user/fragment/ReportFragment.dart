import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../main/components/VoiceMessagePlayer.dart';
import '../../main/utils/Constants.dart';
import '../components/VideoPlayerScreen.dart';

class ReportFragment extends StatefulWidget {
  @override
  _ReportFragmentState createState() => _ReportFragmentState();
}

class _ReportFragmentState extends State<ReportFragment> {
  bool _isDriverSelected = true;
  List<dynamic> _adminReports = [];
  List<dynamic> driverReports = [];
  int _currentPage = 1; // Keep track of the current page number
  int _driverCurrentPage = 1;
  bool _isLoading = false; // Flag to indicate if data is being loaded


  @override
  void initState() {
    super.initState();
    fetchAdminReports();
    fetchDriverReports();
  }

  void _showImageDialog(BuildContext context, List<String> images, String imageUrl) {
    int initialPageIndex = images.indexOf(imageUrl);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: Container(
            color: Colors.black.withOpacity(0.8),
            child: Center(
              child: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    controller: PageController(initialPage: initialPageIndex),
                    itemBuilder: (context, index) {
                      return Center(
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.8,
                          height: MediaQuery.of(context).size.width * 0.8,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              Image.network(
                                images[index],
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 10,
                                right: 10,
                                child: IconButton(
                                  icon: Icon(Icons.close),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> fetchAdminReports({int page = 1}) async {
    if (_isLoading) return; // If already loading, do not fetch again
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(Uri.parse(mBaseUrl + 'CAdminReports?page=$page'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final List<dynamic> adminReports = responseData['adminReports']['data'];

      setState(() {
        if (page == 1) {
          _adminReports = adminReports;
        } else {
          _adminReports.addAll(adminReports);
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // throw Exception('Failed to load admin reports');
      print(response.statusCode);
    }
  }

  Future<void> fetchDriverReports({int page = 1}) async {
    try {
      final response = await http.get(Uri.parse(mBaseUrl + 'user/getDriverReports?page=$page')); // Replace 'your_backend_url_here' with your actual backend URL

      if (response.statusCode == 200) {
        // If the request is successful (status code 200), parse the response body
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> _driverReports = responseData['driverReports']['data'];

        setState(() {
          if (page == 1) {
            // If it's the first page, replace the current list with new data
            driverReports = _driverReports;
          } else {
            // If it's not the first page, append the new data to the existing list
            driverReports.addAll(_driverReports);
          }
          _isLoading = false;
        });

      } else {
        // If the request fails, print an error message
        print('Failed to load driver reports: ${response.statusCode}');
      }
    } catch (e) {
      // If an exception occurs, print the error
      print('Exception occurred: $e');
    }
  }
  // Method to load more reports when the user scrolls to the end
  Future<void> loadMoreReports() async {
    _currentPage++; // Increment the page number
    await fetchAdminReports(page: _currentPage);
    print(_currentPage);
  }

  Future<void> loadMoreDriverReports() async {
    _driverCurrentPage++; // Increment the page number
    await fetchDriverReports(page: _driverCurrentPage);
    print(_driverCurrentPage);
  }

  Future<void> _refreshReports() async {
    _currentPage = 1;
    await fetchAdminReports();
  }

  Future<void> _refreshDriverReports() async {
    _driverCurrentPage = 1;
    await fetchDriverReports();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isDriverSelected = true;
                    });
                  },
                  icon: Icon(Icons.directions_car),
                  label: Text('Driver'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isDriverSelected ? Colors.blue : Colors.grey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isDriverSelected = false;
                    });
                  },
                  icon: Icon(Icons.admin_panel_settings),
                  label: Text('Admin'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !_isDriverSelected ? Colors.blue : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          _isDriverSelected
              ? Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshDriverReports,
              child: Container(
                height: MediaQuery.of(context).size.height,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!_isLoading &&
                        scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                      // If not already loading and user has scrolled to the bottom
                      loadMoreDriverReports(); // Load more reports
                      return true;
                    }
                    return false;
                  },
                  child: ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: driverReports.length,
                    itemBuilder: (context, index) {
                      final driverImage = driverReports[index]['driver_image'];
                      final dynamic media = driverReports[index]['media'];
                      String createdAt = DateFormat('dd-MM-yyyy hh:mm:ss a').format(DateTime.parse(driverReports[index]['created_at']));
                      List<dynamic>? mediaList;
                      if (media != null && !media.endsWith('.aac')) {
                        mediaList = json.decode(media);
                      }
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    top: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green, // Use the textColor variable here
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Icon(Icons.local_shipping, size: 36, color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 50, top: 0, right: 5, bottom: 0),
                                    child: ListTile(
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${driverReports[index]['plate_no']}',
                                            style: TextStyle(fontWeight: FontWeight.bold),),
                                          FittedBox( // Use FittedBox to fit the child within available space
                                            child: Text(
                                              '${driverReports[index]['created_at']}', // Use the createdAt time here
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
                                              Text('${driverReports[index]['driver_surname']}'),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${driverReports[index]['message'] ?? ''}',
                              ),
                              SizedBox(height: 16),
                              // Display media
                              if (media != null) ...[
                                if (mediaList != null && mediaList.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: GridView.count(
                                      physics: NeverScrollableScrollPhysics(),
                                      crossAxisCount: 3,
                                      shrinkWrap: true,
                                      children: mediaList.take(2).map<Widget>((media) {
                                        if (media is String && media.endsWith('.jpg')) {
                                          // Display image
                                          String imageUrl = driverMediaURL + media;
                                          return Padding(
                                            padding: const EdgeInsets.all(2.0),
                                            child: GestureDetector(
                                              onTap: () {
                                                _showImageDialog(context, mediaList!.map<String>((media) => driverMediaURL + media).toList(), imageUrl);
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.black, // Border color
                                                    width: 0.2, // Border width
                                                  ),
                                                ),
                                                child: Image.network(
                                                  imageUrl,
                                                  width: 200,
                                                  height: 200,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          );
                                        } else if (media is String && media.endsWith('.mp4')) {
                                          // Play video
                                          return GestureDetector(
                                            onTap: () {
                                              // Play video
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => VideoPlayerScreen(videoUrl: driverMediaURL + media),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              width: 200,
                                              height: 200,
                                              color: Colors.black, // Placeholder color for video thumbnail
                                              child: Center(
                                                child: Icon(
                                                  Icons.play_circle_fill,
                                                  size: 50,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          // Handle other media types or unknown types
                                          return Container(); // Return empty container or handle accordingly
                                        }
                                      }).toList()..add(
                                        // Show +X if more than 3 media items
                                        mediaList.length > 2
                                            ? GestureDetector(
                                          onTap: () {
                                            String imageUrl = driverMediaURL + driverReports[index]['media'];
                                            _showImageDialog(
                                              context,
                                              (jsonDecode(driverReports[index]['media']) as List)
                                                  .map<String>((media) => driverMediaURL + media)
                                                  .toList(),
                                              imageUrl,
                                            );
                                          },
                                          child: Container(
                                            color: Colors.black54,
                                            width: 200,
                                            height: 200,
                                            child: Center(
                                              child: Text(
                                                '+${mediaList.length - 2}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                            : SizedBox(),
                                      ),
                                    ),
                                  ),
                                if (media.endsWith('.aac'))
                                  SizedBox(
                                    height: 50, // Provide a height constraint
                                    width: 200, // Provide a width constraint
                                    child: VoiceMessagePlayer(
                                      audioUri: '$DOMAIN_URL/public/audio/$media',
                                    ),
                                  )
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          )
              : _adminReports.isEmpty
              ? Expanded(
            child: Center(
              child: Text(
                'No Admin Reports Currently',
                style: TextStyle(fontSize: 24),
              ),
            ),
          )
              : Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshReports,
              child: Container(
                height: MediaQuery.of(context).size.height,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification scrollInfo) {
                    if (!_isLoading &&
                        scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                      // If not already loading and user has scrolled to the bottom
                      loadMoreReports(); // Load more reports
                      return true;
                    }
                    return false;
                  },
                  child: ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: _adminReports.length,
                    itemBuilder: (context, index) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage('https://t4.ftcdn.net/jpg/02/27/45/09/360_F_227450952_KQCMShHPOPebUXklULsKsROk5AvN6H1H.jpg'),
                                  ),
                                  SizedBox(width: 8), // Add some spacing between avatar and text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(5, 5, 0, 0),
                                          child: Text(
                                            'Admin',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(5, 5, 0, 0),
                                          child: Text(_adminReports[index]['created_at'], style: TextStyle(fontSize: 11,color: Colors.grey),),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(8, 15, 0, 0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_adminReports[index]['text']),
                                  ],
                                ),
                              ),
                              // Display media
                              if (_adminReports[index]['media'] != null)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GridView.count(
                                    physics: NeverScrollableScrollPhysics(),
                                    crossAxisCount: 3,
                                    shrinkWrap: true,
                                    children: (jsonDecode(_adminReports[index]['media']) as List)
                                        .take(2)
                                        .map<Widget>((media) {
                                      String imageUrl = mediaUrl + media;
                                      return Padding(
                                        padding: const EdgeInsets.all(2.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            _showImageDialog(
                                              context,
                                              (jsonDecode(_adminReports[index]['media']) as List)
                                                  .map<String>((media) => mediaUrl + media)
                                                  .toList(),
                                              imageUrl,
                                            );
                                          },
                                          child: Image.network(
                                            imageUrl,
                                            width: 200,
                                            height: 200,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    }).toList()
                                      ..addAll(
                                        // Show +X if more than 3 images
                                        ((jsonDecode(_adminReports[index]['media']) as List).length > 2)
                                            ? [
                                          GestureDetector(
                                            onTap: () {
                                              String imageUrl = mediaUrl + _adminReports[index]['media'];
                                              _showImageDialog(
                                                context,
                                                (jsonDecode(_adminReports[index]['media']) as List)
                                                    .map<String>((media) => mediaUrl + media)
                                                    .toList(),
                                                imageUrl,
                                              );
                                            },
                                            child: Container(
                                              color: Colors.black54.withOpacity(0.5),
                                              width: 200,
                                              height: 200,
                                              child: Center(
                                                child: Text(
                                                  '+${(jsonDecode(_adminReports[index]['media']) as List).length - 2}',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 24,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]
                                            : [],
                                      ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),


          ),
        ],
      ),
    );
  }
}
