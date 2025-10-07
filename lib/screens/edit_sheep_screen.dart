import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../models/sheep.dart';
import '../services/sheep_service.dart';

class EditSheepScreen extends StatefulWidget {
  final Sheep sheep;

  const EditSheepScreen({super.key, required this.sheep});

  @override
  State<EditSheepScreen> createState() => _EditSheepScreenState();
}

class _EditSheepScreenState extends State<EditSheepScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController tagIdController;
  late TextEditingController breedController;
  late TextEditingController weightController;
  late TextEditingController medicalRecordsController;
  late TextEditingController motherIdController;
  late TextEditingController fatherIdController;

  String? selectedGender;
  DateTime? birthDate;
  bool isPregnant = false;
  File? selectedImage;
  String? existingImageUrl;
  bool isLoading = false; // <-- Loading state

  @override
  void initState() {
    super.initState();
    tagIdController = TextEditingController(text: widget.sheep.tagId);
    breedController = TextEditingController(text: widget.sheep.breed ?? '');
    weightController =
        TextEditingController(text: widget.sheep.weight?.toString() ?? '');
    medicalRecordsController =
        TextEditingController(text: widget.sheep.medicalRecords ?? '');
    motherIdController =
        TextEditingController(text: widget.sheep.motherId ?? '');
    fatherIdController =
        TextEditingController(text: widget.sheep.fatherId ?? '');

    selectedGender = widget.sheep.gender;
    birthDate = widget.sheep.dob;
    isPregnant = widget.sheep.pregnant ?? false;
    existingImageUrl = widget.sheep.imageUrl;
  }

  Future<String?> uploadImageToCloudinary(File imageFile) async {
    final cloudName = 'dr8cmlcqs';
    final uploadPreset = 'unsigned_sheep';
    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final jsonData = json.decode(resStr);
      return jsonData['secure_url'];
    } else {
      debugPrint('Cloudinary upload failed: ${response.statusCode}');
      return null;
    }
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null) {
      final rawImage = File(result.files.single.path!);
      if (!mounted) return;
      setState(() {
        selectedImage = rawImage;
        existingImageUrl = null;
      });
    }
  }

  Future<void> pickBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() => birthDate = picked);
    }
  }

  void submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (birthDate == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a birth date.")),
        );
        return;
      }

      setState(() => isLoading = true); // <-- Show loader

      String? imageUrl = existingImageUrl;

      if (selectedImage != null) {
        imageUrl = await uploadImageToCloudinary(selectedImage!);
        if (imageUrl == null) {
          if (!mounted) return;
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image upload failed")),
          );
          return;
        }
      }

      final success = await SheepService.updateSheep(
        id: widget.sheep.id,
        tagId: tagIdController.text.trim(),
        gender: selectedGender!,
        dob: birthDate!,
        breed: breedController.text.trim(),
        weight: double.tryParse(weightController.text.trim()) ?? 0.0,
        pregnant: isPregnant,
        medicalRecords: medicalRecordsController.text.trim(),
        imageUrl: imageUrl,
        motherId: motherIdController.text.trim().isEmpty
            ? null
            : motherIdController.text.trim(),
        fatherId: fatherIdController.text.trim().isEmpty
            ? null
            : fatherIdController.text.trim(),
      );

      if (!mounted) return;
      setState(() => isLoading = false); // <-- Hide loader

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sheep updated successfully')),
        );
        Navigator.pop(context, 'refresh');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update sheep')),
        );
      }
    }
  }

  @override
  void dispose() {
    tagIdController.dispose();
    breedController.dispose();
    weightController.dispose();
    medicalRecordsController.dispose();
    motherIdController.dispose();
    fatherIdController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.brown, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Sheep'),
        backgroundColor: Colors.brown[700],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: tagIdController,
                    decoration: _inputDecoration('Sheep Tag ID'),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Tag ID is required' : null,
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    decoration: _inputDecoration('Gender'),
                    value: selectedGender,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (value) => setState(() => selectedGender = value),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Gender is required' : null,
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade400, width: 1.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      birthDate != null
                          ? 'Birth Date: ${birthDate!.toLocal().toString().split(' ')[0]}'
                          : 'Select Birth Date',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Colors.brown),
                    onTap: () => pickBirthDate(context),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: breedController,
                    decoration: _inputDecoration('Breed'),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: weightController,
                    decoration: _inputDecoration('Weight (kg)'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final w = double.tryParse(value);
                        if (w == null || w < 0) {
                          return 'Enter a valid weight';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: const Text(
                      'Pregnant',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: isPregnant,
                    activeColor: Colors.brown,
                    onChanged: (val) => setState(() => isPregnant = val),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: motherIdController,
                    decoration: _inputDecoration('Mother Tag ID'),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: fatherIdController,
                    decoration: _inputDecoration('Father Tag ID'),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: medicalRecordsController,
                    decoration: _inputDecoration('Medical Records'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: const Text(
                      'Select Image',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Image.file(
                        selectedImage!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (existingImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Image.network(
                        existingImageUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Update',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
