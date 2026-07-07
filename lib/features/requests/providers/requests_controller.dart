import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/request_model.dart';
import '../data/services/requests_service.dart';

final requestsServiceProvider = Provider<RequestsService>((ref) {
  return RequestsService();
});

class RequestsFilterNotifier extends Notifier<String> {
  @override
  String build() => 'pending';

  void setFilter(String status) {
    state = status;
  }
}

final requestsFilterProvider =
    NotifierProvider<RequestsFilterNotifier, String>(
  RequestsFilterNotifier.new,
);

class RequestsQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) {
    state = query;
  }
}

final requestsQueryProvider =
    NotifierProvider<RequestsQueryNotifier, String>(
  RequestsQueryNotifier.new,
);

final requestsNotifierProvider =
    AsyncNotifierProvider<RequestsNotifier, List<RequestModel>>(
  RequestsNotifier.new,
);

class RequestsNotifier extends AsyncNotifier<List<RequestModel>> {
  @override
  Future<List<RequestModel>> build() async {
    final status = ref.watch(requestsFilterProvider);
    final query = ref.watch(requestsQueryProvider);
    final service = ref.read(requestsServiceProvider);
    return await service.getRequests(status: status, search: query);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final status = ref.read(requestsFilterProvider);
      final query = ref.read(requestsQueryProvider);
      final service = ref.read(requestsServiceProvider);
      final data = await service.getRequests(status: status, search: query);
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<bool> acceptRequest(String requestId) async {
    try {
      final success = await ref.read(requestsServiceProvider).acceptRequest(requestId);
      if (success) {
        ref.invalidateSelf();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId) async {
    try {
      final success = await ref.read(requestsServiceProvider).rejectRequest(requestId);
      if (success) {
        ref.invalidateSelf();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
