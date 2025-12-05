class MeasurementModel {
  final String from;
  final String to;
  final num distance;
  final num compass;
  final num angle;
  final num left;
  final num right;
  final num top;
  final num bottom;

  MeasurementModel(
      {required this.from,
      required this.to,
      required this.distance,
      required this.compass,
      required this.angle,
      required this.left,
      required this.right,
      required this.top,
      required this.bottom});

  Map<String, dynamic> toJson() {
    return {
      'from': from,
      'to': to,
      'distance': distance,
      'compass': compass,
      'angle': angle,
      'left': left,
      'right': right,
      'top': top,
      'bottom': bottom,
    };
  }

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    return MeasurementModel(
        from: json['from'] as String,
        to: json['to'] as String,
        distance: json['distance'] as num,
        compass: json['compass'] as num,
        angle: json['angle'] as num,
        left: json['left'] as num,
        right: json['right'] as num,
        top: json['top'] as num,
        bottom: json['left'] as num);
  }
}
