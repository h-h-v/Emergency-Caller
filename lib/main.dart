import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class Person {
  final String name;
  final String phoneNumber;
  final String address;

  Person({required this.name, required this.phoneNumber, required this.address});
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Call App',
      theme: ThemeData.dark(),
      home: SecondPage(),
    );
  }
}

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final List<Person> peopleList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Call App'),
      ),
      body: ListView.builder(
        itemCount: peopleList.length,
        itemBuilder: (context, index) {
          return Column(
            children: [
              ListTile(
                title: Text(
                  peopleList[index].name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone Number: ${peopleList[index].phoneNumber}',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Address: ${peopleList[index].address}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      peopleList.removeAt(index);
                    });
                  },
                ),
              ),
              Divider(
                height: 1,
                color: Colors.grey,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show the dialog window
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String name = '';
              String phoneNumber = '';
              String address = '';

              return AlertDialog(
                title: Text('Add Person'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) => name = value,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      onChanged: (value) => phoneNumber = value,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                    ),
                    TextField(
                      onChanged: (value) => address = value,
                      decoration: InputDecoration(labelText: 'Address'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      // Close the dialog window
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Add person details to the list
                      setState(() {
                        peopleList.add(Person(name: name, phoneNumber: phoneNumber, address: address));
                      });

                      // Convert the address to coordinates
                      List<Location> locations = await locationFromAddress(address);
                      if (locations.isNotEmpty) {
                        Location location = locations.first;
                        print('Latitude: ${location.latitude}, Longitude: ${location.longitude}');
                      } else {
                        print('Unable to determine coordinates for $address');
                      }

                      // Close the dialog window
                      Navigator.of(context).pop();
                    },
                    child: Text('Save'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.lightBlue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FloatingActionButton(
          onPressed: () async {
            // Get the current location
            Position currentPosition = await Geolocator.getCurrentPosition();

            // Initialize variables to store the minimum distance and corresponding person's index
            double minDistance = double.infinity;
            int minDistanceIndex = -1;

            // Iterate through each person in the list and calculate the distance
            for (int i = 0; i < peopleList.length; i++) {
              // Convert the address to coordinates
              List<Location> locations = await locationFromAddress(peopleList[i].address);
              if (locations.isNotEmpty) {
                Location location = locations.first;
                double distance = await Geolocator.distanceBetween(
                  currentPosition.latitude,
                  currentPosition.longitude,
                  location.latitude,
                  location.longitude,
                );
                // Check if this distance is the smallest so far
                if (distance < minDistance) {
                  minDistance = distance;
                  minDistanceIndex = i;
                }
              } else {
                print('Unable to determine coordinates for ${peopleList[i].name}');
              }
            }

            // Check if a person with a valid address was found
            if (minDistanceIndex != -1) {
              // Get the phone number of the person with the nearest address
              String phoneNumber = peopleList[minDistanceIndex].phoneNumber;

              // Check if the phone number is not empty
              if (phoneNumber.isNotEmpty) {
                // Make a phone call to the nearest person
                _makePhoneCall(phoneNumber);
              } else {
                print('Phone number is empty for ${peopleList[minDistanceIndex].name}');
              }
            } else {
              print('No valid address found in the list');
            }
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone, color: Colors.white),
              SizedBox(height: 4),
              Text('EMERGENCY', style: TextStyle(color: Colors.white)),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      ),
    );
  }

  // Method to make a phone call
  void _makePhoneCall(String phoneNumber) async {
    String telephoneNumber = '+2347012345678';
    String telephoneUrl = "tel:$telephoneNumber";
    if (await canLaunch(telephoneUrl)) {
      await launch(telephoneUrl);
    } else {
      throw "Error occured trying to call that number.";
    }
  }
}
