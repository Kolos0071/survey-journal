import 'package:flutter/foundation.dart' show listEquals;

class MeasurementModel {
  final String from;
  final String to;
  final num distance;
  final num compass;
  final num angle;
  // null means the side wasn't measured at all (Therion: bare "0" / carry
  // over previous value), as opposed to an explicit [0, 0] reading.
  final List<num>? left;
  final List<num>? right;
  final List<num>? top;
  final List<num>? bottom;
  final String comment;

  MeasurementModel(
      {required this.from,
      required this.to,
      required this.distance,
      required this.compass,
      required this.angle,
      this.left,
      this.right,
      this.top,
      this.bottom,
      this.comment = ""});

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
      'comment': comment,
    };
  }

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    List<num>? parsePair(dynamic value) {
      if (value == null) return null;
      return (value as List<dynamic>).cast<num>();
    }

    return MeasurementModel(
        from: json['from'] as String,
        to: json['to'] as String,
        distance: json['distance'] as num,
        compass: json['compass'] as num,
        angle: json['angle'] as num,
        left: parsePair(json['left']),
        right: parsePair(json['right']),
        top: parsePair(json['top']),
        bottom: parsePair(json['bottom']),
        comment: json['comment'] as String? ?? "");
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MeasurementModel &&
        other.from == from &&
        other.to == to &&
        other.distance == distance &&
        other.compass == compass &&
        other.angle == angle &&
        listEquals(other.left, left) &&
        listEquals(other.right, right) &&
        listEquals(other.top, top) &&
        listEquals(other.bottom, bottom) &&
        other.comment == comment;
  }

  @override
  int get hashCode => Object.hash(
        from,
        to,
        distance,
        compass,
        angle,
        Object.hashAll(left ?? const []),
        Object.hashAll(right ?? const []),
        Object.hashAll(top ?? const []),
        Object.hashAll(bottom ?? const []),
        comment,
      );
}
