import 'package:delivery/driver/driver_dashboard.dart';
import 'package:delivery/model/review.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:delivery/model/order.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverMap extends StatefulWidget {
  final Order orderInformation;
  final MapController controller;

  const DriverMap({
    Key? key,
    required this.orderInformation,
    required this.controller,
  }) : super(key: key);

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  DatabaseReference ref = FirebaseDatabase.instance.ref("order");
  DatabaseReference proposalRef = FirebaseDatabase.instance.ref("proposal");
  bool accepted = false;
  Color containerColor = Colors.blue;
  User? user = FirebaseAuth.instance.currentUser;
  String? customerContact;

  @override
  void initState() {
    super.initState();
    getCustomerContact(widget.orderInformation.uid).then((onValue) {
      setState(() {
        customerContact = onValue['contactNumber'];
      });
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.controller.addMarker(
        GeoPoint(
          latitude: double.parse(widget.orderInformation.startingGeoPoint['latitude'].toString()),
          longitude: double.parse(widget.orderInformation.startingGeoPoint['longitude'].toString()),
        ),
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.person_pin_circle,
            color: Colors.redAccent,
            size: 48,
          ),
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.controller.addMarker(
        GeoPoint(
          latitude: double.parse(widget.orderInformation.endingGeoPoint['latitude'].toString()),
          longitude: double.parse(widget.orderInformation.endingGeoPoint['longitude'].toString()),
        ),
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.person_pin_circle,
            color: Colors.blueAccent,
            size: 48,
          ),
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.controller.drawRoad(
        GeoPoint(
          latitude: double.parse(widget.orderInformation.startingGeoPoint['latitude'].toString()),
          longitude: double.parse(widget.orderInformation.startingGeoPoint['longitude'].toString()),
        ),
        GeoPoint(
          latitude: double.parse(widget.orderInformation.endingGeoPoint['latitude'].toString()),
          longitude: double.parse(widget.orderInformation.endingGeoPoint['longitude'].toString()),
        ),
        roadType: RoadType.bike,
        roadOption: const RoadOption(
          roadColor: Colors.blue,
          roadWidth: 10,
          zoomInto: true,
        ),
      );
    });

    if (widget.orderInformation.status == 'ACCEPTED') {
      containerColor = Color.fromARGB(255, 22, 198, 113);
    }
    print(widget.orderInformation.noteToRider);
  }

  Future getCustomerContact(String uid) async {
    final ref = FirebaseDatabase.instance.ref();
    final snapshot = await ref.child("user/$uid").get();
    return snapshot.value;
  }

  Future insertReview(Review review) async {
    DatabaseReference reviewRef = FirebaseDatabase.instance.ref("review").push();
    int counter = 0;
    List driverReviewList = [];
    await reviewRef.set(review.toJson()).then((value) async {
      print(reviewRef.key);
      DatabaseReference newReviewRef = FirebaseDatabase.instance.ref("review");
      final reviewSnapshot = await newReviewRef.get();
      Map<dynamic, dynamic> reviews = reviewSnapshot.value as Map<dynamic, dynamic>;

      reviews.forEach((key, value) {
        if (value['driverId'] == review.driverId) {
          driverReviewList.add(value['rating']);
          counter++;
        }
      });
      int totalRating = driverReviewList.reduce((value, element) => value + element);

      double calculatedRating = totalRating / counter;
      calculatedRating = double.parse(calculatedRating.toStringAsFixed(2));

      DatabaseReference driver = FirebaseDatabase.instance.ref("user/${review.customerId}");
      driver.update({'driverRating': calculatedRating});
    }).catchError((onError) => {print(onError)});
  }

  void _acceptOrder() async {
    await ref.update({
      '${widget.orderInformation.key}/status': 'ACCEPTED',
      '${widget.orderInformation.key}/driverId': user?.uid,
    });
    setState(() {
      accepted = true;
      containerColor = Color.fromARGB(255, 22, 198, 113); // Change container color to light blue
    });
  }

  void _completeOrder() async {
    await ref.update({
      '${widget.orderInformation.key}/status': 'COMPLETED',
    });

    setState(() {
      containerColor = Colors.lightBlue; // Change container color to light blue
    });
  }

  void _cancelOrder() async {
    await ref.update({
      '${widget.orderInformation.key}/status': 'CANCELED',
    });

    DataSnapshot snapshot = await proposalRef.get();
    if (snapshot.exists) {
      Map<dynamic, dynamic> proposals = snapshot.value as Map<dynamic, dynamic>;

      // Iterate through the proposals to find the matching orderId
      proposals.forEach((key, value) {
        // Assuming 'orderId' is a field in your proposal records
        if (value['orderId'] == widget.orderInformation.key) {
          // Remove the item if orderId matches
          proposalRef.child(key).remove().then((_) {
            print("Proposal with orderId ${widget.orderInformation.key} removed successfully");
          }).catchError((error) {
            print("Failed to remove proposal: $error");
          });
        }
      });
    } else {
      print("No proposals found.");
    }

    setState(() {
      containerColor = Colors.lightBlue; // Change container color to light blue
    });
  }

  String truncateWithEllipsis(int maxLength, String text) {
    return (text.length > maxLength) ? '${text.substring(0, maxLength)}...' : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          OSMFlutter(
            controller: widget.controller,
            osmOption: OSMOption(
              zoomOption: const ZoomOption(
                initZoom: 18,
                minZoomLevel: 3,
                maxZoomLevel: 19,
                stepZoom: 1.0,
              ),
              showZoomController: true,
              userLocationMarker: UserLocationMaker(
                personMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.location_history_rounded,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
                directionArrowMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.double_arrow,
                    size: 48,
                  ),
                ),
              ),
              roadConfiguration: const RoadOption(
                roadColor: Colors.white,
              ),
              markerOption: MarkerOption(
                defaultMarker: const MarkerIcon(
                  icon: Icon(
                    Icons.person_pin_circle,
                    color: Colors.blue,
                    size: 56,
                  ),
                ),
              ),
              enableRotationByGesture: false,
            ),
          ),
          //rectangular container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: accepted ? 340 : null, // Adjust height based on acceptance status
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Your content here
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        'From : ${widget.orderInformation.startingGeoPoint['location']}',
                        style: const TextStyle(color: Colors.black, fontSize: 18.0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        'To : ${widget.orderInformation.endingGeoPoint['location']}',
                        style: const TextStyle(color: Colors.black, fontSize: 18.0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Distance: ${double.parse(widget.orderInformation.distance).toStringAsFixed(3)} km',
                          style: const TextStyle(color: Colors.black, fontSize: 18.0),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final Uri phoneUri = Uri(scheme: 'tel', path: customerContact);
                            await launchUrl(phoneUri);
                          },
                          child: Container(
                            padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 5.0, bottom: 5.0),
                            decoration: BoxDecoration(
                              color: Colors.white60,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(width: 0.8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  customerContact ?? '',
                                  style: const TextStyle(color: Colors.black, fontSize: 18.0),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.call_made,
                                  size: 20.0,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Container for Distance
                        Container(
                          //width: MediaQuery.of(context).size.width * 0.4, // Adjust width as needed
                          decoration: BoxDecoration(
                            color: Colors.white60,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Net Weight:',
                                style: TextStyle(color: Colors.black, fontSize: 12.0),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  '${widget.orderInformation.netWeight}kg',
                                  style: const TextStyle(color: Colors.black, fontSize: 20.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8), // Add spacing between containers
                        // Container for Rate
                        Container(
                          //width: MediaQuery.of(context).size.width * 0.4, // Adjust width as needed
                          decoration: BoxDecoration(
                            color: Colors.white60,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Rate:',
                                style: TextStyle(color: Colors.black, fontSize: 12.0),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text(
                                  '${widget.orderInformation.rate}', // Replace 'rate' with your actual rate value
                                  style: const TextStyle(color: Colors.black, fontSize: 20.0),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8), // Add spacing between containers
                        // Container for Rate
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text('Customer Note'),
                                    content: TextFormField(
                                      initialValue: widget.orderInformation.noteToRider,
                                      readOnly: true,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: null,
                                      keyboardType: TextInputType.multiline,
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Container(
                              //width: MediaQuery.of(context).size.width * 0.4, // Adjust width as needed
                              decoration: BoxDecoration(
                                color: Colors.white60,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(width: 0.8),
                              ),
                              padding: const EdgeInsets.all(10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Note from Customer (Click to view)',
                                    style: TextStyle(color: Colors.black, fontSize: 12.0),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      truncateWithEllipsis(15,
                                          '${widget.orderInformation.noteToRider}'), // Replace 'rate' with your actual rate value
                                      style: const TextStyle(color: Colors.black, fontSize: 20.0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    if (!accepted) // Only show Accept and Close buttons if order is not accepted
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _acceptOrder,
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(15.0),
                              ),
                              child: const Text(
                                'Confirm',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _cancelOrder();
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const DriverDashboard()),
                                );
                                //Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(15.0),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (accepted) // Show Complete and Cancel buttons if order is accepted
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                int rating = 0;
                                String commentText = '';
                                _completeOrder();
                                // Navigator.pop(context);
                                // Navigator.pushReplacement(
                                //   context,
                                //   MaterialPageRoute(builder: (context) => const DriverDashboard()),
                                // );
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Rate your Customer'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('We value our riders as we value our customer. Send a review :'),
                                          // Star rating widget
                                          RatingBar.builder(
                                            initialRating: rating.toDouble(),
                                            minRating: 1,
                                            direction: Axis.horizontal,
                                            allowHalfRating: false,
                                            itemCount: 5,
                                            itemSize: 40,
                                            itemBuilder: (context, _) => const Icon(
                                              Icons.star,
                                              color: Colors.amber,
                                            ),
                                            onRatingUpdate: (value) {
                                              rating = value.toInt(); // Update the rating value
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          // Text input for comments
                                          TextFormField(
                                            onChanged: (value) {
                                              setState(() {
                                                commentText = value;
                                              });
                                              print(commentText);
                                            },
                                            decoration: const InputDecoration(
                                              hintText: 'Add your comments (optional)',
                                              border: OutlineInputBorder(),
                                            ),
                                            maxLines: null,
                                            keyboardType: TextInputType.multiline,
                                          ),
                                        ],
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          onPressed: () async {
                                            print(widget.orderInformation.uid);
                                            Review review = Review(
                                              reviewerUserType: 'Rider',
                                              driverId: user?.uid ?? 'Unknown Driver',
                                              orderId: 'Order ID here',
                                              rating: double.parse(rating?.toString() ?? '0.0'),
                                              customerId: widget.orderInformation.uid ?? 'Unknown User',
                                              customerName: widget.orderInformation.name,
                                              driverName: user?.displayName ?? "",
                                              message: commentText ?? 'No comment provided',
                                              timestamp: DateTime.now().toString(),
                                            );
                                            await insertReview(review).then((value) {
                                              Navigator.pop(context);
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(builder: (context) => const DriverDashboard()),
                                              );
                                            });
                                          },
                                          child: const Text('Submit'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(15.0),
                              ),
                              child: const Text(
                                'Complete',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          // const SizedBox(width: 10),
                          // Expanded(
                          //   child: TextButton(
                          //     onPressed: () {
                          //       // Handle cancellation logic
                          //       _cancelOrder();
                          //       Navigator.pushReplacement(
                          //         context,
                          //         MaterialPageRoute(builder: (context) => const DriverDashboard()),
                          //       );
                          //     },
                          //     style: TextButton.styleFrom(
                          //       backgroundColor: Colors.white,
                          //       padding: const EdgeInsets.all(15.0),
                          //     ),
                          //     child: const Text(
                          //       'Cancel',
                          //       style: TextStyle(
                          //         color: Colors.black,
                          //         fontWeight: FontWeight.bold,
                          //         fontSize: 20,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
