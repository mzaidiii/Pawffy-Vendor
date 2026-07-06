import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/home_service.dart';

final homeServiceProvider = Provider<HomeService>((ref) {
  return HomeService();
});

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setIndex(int index) {
    state = index;
  }
}

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
);
