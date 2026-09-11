import 'package:rikipath_mobile/features/home/domain/home_dashboard.dart';

abstract interface class HomeRepository {
  Future<HomeDashboard> loadDashboard();
}
