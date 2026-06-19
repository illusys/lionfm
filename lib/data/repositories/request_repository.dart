import '../models/request_model.dart';

abstract class RequestRepository {
  Future<void> submitRequest(RequestModel request);
  Future<List<RequestModel>> getRecentRequests();
}

class MockRequestRepository implements RequestRepository {
  final List<RequestModel> _requests = [];

  @override
  Future<void> submitRequest(RequestModel request) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _requests.add(request);
  }

  @override
  Future<List<RequestModel>> getRecentRequests() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.unmodifiable(_requests);
  }
}
