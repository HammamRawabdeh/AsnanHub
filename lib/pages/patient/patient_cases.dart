import 'package:asnan_hub/extensions/snackbar_extension.dart';
import 'package:asnan_hub/models/case.dart';
import 'package:asnan_hub/models/user.dart';
import 'package:asnan_hub/pages/patient/patient_edit_case.dart';
import 'package:asnan_hub/services/auth_serrvice.dart';
import 'package:asnan_hub/widgets/case_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MyCases extends StatefulWidget {
  const MyCases({super.key});

  @override
  State<MyCases> createState() => _MyCasesState();
}

class _MyCasesState extends State<MyCases> {
  UserModel? user;
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
      user = await authService.getUserProfile();
      print("user is ${user?.name ?? 'null'}");
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  Future<void> _fetchCases() async {
    if (user == null) return;

    try {
      QuerySnapshot snapshot;
      try {
        // Try with orderBy first
        snapshot = await FirebaseFirestore.instance
            .collection('cases')
            .where('patientId', isEqualTo: user!.uid)
            .orderBy('createdAt', descending: true)
            .get();

            
      } catch (e) {
        // If orderBy fails (no index), fetch without ordering
        print('OrderBy failed, fetching without order: $e');
        snapshot = await FirebaseFirestore.instance
            .collection('cases')
            .where('patientId', isEqualTo: user!.uid)
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

  Future<void> _deleteCase(Case caseItem) async {
    if (caseItem.documentId == null) {
      if (mounted) {
        context.showErrorSnackBar(
          'Cannot delete: Case ID not found',
          Colors.red,
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Case'),
        content: const Text(
          'Are you sure you want to cancel this case? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(caseItem.documentId)
          .delete();

      if (!mounted) return;

      context.showErrorSnackBar('Case cancelled successfully', Colors.green);

      // Refresh the list
      await _fetchCases();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      context.showErrorSnackBar(
        'Error cancelling case: ${e.toString()}',
        Colors.red,
      );
    }
  }

  void _editCase(Case caseItem) {
    if (caseItem.documentId == null) {
      context.showErrorSnackBar('Cannot edit: Case ID not found', Colors.red);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditCasePage(caseId: caseItem.documentId!, existingCase: caseItem),
      ),
    ).then((_) async {
      // Refresh cases after editing
      await _fetchCases();
      if (mounted) {
        setState(() {});
      }
    });
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
    //if the cases are empty
    if (patientCases.isEmpty) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await _fetchCases();
            setState(() {});
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 300),
              Center(
                child: Text('No cases found', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      );
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
              onEdit: caseItem.state == CaseState.pending
                  ? () => _editCase(caseItem)
                  : null,
              onDelete: () => _deleteCase(caseItem),
            );
          },
        ),
      ),
    );
  }
}
