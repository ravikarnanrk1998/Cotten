import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String loadsCollection = 'loads';
  static const String summariesCollection = 'summaries';
  static const String statusCollection = 'status';
  static const String statusDocId = 'current_status';
  static const String loadSentCollection = 'load_sent';
  // 🔹 LOADS (Input Data)
  static Stream<List<Map<String, dynamic>>> getLoads() {
    return _db
        .collection(loadsCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList();
        });
  }

  static Future<void> addLoad(Map<String, dynamic> load) async {
    await _db.collection(loadsCollection).add(load);
  }

  static Future<void> deleteLoad(String id) async {
    await _db.collection(loadsCollection).doc(id).delete();
  }

  // 🔹 SUMMARIES (Finalized Sent Data)
  static Stream<List<Map<String, dynamic>>> getSummaries() {
    return _db
        .collection(summariesCollection)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList();
        });
  }

  static Future<void> addSummary(Map<String, dynamic> summary) async {
    await _db.collection(summariesCollection).add({
      ...summary,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> deleteSummary(String id) async {
    await _db.collection(summariesCollection).doc(id).delete();
  }

  static Future<void> updateSummary(
    String id,
    Map<String, dynamic> data,
  ) async {
    await _db.collection(summariesCollection).doc(id).update(data);
  }

  // 🔹 LOAD SENT (Temporary History for Summary Page)
  static Stream<List<Map<String, dynamic>>> getLoadSent() {
    return _db.collection(loadSentCollection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  static Future<void> addLoadSent(Map<String, dynamic> load) async {
    await _db.collection(loadSentCollection).add({
      ...load,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  static Future<void> deleteLoadSent(String id) async {
    await _db.collection(loadSentCollection).doc(id).delete();
  }

  static Future<void> clearLoadSent() async {
    final snapshot = await _db.collection(loadSentCollection).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  // 🔹 STATUS (Dashboard Tracker)
  static Stream<Map<String, dynamic>?> getStatus() {
    return _db
        .collection(statusCollection)
        .doc(statusDocId)
        .snapshots()
        .map((doc) => doc.data());
  }

  static Future<void> updateStatus(Map<String, dynamic> status) async {
    await _db
        .collection(statusCollection)
        .doc(statusDocId)
        .set(status, SetOptions(merge: true));
  }

  static Future<void> resetStatus() async {
    await _db.collection(statusCollection).doc(statusDocId).set({
      "totalAmount": 0,
      "hybridHigh": 0,
      "hybridMedium": 0,
      "hybridLow": 0,
      "hybridTotal": 0,
      "normalHigh": 0,
      "normalMedium": 0,
      "normalLow": 0,
      "normalTotal": 0,
    });
  }
}
