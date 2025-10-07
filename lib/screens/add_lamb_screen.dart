import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../services/lamb_service.dart';

class AddLambScreen extends StatefulWidget {
  const AddLambScreen({super.key});

  @override
  State<AddLambScreen> createState() => _AddLambScreenState();
}

class _AddLambScreenState extends State<AddLambScreen> {
  final _formKey = GlobalKey<FormState>();

  final tagIdController = TextEditingController();
  final motherIdController = TextEditingController();
  final fatherIdController = TextEditingController();
  final notesController = TextEditingController();
  final weaningWeightController = TextEditingController();

  String? selectedGender;
  DateTime? birthDate;
  File? selectedImage;

  // ---------- Cloudinary Upload Function ----------
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
      });
    }
  }

  Future<void> pickBirthDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
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

      String? imageUrl;
      if (selectedImage != null) {
        imageUrl = await uploadImageToCloudinary(selectedImage!);
        if (imageUrl == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Image upload failed")),
          );
          return;
        }
      }

      final success = await LambService.addLamb(
        tagId: tagIdController.text.trim(),
        gender: selectedGender!,
        dob: birthDate!,
        motherId: motherIdController.text.trim(),
        fatherId: fatherIdController.text.trim(),
        notes: notesController.text.trim(),
        imageUrl: imageUrl,
        weaningWeight: weaningWeightController.text.isNotEmpty
            ? double.tryParse(weaningWeightController.text)
            : null,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lamb added successfully')),
        );
        Navigator.pop(context, 'refresh');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add lamb')),
        );
      }
    }
  }

  // Modern rounded input decoration with visible borders
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.grey, width: 1), // visible border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.grey, width: 1), // visible border
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.brown, width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    tagIdController.dispose();
    motherIdController.dispose();
    fatherIdController.dispose();
    notesController.dispose();
    weaningWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Lamb'),
        backgroundColor: Colors.brown[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Lamb Tag ID
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: TextFormField(
                  controller: tagIdController,
                  decoration: _inputDecoration('Lamb Tag ID'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Tag ID is required' : null,
                ),
              ),

              // Gender
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: DropdownButtonFormField<String>(
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
              ),

              // Birth Date
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: Colors.grey[100],
                  title: Text(
                    birthDate != null
                        ? 'Birth Date: ${birthDate!.toLocal().toString().split(' ')[0]}'
                        : 'Select Birth Date',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: Colors.brown),
                  onTap: () => pickBirthDate(context),
                ),
              ),

              // Mother Tag ID
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: TextFormField(
                  controller: motherIdController,
                  decoration: _inputDecoration('Mother Tag ID'),
                ),
              ),

              // Father Tag ID
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: TextFormField(
                  controller: fatherIdController,
                  decoration: _inputDecoration('Father Tag ID'),
                ),
              ),

              // Weaning Weight
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: TextFormField(
                  controller: weaningWeightController,
                  decoration: _inputDecoration('Weaning Weight (kg)'),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),

              // Notes
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: TextFormField(
                  controller: notesController,
                  decoration: _inputDecoration('Notes / Health Info'),
                  maxLines: 2,
                ),
              ),

              // Image Picker
              ElevatedButton.icon(
                onPressed: pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      selectedImage!,
                      height: 150,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Submit',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
