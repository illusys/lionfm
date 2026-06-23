import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';

abstract class RequestRepository {
  Future<void> submitRequest(RequestModel request, {String? userId});
  Future<List<RequestModel>> getRecentRequests();
  Stream<List<RequestModel>> watchRequests({String? status});
  Future<void> updateModeration({
    required String requestId,
    required RequestStatus status,
    String? notes,
    String? assignedTo,
  });
}

class FirestoreRequestRepository implements RequestRepository {
  FirestoreRequestRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> submitRequest(RequestModel request, {String? userId}) async {
    final data = request.toFirestoreCreate(userId: userId);
    await _db.collection('requests').add(data);
  }

  @override
  Future<List<RequestModel>> getRecentRequests() async {
    final snap = await _db
        .collection('requests')
        .orderBy('submittedAt', descending: true)
        .limit(50)
        .get();
    return snap.docs.map(RequestModel.fromFirestore).toList();
  }

  @override
  Stream<List<RequestModel>> watchRequests({String? status}) {
    Query<Map<String, dynamic>> query = _db
        .collection('requests')
        .orderBy('submittedAt', descending: true)
        .limit(200);
    if (status != null) {
      query = _db
          .collection('requests')
          .where('status', isEqualTo: status)
          .orderBy('submittedAt', descending: true)
          .limit(200);
    }
    return query.snapshots().map(
          (snap) => snap.docs.map(RequestModel.fromFirestore).toList(),
        );
  }

  @override
  Future<void> updateModeration({
    required String requestId,
    required RequestStatus status,
    String? notes,
    String? assignedTo,
  }) async {
    await _db.collection('requests').doc(requestId).update({
      'status': status.name,
      if (notes != null) 'moderationNotes': notes,
      if (assignedTo != null) 'assignedTo': assignedTo,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// Kept for tests only. Production code should use FirestoreRequestRepository.
class MockRequestRepository implements RequestRepository {
  final List<RequestModel> _requests = [];

  @override
  Future<void> submitRequest(RequestModel request, {String? userId}) async {
    _requests.add(request);
  }

  @override
  Future<List<RequestModel>> getRecentRequests() async => List.unmodifiable(_requests);

  @override
  Stream<List<RequestModel>> watchRequests({String? status}) =>
      Stream.value(List.unmodifiable(_requests));

  @override
  Future<void> updateModeration({
    required String requestId,
    required RequestStatus status,
    String? notes,
    String? assignedTo,
  }) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index == -1) return;
    _requests[index] = _requests[index].copyWith(status: status);
  }
}
