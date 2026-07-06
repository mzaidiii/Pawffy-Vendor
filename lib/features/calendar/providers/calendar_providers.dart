import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/models/calendar_day_model.dart';
import '../data/models/blocked_date_model.dart';
import '../data/services/calendar_service.dart';

final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }
}

final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

final calendarDayProvider =
    AsyncNotifierProvider<CalendarDayNotifier, CalendarDayModel>(
      CalendarDayNotifier.new,
    );

class CalendarDayNotifier extends AsyncNotifier<CalendarDayModel> {
  @override
  Future<CalendarDayModel> build() async {
    final selectedDate = ref.watch(selectedDateProvider);
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
    final service = ref.read(calendarServiceProvider);
    return await service.getCalendarDay(date: dateStr);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final selectedDate = ref.read(selectedDateProvider);
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final service = ref.read(calendarServiceProvider);
      final data = await service.getCalendarDay(date: dateStr);
      state = AsyncData(data);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final blockedDatesProvider =
    AsyncNotifierProvider<BlockedDatesNotifier, List<BlockedDateModel>>(
      BlockedDatesNotifier.new,
    );

class BlockedDatesNotifier extends AsyncNotifier<List<BlockedDateModel>> {
  @override
  Future<List<BlockedDateModel>> build() async {
    final service = ref.read(calendarServiceProvider);
    return await service.getBlockedDates();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final service = ref.read(calendarServiceProvider);
      final list = await service.getBlockedDates();
      state = AsyncData(list);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<bool> addBlockedDate(String date, String reason) async {
    final service = ref.read(calendarServiceProvider);
    try {
      final newBlocked = await service.addBlockedDate(date, reason);
      state = AsyncData([...state.value ?? [], newBlocked]);
      ref.invalidate(calendarDayProvider);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeBlockedDate(String id) async {
    final service = ref.read(calendarServiceProvider);
    try {
      await service.removeBlockedDate(id);
      state = AsyncData(
        state.value?.where((item) => item.id != id).toList() ?? [],
      );
      ref.invalidate(calendarDayProvider);
      return true;
    } catch (e) {
      return false;
    }
  }
}
