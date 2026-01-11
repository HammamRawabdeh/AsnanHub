import 'package:cloud_firestore/cloud_firestore.dart';

class Case {
  final String? documentId; // Firestore document ID for updates/deletes
  final CaseType type; // required
  final TimeShift shift;
  final String imageUrl;
  final String? description;
  final CaseState state;
  final DateTime date;

  Case({
    this.documentId,
    required this.type,
    required this.shift,
    required this.imageUrl,
    this.description,
    this.state = CaseState.pending,
    required this.date,
  });

  /// 🔥 From Firestore document
  factory Case.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      
      if (data == null) {
        throw Exception('Document data is null');
      }

      // Parse type with fallback
      CaseType caseType;
      try {
        caseType = CaseType.values.byName(data['type'] as String);
      } catch (e) {
        print('Error parsing case type: ${data['type']}, defaulting to dentalCheckup');
        caseType = CaseType.dentalCheckup;
      }

      // Parse shift with fallback
      TimeShift timeShift;
      try {
        timeShift = TimeShift.values.byName(data['shift'] as String);
      } catch (e) {
        print('Error parsing shift: ${data['shift']}, defaulting to morning');
        timeShift = TimeShift.morning;
      }

      // Parse state with fallback
      CaseState caseState = CaseState.pending;
      if (data['state'] != null) {
        try {
          caseState = CaseState.values.byName(data['state'] as String);
        } catch (e) {
          print('Error parsing state: ${data['state']}, defaulting to pending');
        }
      }

      // Parse date
      DateTime caseDate;
      if (data['date'] is Timestamp) {
        caseDate = (data['date'] as Timestamp).toDate();
      } else if (data['date'] is DateTime) {
        caseDate = data['date'] as DateTime;
      } else {
        print('Error parsing date, using current date');
        caseDate = DateTime.now();
      }

      // Get imageUrl with fallback
      final imageUrl = data['imageUrl'] as String? ?? '';

      return Case(
        documentId: doc.id,
        type: caseType,
        shift: timeShift,
        imageUrl: imageUrl,
        description: data['description'] as String?,
        state: caseState,
        date: caseDate,
      );
    } catch (e) {
      print('Error parsing Case from Firestore: $e');
      // Return a default case to prevent crash
      return Case(
        documentId: doc.id,
        type: CaseType.dentalCheckup,
        shift: TimeShift.morning,
        imageUrl: '',
        description: null,
        state: CaseState.pending,
        date: DateTime.now(),
      );
    }
  }

   @override
  String toString() {
    return '''
Case(
  type: ${type.label}, 
  shift: ${shift.name}, 
  state: ${state.name}, 
  date: ${date.day}/${date.month}/${date.year}, 
  imageUrl: ${imageUrl.isNotEmpty ? imageUrl : "No Image"}, 
  description: ${description ?? "No description"}
)
''';
  }

}


enum CaseType {
  toothExtraction,
  cavityFilling,
  rootCanal,
  scalingPolishing,
  dentalCheckup,
  fluorideTreatment,
  fissureSealant,
  cosmeticConsultation,
  emergencyPainRelief,
}
extension CaseTypeExtension on CaseType {
  String get label {
    switch (this) {
      case CaseType.toothExtraction:
        return "Tooth Extraction";
      case CaseType.cavityFilling:
        return "Cavity Filling";
      case CaseType.rootCanal:
        return "Root Canal";
      case CaseType.scalingPolishing:
        return "Scaling & Polishing";
      case CaseType.dentalCheckup:
        return "Dental Checkup";
      case CaseType.fluorideTreatment:
        return "Fluoride Treatment";
      case CaseType.fissureSealant:
        return "Fissure Sealant";
      case CaseType.cosmeticConsultation:
        return "Cosmetic Consultation";
      case CaseType.emergencyPainRelief:
        return "Emergency Pain Relief";
    }
  }
}


enum TimeShift {
  morning , //9-12
  afternoon, //12-3
  evening //3-6
}

enum CaseState {
  pending,
  booked,
  cancelled,
  timedOut,
  completed,

}