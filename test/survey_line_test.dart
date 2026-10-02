import 'package:flutter_test/flutter_test.dart';
import 'package:pickquet/model.dart';
import 'package:pickquet/piquet_journal_screen/survey_line.dart';

MeasurementModel leg(String from, String to, num distance, num compass,
        [num angle = 0]) =>
    MeasurementModel(
        from: from,
        to: to,
        distance: distance,
        compass: compass,
        angle: angle);

void main() {
  test('lays out stations by azimuth and clino', () {
    final line = SurveyLine.fromMeasurements([
      leg('0', '1', 10, 0),
      leg('1', '2', 10, 90),
      leg('2', '3', 10, 0, -90),
    ]);
    final s = line.stations;
    expect(s['0']!.x, closeTo(0, 1e-9));
    expect(s['1']!.y, closeTo(10, 1e-9));
    expect(s['2']!.x, closeTo(10, 1e-9));
    expect(s['2']!.y, closeTo(10, 1e-9));
    expect(s['3']!.z, closeTo(-10, 1e-9));
    expect(s['3']!.x, closeTo(10, 1e-9));
    expect(line.totalLength, closeTo(30, 1e-9));
    expect(line.entrance, '0');
    expect(line.components, 1);
  });

  test('handles backward legs, splays and disconnected parts', () {
    final line = SurveyLine.fromMeasurements([
      leg('0', '1', 10, 0),
      leg('2', '1', 5, 270), // 2 is 5 m east of 1
      leg('1', '-', 3, 180),
      leg('a', 'b', 1, 0),
    ]);
    expect(line.stations['2']!.x, closeTo(5, 1e-9));
    expect(line.stations['2']!.y, closeTo(10, 1e-9));
    expect(line.stations.containsKey('-'), isFalse);
    expect(line.splays.single.$2.y, closeTo(7, 1e-9));
    expect(line.legs.length, 3);
    expect(line.components, 2);
  });
}
