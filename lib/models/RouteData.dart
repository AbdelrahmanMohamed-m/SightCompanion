
class RouteData {
  double duration, distance;
  RouteData({
    required this.distance,
    required this.duration,
  });

  Map<String, dynamic> toMap (){
    return {
      'distance':distance,
      'duration':duration,
    };
  }
  static RouteData fromJson(Map<String, dynamic> json) {
      return RouteData(
        distance: double.parse(json['distance'].toString()),
        duration: double.parse(json['duration'].toString()),
      );

  }

}