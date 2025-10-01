import 'package:health/health.dart';

class GoogleFitService {
  static final GoogleFitService instance = GoogleFitService._();
  GoogleFitService._();

  final Health _health = Health();
  bool _authorized = false;

  Future<bool> authorize() async {
    final types = [HealthDataType.DIETARY_ENERGY_CONSUMED];

    try {
      _authorized = await _health.requestAuthorization(types);
      return _authorized;
    } catch (e) {
      print('Error autorizando Google Fit: $e');
      return false;
    }
  }

  Future<bool> writeDailyNutrition({required double calories}) async {
    if (!_authorized) {
      final authorized = await authorize();
      if (!authorized) return false;
    }

    final now = DateTime.now();

    try {
      await _health.writeHealthData(
        value: calories,
        type: HealthDataType.DIETARY_ENERGY_CONSUMED,
        startTime: now,
        endTime: now,
      );

      return true;
    } catch (e) {
      print('Error escribiendo a Google Fit: $e');
      return false;
    }
  }
}
