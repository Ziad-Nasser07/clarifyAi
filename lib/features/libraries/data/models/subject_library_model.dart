import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectLibraryModel {
  final String id;
  final String subjectName;
  final int colorValue;
  final DateTime createdAt;

  SubjectLibraryModel({
    required this.id,
    required this.subjectName,
    required this.colorValue,
    required this.createdAt,
  });

  factory SubjectLibraryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubjectLibraryModel(
      id: doc.id,
      subjectName: data['subjectName'] ?? '',
      colorValue: data['colorValue'] ?? 0xFF2196F3,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'colorValue': colorValue,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}