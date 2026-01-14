import 'package:asnan_hub/models/case.dart';
import 'package:asnan_hub/models/students.dart';
import 'package:asnan_hub/services/auth_serrvice.dart';
import 'package:asnan_hub/widgets/case_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DoctorMyCases extends StatefulWidget {
  const DoctorMyCases({super.key});

  @override
  State<DoctorMyCases> createState() => _DoctorMyCasesState();
}

class _DoctorMyCasesState extends State<DoctorMyCases> {
  StudentUser? user;
  final AuthService authService = AuthService();
  bool loading = false;
  List<Case> doctorCases = [];

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => loading = true);
    await _fetchUser();
    await _fetchDoctorCases();
    if (mounted) setState(() => loading = false);
  }

  Future<void> _fetchUser() async {
    try {
      user = await authService.getStudentProfile();
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  Future<void> _fetchDoctorCases() async {
    if (user == null) return;

    try {
      // Query: Give me cases where doctorId is ME and state is (booked OR completed)
      final snapshot = await FirebaseFirestore.instance
          .collection('cases')
          .where('doctorId', isEqualTo: user!.uid)
          .where('state', whereIn: [CaseState.booked.name, CaseState.completed.name])
          .get();

      // Convert documents to Case objects
      doctorCases = snapshot.docs
          .map((doc) {
            try {
              return Case.fromFirestore(doc);
            } catch (e) {
              print('Error parsing case: $e');
              return null;
            }
          })
          .whereType<Case>() // Remove nulls
          .toList();

      // Sort by date manually (newest first) to avoid Firestore index errors
      doctorCases.sort((a, b) => b.date.compareTo(a.date));

    } catch (e) {
      print('Error fetching doctor cases: $e');
    }
  }

  // Optional: Function to mark a booked case as completed
  Future<void> _markAsCompleted(Case caseItem) async {
    if (caseItem.documentId == null) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Complete Case"),
        content: const Text("Have you finished treating this patient?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Yes")),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(caseItem.documentId)
          .update({'state': CaseState.completed.name});
      
      // Update local counter for the student (optional but good practice)
      // You might want to increment 'casesCompleted' in the students collection here too

      _fetchDoctorCases(); // Refresh list
      if(mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (doctorCases.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My History')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No active or past cases found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My History')),
      body: RefreshIndicator(
        onRefresh: _initData,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: doctorCases.length,
          itemBuilder: (context, index) {
            final caseItem = doctorCases[index];
            
            // We wrap the card in a column to add a "Mark Complete" button
            // only if the case is currently BOOKED
            return Column(
              children: [
                CaseCard(caseItem: caseItem),
                
                // Add "Complete" button only for Booked cases
                if (caseItem.state == CaseState.booked)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Mark as Completed"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _markAsCompleted(caseItem),
                      ),
                    ),
                  ),
                const SizedBox(height: 10), // Spacing
              ],
            );
          },
        ),
      ),
    );
  }
}