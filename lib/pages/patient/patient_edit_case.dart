import 'dart:async';
import 'dart:io';

import 'package:asnan_hub/extensions/snackbar_extension.dart';
import 'package:asnan_hub/models/case.dart';
import 'package:asnan_hub/widgets/camera_input.dart';
import 'package:asnan_hub/widgets/case_types_grid.dart';
import 'package:asnan_hub/widgets/date_picker_field.dart';
import 'package:asnan_hub/widgets/description_field.dart';
import 'package:asnan_hub/widgets/time_shift_selector.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class EditCasePage extends StatefulWidget {
  final String caseId;
  final Case existingCase;

  const EditCasePage({
    super.key,
    required this.caseId,
    required this.existingCase,
  });

  @override
  State<EditCasePage> createState() => _EditCasePageState();
}

class _EditCasePageState extends State<EditCasePage> {
  final _formKey = GlobalKey<FormState>();
  File? _selectedImage;
  CaseType? _selectedCaseType;
  DateTime? _selectedDate;
  TimeShift? _selectedShift;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    setState(() => _isLoading = true);
    
    _selectedCaseType = widget.existingCase.type;
    _selectedShift = widget.existingCase.shift;
    _selectedDate = widget.existingCase.date;
    _descriptionController.text = widget.existingCase.description ?? '';
    
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<String?> uploadImage(File imageFile) async {
    try {
      print('Starting image upload to Firebase Storage...');
      print('File path: ${imageFile.path}');
      
      if (!imageFile.existsSync()) {
        print('Error: File does not exist at path: ${imageFile.path}');
        return null;
      }
      
      final fileSize = await imageFile.length();
      print('File size: $fileSize bytes');
      
      if (fileSize == 0) {
        print('Error: File is empty');
        return null;
      }
      
      final fileBytes = await imageFile.readAsBytes();
      print('File bytes read: ${fileBytes.length} bytes');
      
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('cases')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      print('Uploading to Firebase Storage...');
      final uploadTask = storageRef.putData(
        fileBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
        print('Upload progress: ${progress.toStringAsFixed(2)}%');
      });
      
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('Upload timeout after 30 seconds');
          throw TimeoutException('Upload timeout', const Duration(seconds: 30));
        },
      );
      
      print('Upload completed: ${snapshot.bytesTransferred} bytes');

      String downloadUrl = await snapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Get URL timeout');
          throw TimeoutException('Get URL timeout', const Duration(seconds: 10));
        },
      );
      print('Download URL obtained: $downloadUrl');
      
      return downloadUrl;
    } catch (ex) {
      print("Image upload failed: $ex");
      return null;
    }
  }

  Future<void> _updateCase() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCaseType == null) {
      context.showErrorSnackBar('Please select a problem type', Colors.red);
      return;
    }

    if (_selectedDate == null) {
      context.showErrorSnackBar('Please select a preferred date', Colors.red);
      return;
    }

    if (_selectedShift == null) {
      context.showErrorSnackBar('Please select a preferred time', Colors.red);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          context.showErrorSnackBar('Please login first', Colors.red);
        }
        return;
      }

      print('Starting case update...');

      // Upload new image if one was selected, otherwise keep existing
      String imageUrl = widget.existingCase.imageUrl;
      if (_selectedImage != null) {
        final newImageUrl = await uploadImage(_selectedImage!);
        
        if (newImageUrl == null) {
          if (mounted) {
            context.showErrorSnackBar(
              'Failed to upload image. Please try again.',
              Colors.red,
            );
          }
          return;
        }
        imageUrl = newImageUrl;
      }

      print('Updating case in Firestore...');

      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('cases')
          .doc(widget.caseId)
          .update({
        'type': _selectedCaseType!.name,
        'shift': _selectedShift!.name,
        'imageUrl': imageUrl,
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate!),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Case updated successfully');

      if (!mounted) return;

      context.showErrorSnackBar('Case updated successfully!', Colors.green);
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      print('Error updating case: $e');
      if (!mounted) return;
      context.showErrorSnackBar('Error: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var scheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Case'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Problem Type Section
              Text(
                'Problem Type *',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 12),
              CaseTypesGrid(
                selectedType: _selectedCaseType,
                onSelected: (CaseType type) {
                  setState(() => _selectedCaseType = type);
                },
              ),
              const SizedBox(height: 24),

              // Description Section
              DescriptionField(
                controller: _descriptionController,
                label: 'Problem Description',
                hint:
                    'Explain your problem in detail... Example: I suffer from pain in the lower left molar since a week',
                helperText:
                    'The clearer the description, the more accurate the diagnosis',
                isOptional: true,
              ),
              const SizedBox(height: 24),

              // Photos Section
              Text(
                'Photos *',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedImage != null 
                    ? 'New image selected (tap to change)'
                    : 'Current image (tap to change)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              // Show existing image if no new image selected
              if (_selectedImage == null && 
                  widget.existingCase.imageUrl.isNotEmpty &&
                  widget.existingCase.imageUrl != 'placeholder_url')
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.existingCase.imageUrl,
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
                    ),
                  ),
                ),
              CameraInput(
                onPickedImage: (image) {
                  setState(() => _selectedImage = image);
                },
              ),
              const SizedBox(height: 24),

              // Preferred Date
              DatePickerField(
                selectedDate: _selectedDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                },
                label: 'Preferred Date *',
              ),
              const SizedBox(height: 24),

              // Preferred Time
              TimeShiftSelector(
                selectedShift: _selectedShift,
                onShiftSelected: (shift) {
                  setState(() => _selectedShift = shift);
                },
                label: 'Preferred Time *',
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _updateCase,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isSubmitting ? 'Updating...' : 'Update Case',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

