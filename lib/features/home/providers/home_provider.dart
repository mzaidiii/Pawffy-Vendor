import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/home_service.dart';

final homeServiceProvider = Provider<HomeService>((ref) {
  return HomeService();
});
