import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart' as loc;
import 'package:object_detection/modules/volunteer/data/firebase/user_firebase.dart';
import 'package:object_detection/modules/volunteer/ui/volunteer_request/cubit/cubit.dart';
import 'package:object_detection/shared/constants.dart';
import '../../../../models/UserLocation.dart';
import '../../../../models/Request.dart';
import '../../../../models/User.dart';

class LocationApi {
  static loc.Geolocator _geolocator = loc.Geolocator();

  static late VolunteerRequestCubit myCubit;

  static Future<void> sendRealTimeLocationUpdates(
      VolunteerRequestCubit cubit) async {
    if (await _checkServiceAvailability() && await _checkLocationPermission()) {
      myCubit = cubit;
      loc.Geolocator.getPositionStream(
        desiredAccuracy: loc.LocationAccuracy.best,
        intervalDuration: Duration(minutes: 3),
      ).listen((loc.Position position) async {
        await _updateUserLocation(position.latitude, position.longitude);
      });
    }
    myCubit = cubit;
  }

  static Future<bool> _checkServiceAvailability() async {
    bool serviceEnabled = await loc.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Handle the failure to enable location service
    }
    return serviceEnabled;
  }

  static Future<bool> _checkLocationPermission() async {
    loc.LocationPermission permission =
    await loc.Geolocator.checkPermission();
    if (permission == loc.LocationPermission.denied) {
      permission = await loc.Geolocator.requestPermission();
      if (permission != loc.LocationPermission.whileInUse &&
          permission != loc.LocationPermission.always) {
        // Handle the failure to grant location permission
      }
    }
    return permission == loc.LocationPermission.whileInUse ||
        permission == loc.LocationPermission.always;
  }

  static Request? request;

  static void _updateRequestObj(double latitude, double longitude) async {
    UserModel userModel = await getCurrentUser();
    if (request == null) {
      request = Request(
        blindData: userModel,
        blindLocation: UserLocation(latitude, longitude),
        date: Timestamp.now(),
      );
    } else {
      request!.blindLocation.latitude = latitude;
      request!.blindLocation.longitude = longitude;
    }
  }

  static Future<void> _updateUserLocation(
      double latitude, double longitude) async {
    _updateRequestObj(latitude, longitude);
    try {
      await UserFirebase.setRequestForAllVolunteers(request!, myCubit);
      //requestState = RequestSucceeded();
    } catch (e) {
      print(e.toString());
    }
  }
}
