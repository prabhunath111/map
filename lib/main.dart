import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:icon_shadow/icon_shadow.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'button.dart';
import 'package:google_map_polyline/google_map_polyline.dart';
import 'package:permission/permission.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoder/geocoder.dart';

import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';

GoogleMapsPlaces _places =
    GoogleMapsPlaces(apiKey: 'AIzaSyCQKKiOGablkNeAoIGYTzEj-muQnhNhy1c');

void main() => runApp(MaterialApp(
      home: MapsDemo(),
    ));

class MapsDemo extends StatefulWidget {
  MapsDemo() : super();

  final String title = "Map";

  @override
  MapsDemoState createState() => MapsDemoState();
}

TextEditingController _textEditingController = TextEditingController();

class MapsDemoState extends State<MapsDemo> {
  CameraPosition _positionSearchCamera;
  Coordinates _positionSearch;
  String searchAddr;

  var placeDescription;

  BitmapDescriptor customIcon;
  Set<Marker> _markers = {};
  Set<Polyline> polyline = {};
  bool mapToggle = false;
  var currentLocation;
  var currentLatitude;
  var currentLongitude;
  GoogleMapController mapController;

//  GoogleMapController _controller;
  List<LatLng> routeCoords;
  GoogleMapPolyline _googleMapPolyline =
      new GoogleMapPolyline(apiKey: "AIzaSyCQKKiOGablkNeAoIGYTzEj-muQnhNhy1c");

  Future getsomePoints() async {
    print('getsomePoints');
    var permissions =
        await Permission.getPermissionsStatus([PermissionName.Location]);
    if (permissions[0].permissionStatus == PermissionStatus.notAgain) {
      var askpermissions =
          await Permission.requestPermissions([PermissionName.Location]);
    } else {
      routeCoords = await _googleMapPolyline.getCoordinatesWithLocation(
          origin: LatLng(22.5735, 88.4331),
          destination: LatLng(22.6420, 88.4312),
          mode: RouteMode.driving);
      print('routeCoords $routeCoords');
    }
  }

  Future getaddressPoints() async {
    print('getaddress');
    routeCoords = await _googleMapPolyline.getPolylineCoordinatesWithAddress(
        origin:
            'EC-146 (Near City Center I, Sector 1, Bidhannagar, Kolkata, West Bengal 700064',
        destination:
            'DC Block, Sector 1, Bidhannagar, Kolkata, West Bengal 700064',
        mode: RouteMode.driving);
    //getActualRoute();

    print("routeCoordsa $routeCoords");
  }

  /*BitmapDescriptor customIcon;
  Set<Marker> _markers = {};*/

  @override
  void initState() {
    super.initState();
    _markers = Set.from([]);

    Geolocator().getCurrentPosition().then((currloc) {
      setState(() {
        currentLocation = currloc;
        mapToggle = true;

        LatLng _lastMapPosition =
            LatLng(currentLocation.latitude, currentLocation.longitude);
        _markers.add(
          Marker(
            markerId: MarkerId(_lastMapPosition.toString()),
            position: _lastMapPosition,
            icon: customIcon,
          ),
        );
      });
    });

    // getaddressPoints();
  }

  createMarker(context) {
    if (customIcon == null) {
      ImageConfiguration configuration = createLocalImageConfiguration(context);
      BitmapDescriptor.fromAssetImage(configuration, 'images/marker.png')
          .then((icon) {
        setState(() {
          customIcon = icon;
        });
      });
    }
  }

  Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = const LatLng(22.5726, 88.3639);
  LatLng _lastMapPosition = _center;
  MapType _currentMapType = MapType.normal;

  static final CameraPosition _position1 = CameraPosition(
//    bearing: 192.833,
    target: LatLng(22.5726, 88.3639),
    tilt: 59.440,
    zoom: 11.0,
  );

