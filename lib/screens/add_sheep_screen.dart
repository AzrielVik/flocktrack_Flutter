// File: add_sheep_screen.dart

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../services/sheep_service.dart';

class AddSheepScreen extends StatefulWidget {
  const AddSheepScreen({super.key});

  @override
  State<AddSheepScreen> createState() => _AddSheepScreenState();
}

class _AddSheepScreenState extends State<AddSheepScreen> {
  final _formKey = GlobalKey<FormState>();
  final tagIdController = TextEditingController();
  final medicalRecordsController = TextEditingController();
  final weightController = TextEditingController();
  final breedController = TextEditingController();
  final motherIdController = TextEditingController();
  final fatherIdController = TextEditingController();

  String gender = 'Male';
  String pregnant = 'No';
  String isLamb = 'No';
  File? selectedImage;
  DateTime? selectedDob;

  @override
  void dispose() {
    tagIdController.dispose();
    medicalRecordsController.dispose();
    weightController.dispose();
    breedController.dispose();
    motherIdController.dispose();
    fatherIdController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image selection not supported on Web')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final rawImage = File(result.files.single.path!);
      setState(() {
        selectedImage = rawImage;
      });
    }
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'dr8cmlcqs';
    const uploadPreset = 'unsigned_sheep';

    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = 'sheep_app'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resData = await response.stream.bytesToString();
      final jsonMap = json.decode(resData);
      return jsonMap['secure_url'];
    } else {
      print("Cloudinary upload failed: ${response.statusCode}");
      return null;
    }
  }

  Future<void> pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDob ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        selectedDob = picked;
      });
    }
  }

  void submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (tagIdController.text.trim().isEmpty ||
          gender.isEmpty ||
          (isLamb == 'No' && selectedDob == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please fill all required fields: Tag ID, Gender, and DOB")),
        );
        return;
      }

      if (gender == 'Male' && pregnant == 'Yes') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("A male sheep can't be pregnant.")),
        );
        return;
      }

      String? imageUrl;
      if (selectedImage != null) {
        imageUrl = await uploadImageToCloudinary(selectedImage!);
        if (imageUrl == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to upload image to Cloudinary")),
          );
          return;
        }
      }

      final success = await SheepService.addSheep(
        tagId: tagIdController.text.trim(),
        gender: gender.toLowerCase(),
        isPregnant: gender.toLowerCase() == 'female' ? (pregnant == 'Yes') : false,
        imageUrl: imageUrl,
        medicalRecords: medicalRecordsController.text.trim(),
        dob: selectedDob?.toIso8601String().split('T').first ?? '',
        weight: weightController.text.trim().isNotEmpty
            ? double.tryParse(weightController.text.trim())
            : null,
        breed: breedController.text.trim(),
        motherId:
            motherIdController.text.trim().isNotEmpty ? motherIdController.text.trim() : null,
        fatherId:
            fatherIdController.text.trim().isNotEmpty ? fatherIdController.text.trim() : null,
        isLamb: isLamb == 'Yes',
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sheep added successfully')),
        );
        Navigator.pop(context, 'refresh');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add sheep')),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add New Sheep',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: tagIdController,
                decoration: _inputDecoration('Tag ID'),
                validator: (value) => value!.isEmpty ? 'Tag ID is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: _inputDecoration('Gender'),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (value) {
                  setState(() {
                    gender = value!;
                    if (gender == 'Male') pregnant = 'No';
                  });
                },
              ),
              const SizedBox(height: 12),
              if (gender == 'Female')
                DropdownButtonFormField<String>(
                  value: pregnant,
                  decoration: _inputDecoration('Pregnant'),
                  items: const [
                    DropdownMenuItem(value: 'No', child: Text('No')),
                    DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                  ],
                  onChanged: (value) => setState(() => pregnant = value!),
                ),
              if (gender == 'Female') const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: isLamb,
                decoration: _inputDecoration('Is this a lamb?'),
                items: const [
                  DropdownMenuItem(value: 'No', child: Text('No')),
                  DropdownMenuItem(value: 'Yes', child: Text('Yes')),
                ],
                onChanged: (value) {
                  setState(() {
                    isLamb = value!;
                    if (isLamb == 'Yes') selectedDob = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: medicalRecordsController,
                decoration: _inputDecoration('Medical Records'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: weightController,
                decoration: _inputDecoration('Weight (kg)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: breedController,
                decoration: _inputDecoration('Breed'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: motherIdController,
                decoration: _inputDecoration('Mother Tag ID'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: fatherIdController,
                decoration: _inputDecoration('Father Tag ID'),
              ),
              const SizedBox(height: 16),
              if (isLamb == 'No')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Date of Birth",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      icon: const Icon(Icons.calendar_today, color: Colors.blue),
                      label: Text(
                        selectedDob != null
                            ? DateFormat('yyyy-MM-dd').format(selectedDob!)
                            : 'Select DOB',
                        style: const TextStyle(color: Colors.blue),
                      ),
                      onPressed: pickDob,
                    ),
                  ],
                ),
              const SizedBox(height: 10),
              if (!kIsWeb)
                ElevatedButton.icon(
                  onPressed: pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Select Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              if (!kIsWeb && selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      selectedImage!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              if (kIsWeb)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Image selection not supported on Web',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700], // ✅ Green button
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
