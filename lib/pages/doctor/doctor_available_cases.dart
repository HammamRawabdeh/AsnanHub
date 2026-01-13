import 'package:asnan_hub/models/case.dart';
import 'package:asnan_hub/models/students.dart';
import 'package:asnan_hub/services/auth_serrvice.dart';
import 'package:asnan_hub/widgets/case_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorAvailableCases extends StatefulWidget {
  const DoctorAvailableCases({super.key});

  @override
  State<DoctorAvailableCases> createState() => _DoctorAvailableCasesState();
}

class _DoctorAvailableCasesState extends State<DoctorAvailableCases> {
  StudentUser? user;
  var authService = AuthService();
  bool loading = false;
  List<Case> patientCases = []; // ✅ initialize empty

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => loading = true);

    await _fetchUser();
    await _fetchCases();

    if (!mounted) return;
    setState(() => loading = false);
  }

  Future<void> _fetchUser() async {
    try {
      user = await authService.getStudentProfile();
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  Future<void> _fetchCases() async {
    if (user == null) return;

    try {
      QuerySnapshot snapshot;
      try {
        // Fetch all pending cases (available for booking)
        snapshot = await FirebaseFirestore.instance
            .collection('cases')
            .where('state', isEqualTo: CaseState.pending.name)
            .orderBy('createdAt', descending: true)
            .get();
            
        print("fetched with order ${snapshot.docs.length} cases");
      } catch (e) {
        // If orderBy fails (no index), fetch without ordering
        print('OrderBy failed, fetching without order: $e');
        snapshot = await FirebaseFirestore.instance
            .collection('cases')
            .where('state', isEqualTo: CaseState.pending.name)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        print('No cases found for user: ${user!.uid}');
        patientCases = [];
        return;
      }

      // Parse cases with error handling
      patientCases = snapshot.docs
          .map((doc) {
            try {
              return Case.fromFirestore(doc);
            } catch (e) {
              print('Error parsing case document ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Case>() // Filter out null values
          .toList();

      print('Successfully loaded ${patientCases.length} cases');
    } catch (e) {
      print('Error fetching cases: $e');
      patientCases = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'User profile not found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Please make sure you have completed your profile',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    // what will happen when doctor click on book button
    Future<void> _bookCase(Case caseItem) async {
      FirebaseFirestore.instance.collection('cases').doc(caseItem.documentId).update({
        'state': CaseState.booked.toString(),
        'doctorId': user!.uid,
      });
    }

    if (patientCases.isEmpty) {
      return const Scaffold(body: Center(child: Text('No cases found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Cases')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _fetchCases();
          setState(() {});
        },
        child: ListView.builder(
          itemCount: patientCases.length,
          itemBuilder: (context, index) {
            final caseItem = patientCases[index];
            return CaseCard(
              caseItem: caseItem,
              onBook: () => _bookCase(caseItem),
            );
          },
        ),
      ),
    );
  }
}