  Future<void> _goToPosition1() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(_position1));
  }

  _onMapCreated(GoogleMapController controller) {
    setState(() {
      _controller.complete(controller);
      /*  polyline.add(Polyline(
          polylineId: PolylineId('route1'),
          visible: true,
          points: routeCoords,
          width: 4,
          color: Colors.blue,
          startCap: Cap.roundCap,
          endCap: Cap.buttCap,
      ),
      );*/
    });
  }

  _onCameraMove(CameraPosition position) {
    _lastMapPosition = position.target;
  }

  _onMapTypeButtonPressed() {
    setState(() {
      _currentMapType = _currentMapType == MapType.normal
          ? MapType.satellite
          : MapType.normal;
    });
  }

  _onAddMarkerButtonPressed() {
    print('inside add marker');
    print('_lastMap $_lastMapPosition');
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(_lastMapPosition.toString()),
          position: _lastMapPosition,
          icon: customIcon,
        ),
      );
    });
  }

  Widget button(Function function, IconData icon) {
    return FloatingActionButton(
      onPressed: function,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      backgroundColor: Colors.blue,
      child: Icon(
        icon,
        size: 36.0,
      ),
    );
  }

  Future searchandNavigate(String query) async {
//    final query = "Patna";
    var addresses = await Geocoder.local.findAddressesFromQuery(query);
    var first = addresses.first;

    _positionSearch = first.coordinates;

    _positionSearchCamera =  CameraPosition(
        target: LatLng(_positionSearch.latitude, _positionSearch.longitude),
        zoom: 11.0);

    final GoogleMapController controller = await _controller.future;
    controller
        .animateCamera(CameraUpdate.newCameraPosition(_positionSearchCamera));

    LatLng _searchMapPosition =
        LatLng(_positionSearch.latitude, _positionSearch.longitude);
    print('search ${_searchMapPosition.toString()}');

//    _onAddMarkerButtonPressed();
    LatLng originPosition =
    LatLng(_searchMapPosition.latitude, _searchMapPosition.longitude);

    print('origin $originPosition');

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId(originPosition.toString()),
          position: originPosition,
          icon: customIcon,
        ),
      );
    });

  }

  @override
  Widget build(BuildContext context) {
    createMarker(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            onMapCreated: _onMapCreated,
//              polylines: polyline,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            mapType: _currentMapType,
            markers: _markers,
            onCameraMove: _onCameraMove,
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.topRight,
              child: Column(
                children: <Widget>[
                  button(_onMapTypeButtonPressed, Icons.map),
                  SizedBox(
                    height: 16.0,
                  ),
                  button(_onAddMarkerButtonPressed, Icons.add_location),
                  SizedBox(
                    height: 16.0,
                  ),
                  button(_goToPosition1, Icons.location_searching),
//Button for draw route in google map

                  RaisedButton.icon(
                      onPressed: () {},
                      icon: Icon(Icons.directions_car),
                      label: Text('path')),
                ],
              ),
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: Stack(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF148CA6), Color(0xFF063540)]),
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.cyan,
                  ),
                  height: 200.0,
                  margin:
                      EdgeInsets.only(right: 20.0, left: 20.0, bottom: 70.0),
                  child: Stack(
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFF148CA6), Color(0xFF063540)]),
                          borderRadius: BorderRadius.circular(10.0),
                          color: Colors.cyan,
                        ),
                        child: Column(
                          children: <Widget>[
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, top: 8.0),
                              child: Row(
                                children: <Widget>[
                                  IconShadowWidget(Icon(Icons.panorama_fish_eye,
                                      color: Colors.cyan, size: 16.0)),
                                  Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
//Have to change into text field
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: Container(
                                            height: 30.0,
                                            width: 250.0,
                                            child: TextField(
                                              decoration: InputDecoration(
                                                  hintText: 'Enter Origin',
                                                  focusColor: Colors.white,
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      EdgeInsets.only(
                                                          left: 15.0,
                                                          top: 15.0),
                                                /*  suffixIcon: IconButton(
                                                      icon: Icon(Icons.search),
                                                      onPressed: () {
                                                        if (searchAddr
                                                                .isNotEmpty &&
                                                            searchAddr != null)
                                                          searchandNavigate(
                                                              searchAddr);
                                                      }, //searchandNavigate,
                                                      iconSize: 30.0)*/
                                              ),
                                              onTap: _handlePressButton,
                                              onChanged: (val) {
                                                setState(() {
                                                  searchAddr = val;
                                                  controller: _textEditingController ;
                                                });
                                              },
                                            )
                                        ),
                                      )



                                      /*Text(
                                        'Brooklyn, New York, USA',
                                        style: TextStyle(color: Colors.white),
                                      ),*/
                                      )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Row(
                                children: <Widget>[
                                  IconShadowWidget(Icon(Icons.more_vert,
                                      color: Color(0xFFF3B0FC), size: 15.0)),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12.0,
                                    ),
                                    child: Container(
                                      height: 1.5,
                                      width: 230.0,
                                      color: Colors.cyan,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 8.0, right: 8.0),
                                    child: IconShadowWidget(Icon(
                                        Icons.import_export,
                                        color: Colors.white,
                                        size: 28.0)),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                              ),
                              child: Row(
                                children: <Widget>[
                                  IconShadowWidget(Icon(Icons.panorama_fish_eye,
                                      color: Color(0xFFFDDEEF), size: 16.0)),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child:
                                    /*Text(
                                      'Add destination',
                                      style: TextStyle(color: Colors.white),
                                    ), */

                                    Padding(
                                      padding:
                                      const EdgeInsets.only(right: 3.0),
                                      child: Container(
                                          height: 20.0,
                                          width: 250.0,
                                          child: TextField(
                                            decoration: InputDecoration(
                                                hintText: 'Enter Destination',
                                                focusColor: Colors.white,
                                                border: InputBorder.none,
                                                contentPadding:
                                                EdgeInsets.only(
                                                    left: 12.0,
                                                    top: 15.0),
                                               /* suffixIcon: IconButton(
                                                    icon: Icon(Icons.search),
                                                    onPressed: () {
                                                      if (searchAddr
                                                          .isNotEmpty &&
                                                          searchAddr != null)
                                                        searchandNavigate(
                                                            searchAddr);
                                                    }, //searchandNavigate,
                                                    iconSize: 30.0)*/

                                            ),
                                            onTap: _handlePressButton,
                                            onChanged: (val) {
                                              setState(() {
                                                searchAddr = val;
                                              });
                                            },
                                          )
                                      ),
                                    )
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      color: Colors.cyan,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Row(
// Select your uber and icon before text
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Icon(
                                              Icons.directions_car,
                                              color: Color(0xFF148CA6),
                                              size: 16.0,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Text(
                                              "Select your Uber",
                                              style: TextStyle(
                                                  color: Color(0xFF148CA6),
                                                  fontSize: 10.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: <Widget>[
                                            Column(
                                              children: <Widget>[
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0,
                                                          right: 8.0),
                                                  child: Container(
                                                    height: 30.0,
                                                    width: 30.0,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: DecorationImage(
                                                          image: AssetImage(
                                                              'images/car.png'),
                                                        )),
                                                  ),
                                                ),
                                                Text('\$7.80',
                                                    style: TextStyle(
                                                        fontSize: 7.0,
                                                        color:
                                                            Color(0xFF148CA6))),
                                                Text('6:15pm',
                                                    style: TextStyle(
                                                        fontSize: 6.0,
                                                        color:
                                                            Color(0xFF5F9EA0))),
                                              ],
                                            ),
                                            Column(
                                              children: <Widget>[
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0,
                                                          right: 8.0),
                                                  child: Container(
                                                    height: 30.0,
                                                    width: 30.0,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: DecorationImage(
                                                          image: AssetImage(
                                                              'images/car.png'),
                                                        )),
                                                  ),
                                                ),
                                                Text(
                                                  '\$12.30',
                                                  style: TextStyle(
                                                      fontSize: 7.0,
                                                      color: Color(0xFF148CA6)),
                                                ),
                                                Text('6:18pm',
                                                    style: TextStyle(
                                                        fontSize: 6.0,
                                                        color:
                                                            Color(0xFF5F9EA0))),
                                              ],
                                            ),
                                            Column(
                                              children: <Widget>[
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0,
                                                          right: 8.0),
                                                  child: Container(
                                                    height: 30.0,
                                                    width: 30.0,
                                                    decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        image: DecorationImage(
                                                          image: AssetImage(
                                                              'images/car.png'),
                                                        )),
                                                  ),
                                                ),
                                                Text(
                                                  '\$7.80',
                                                  style: TextStyle(
                                                      fontSize: 7.0,
                                                      color: Color(0xFF148CA6)),
                                                ),
                                                Text('6:15pm',
                                                    style: TextStyle(
                                                        fontSize: 6.0,
                                                        color:
                                                            Color(0xFF5F9EA0))),
                                              ],
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    children: <Widget>[
                                      Row(
// Select your uber and icon before text
                                        children: <Widget>[
                                          Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Icon(
                                              Icons.airline_seat_recline_normal,
                                              color: Color(0xFF148CA6),
                                              size: 16.0,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Text(
                                              "Passenger",
                                              style: TextStyle(
                                                  color: Color(0xFF148CA6),
                                                  fontSize: 10.0),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 20.0, left: 20.0),
                                        child: Row(
                                          children: <Widget>[
                                            Text(
                                              "1",
                                              style: TextStyle(
                                                  color: Color(0xFF148CA6),
                                                  fontSize: 20.0),
                                            ),
                                            Expanded(
                                              child:
                                                  new CircularPercentIndicator(
                                                radius: 55.0,
                                                lineWidth: 0.5,
                                                percent: 1.0,
                                                center: new Text(
                                                  '2',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                progressColor:
                                                    Color(0xFF148CA6),
                                              ),
                                            ),
                                            Text(
                                              "3",
                                              style: TextStyle(
                                                  color: Color(0xFF148CA6),
                                                  fontSize: 20.0),
                                            )
                                          ],
                                        ),
                                      )
                                    ],
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
              ],
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            margin: EdgeInsets.only(left: 20.0, right: 20.0),
            child: RaisedGradientButton(
              child: Text(
                'Request uberX',
                style: TextStyle(color: Colors.white),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[Colors.pinkAccent, Colors.redAccent],
              ),
              onPressed: () {
                print('button clicked');
              },
            ),
          ),
        ],
      ),
    );
  }

