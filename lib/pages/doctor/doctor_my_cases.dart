import 'package:asnan_hub/models/case.dart';
import 'package:asnan_hub/models/caseWithUser.dart';
import 'package:asnan_hub/models/students.dart';
import 'package:asnan_hub/models/user.dart';
import 'package:asnan_hub/services/auth_serrvice.dart';
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
  List<Casewithuser> doctorCases = [];

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
          .where(
            'state',
            whereIn: [CaseState.booked.name, CaseState.completed.name],
          )
          .get();

      // Convert documents to Case objects with patient info
      List<Casewithuser> cases = [];

      for (var doc in snapshot.docs) {
        try {
          Case c = Case.fromFirestore(doc);

          // Get patientId from the document data
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;
          final patientId = data['patientId'] as String?;

          if (patientId == null) {
            print('Warning: Case ${doc.id} has no patientId');
            continue;
          }

          // Fetch patient data from 'users' collection
          final patientDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(patientId)
              .get();

          if (!patientDoc.exists) {
            print('Warning: Patient $patientId not found');
            continue;
          }

          final patientData = patientDoc.data() as Map<String, dynamic>;
          final patient = UserModel.fromMap(patientData);

          var caseWithUser = Casewithuser(
            c: c,
            name: patient.name,
            phoneNumber: patient.phone,
          );
          cases.add(caseWithUser);
        } catch (e) {
          print('Error parsing case ${doc.id}: $e');
        }
      }

      // Sort by date manually (newest first)
      cases.sort((a, b) => b.c.date.compareTo(a.c.date));

      if (mounted) {
        setState(() {
          doctorCases = cases;
        });
      }
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Update case state to completed
        await FirebaseFirestore.instance
            .collection('cases')
            .doc(caseItem.documentId)
            .update({'state': CaseState.completed.name});

        // Update student's casesCompleted count
        await FirebaseFirestore.instance
            .collection('students')
            .doc(user!.uid)
            .update({'casesCompleted': FieldValue.increment(1)});

        // Refresh the list
        await _fetchDoctorCases();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Case marked as completed!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error marking case as completed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
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

            // Unified card containing patient info and case details
            final scheme = Theme.of(context).colorScheme;
            
            return Column(
              children: [
                const SizedBox(height: 12),
                
                // Single unified card for patient and case
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Patient Info Section (Top)
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              scheme.primary.withOpacity(0.1),
                              scheme.secondary.withOpacity(0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Avatar/Icon Container
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: scheme.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: scheme.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.person,
                                size: 32,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Patient Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Patient',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                          letterSpacing: 0.5,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    caseItem.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: scheme.primary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.phone_rounded,
                                          size: 16,
                                          color: scheme.secondary,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          caseItem.phoneNumber,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Divider
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey.shade200,
                      ),
                      
                      // Case Image Section
                      if (caseItem.c.imageUrl.isNotEmpty &&
                          caseItem.c.imageUrl != 'placeholder_url')
                        ClipRRect(
                          child: Image.network(
                            caseItem.c.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported, size: 50),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                          ),
                        ),
                      
                      // Case Details Section
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Type + Status
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.medical_services_rounded,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      caseItem.c.type.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                _buildStatusChip(caseItem.c.state),
                              ],
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Description
                            if (caseItem.c.description != null) ...[
                              Text(
                                caseItem.c.description!,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            
                            const Divider(),
                            const SizedBox(height: 12),
                            
                            // Date & Shift
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  _formatDate(caseItem.c.date),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 16),
                                const Icon(Icons.schedule, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  caseItem.c.shift.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Complete Button (if booked)
                      if (caseItem.c.state == CaseState.booked) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_outline, size: 22),
                                label: const Text(
                                  "Mark as Completed",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                onPressed: () => _markAsCompleted(caseItem.c),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 20), // Spacing between items
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper methods for building UI components
  Widget _buildStatusChip(CaseState state) {
    Color color;
    String text;

    switch (state) {
      case CaseState.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case CaseState.booked:
        color = Colors.blue;
        text = 'Booked';
        break;
      case CaseState.completed:
        color = Colors.green;
        text = 'Completed';
        break;
      case CaseState.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case CaseState.timedOut:
        color = Colors.grey;
        text = 'Timed Out';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
