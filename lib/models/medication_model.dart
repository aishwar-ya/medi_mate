// lib/models/medication_model.dart

class Medication {
  final int id;
  final String name;
  final String? dosage;
  final String? frequency;
  final int? stockQuantity;
  final String? nextDose;
  final String userId;
  final String? barcode;
  final List<String>? reminderTimes;
  final DateTime createdAt;

  Medication({
    required this.id,
    required this.name,
    this.reminderTimes,
    this.dosage,
    this.frequency,
    this.stockQuantity,
    this.nextDose,
    required this.userId,
    this.barcode,
    required this.createdAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) {
    List<String>? reminderTimes;

    final reminderData = json['reminder_times'];

    if (reminderData is List) {
      reminderTimes = reminderData
          .map((item) => item.toString())
          .toList();
    } else if (reminderData is String &&
        reminderData.trim().isNotEmpty) {
      reminderTimes = [reminderData.trim()];
    }

    return Medication(
      id: json['id'] as int,
      name: json['name'] as String,
      dosage: json['dosage'] as String?,
      frequency: json['frequency'] as String?,
      stockQuantity: json['stock_quantity'] as int?,
      nextDose: json['next_dose'] as String?,
      userId: json['user_id'] as String,
      barcode: json['barcode'] as String?,
      reminderTimes: reminderTimes,
      createdAt: DateTime.parse(
        json['created_at'] as String,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'stock_quantity': stockQuantity,
      'next_dose': nextDose,
      'user_id': userId,
      'barcode': barcode,
      'reminder_times': reminderTimes ?? <String>[],
      'created_at': createdAt.toIso8601String(),
    };
  }
}