/*List<LatLng> _createPoints() {
    final List<LatLng> points = <LatLng>[];
    points.add(LatLng(22.6420, 88.4312));
    points.add(LatLng(22.5735, 88.4331));
*/
/*    points.add(LatLng(8.196142, 2.094979));
    points.add(LatLng(12.196142, 3.094979));
    points.add(LatLng(16.196142, 4.094979));
    points.add(LatLng(20.196142, 5.094979));*/ /*
    return points;
  }*/

/* getActualRoute() {

    polyline.add(Polyline(
      polylineId: PolylineId('route1'),
      visible: true,
      points: routeCoords,
      width: 4,
      color: Colors.blue,
      startCap: Cap.roundCap,
      endCap: Cap.buttCap,
    ),
    );

  }*/
  void onMapCreated(controller) {
    setState(() {
      mapController = controller;
    });
  }

  Future<void> _handlePressButton() async {
    // show input autocomplete with selected mode
    // then get the Prediction selected
    Prediction p = await PlacesAutocomplete.show(
      context: context,
      apiKey: 'AIzaSyCQKKiOGablkNeAoIGYTzEj-muQnhNhy1c',
//      onError: onError,
      mode: Mode.overlay,
      language: "en",
      components: [Component(Component.country, "in")],
    );

//Displaying description of prediction
     placeDescription = p.description;
    print('predict $placeDescription');
    setState(() {
      searchAddr = placeDescription;
      searchandNavigate(placeDescription);
    });
  }
}
