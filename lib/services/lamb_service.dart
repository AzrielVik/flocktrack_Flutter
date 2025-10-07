import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/lamb.dart';

class LambService {
  static const String baseUrl = 'https://nduwa-sheep-backend.onrender.com';

  // Fetch all lambs
  static Future<List<Lamb>> fetchAllLambs() async {
    try {
      print('🔄 Fetching all lambs from $baseUrl/lambs ...');
      final response = await http.get(Uri.parse('$baseUrl/lambs'));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          if (json['image_url'] == null && json['image'] != null) {
            json['image_url'] = '$baseUrl/uploads/${json['image']}';
          }
          return Lamb.fromJson(json);
        }).toList();
      } else {
        throw Exception('❌ Failed to load lambs. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception while fetching lambs: $e');
      rethrow;
    }
  }

  // Fetch lamb by ID
  static Future<Lamb> fetchLambById(int id) async {
    try {
      print('🔍 Fetching lamb with ID $id ...');
      final response = await http.get(Uri.parse('$baseUrl/lambs/$id'));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Lamb.fromJson(jsonData['data']);
      } else {
        throw Exception('❌ Failed to load lamb by ID. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception while fetching lamb by ID: $e');
      rethrow;
    }
  }

  // Delete lamb
  static Future<bool> deleteLamb(int id) async {
    try {
      print('🗑️ Deleting lamb with ID $id ...');
      final response = await http.delete(Uri.parse('$baseUrl/lambs/$id'));

      print('📡 Delete response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('💥 Exception while deleting lamb: $e');
      return false;
    }
  }

  // Add new lamb with optional image file upload (multipart)
  static Future<bool> addLambMultipart({
    required String tagId,
    required String gender,
    required DateTime dob,
    String? motherId,
    String? fatherId,
    required String notes,
    File? imageFile,
  }) async {
    try {
      print('📤 Uploading new lamb with image...');
      final uri = Uri.parse('$baseUrl/lambs');
      final request = http.MultipartRequest('POST', uri);

      request.fields['tag_id'] = tagId;
      request.fields['gender'] = gender;
      request.fields['dob'] = dob.toIso8601String().split('T')[0];
      if (motherId != null && motherId.isNotEmpty) request.fields['mother_id'] = motherId;
      if (fatherId != null && fatherId.isNotEmpty) request.fields['father_id'] = fatherId;
      request.fields['medical_records'] = notes;

      if (imageFile != null) {
        final imageStream = await http.MultipartFile.fromPath('image', imageFile.path);
        request.files.add(imageStream);
      }

      final response = await request.send();
      print('📡 Multipart upload response: ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      print('💥 Exception during multipart upload: $e');
      return false;
    }
  }

  // Add lamb using JSON with Cloudinary imageUrl
  static Future<bool> addLamb({
    required String tagId,
    required String gender,
    required DateTime dob,
    String? motherId,
    String? fatherId,
    required String notes,
    String? imageUrl,
    double? weaningWeight, // ✅ NEW PARAM
  }) async {
    try {
      print('➕ Adding new lamb via JSON with imageUrl...');
      final uri = Uri.parse('$baseUrl/lambs');
      final Map<String, dynamic> payload = {
        'tag_id': tagId,
        'gender': gender,
        'dob': dob.toIso8601String().split('T')[0],
        'mother_id': motherId,
        'father_id': fatherId,
        'medical_records': notes,
        'image_url': imageUrl,
        'weaning_weight': weaningWeight,
      };

      payload.removeWhere((key, value) => value == null || value == '');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      print('📡 Add lamb JSON response: ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      print('💥 Exception during add lamb JSON: $e');
      return false;
    }
  }

  // Update lamb with optional image file upload (multipart)
  static Future<bool> updateLambMultipart({
    required int id,
    required String tagId,
    required String gender,
    required DateTime dob,
    String? motherId,
    String? fatherId,
    required String notes,
    File? imageFile,
  }) async {
    try {
      print('✏️ Updating lamb with image (ID: $id) ...');
      final uri = Uri.parse('$baseUrl/lambs/$id');
      final request = http.MultipartRequest('PUT', uri);

      request.fields['tag_id'] = tagId;
      request.fields['gender'] = gender;
      request.fields['dob'] = dob.toIso8601String().split('T')[0];
      if (motherId != null && motherId.isNotEmpty) request.fields['mother_id'] = motherId;
      if (fatherId != null && fatherId.isNotEmpty) request.fields['father_id'] = fatherId;
      request.fields['medical_records'] = notes;

      if (imageFile != null) {
        final imageStream = await http.MultipartFile.fromPath('image', imageFile.path);
        request.files.add(imageStream);
      }

      final response = await request.send();
      print('📡 Multipart update response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('💥 Exception during multipart update: $e');
      return false;
    }
  }

  // Update lamb via JSON with Cloudinary image URL
  static Future<bool> updateLamb({
    required int id,
    required String tagId,
    required String gender,
    required DateTime dob,
    String? motherId,
    String? fatherId,
    String? notes,
    String? imageUrl,
    double? weaningWeight, // ✅ NEW PARAM
  }) async {
    try {
      print('✏️ Updating lamb via JSON (ID: $id) ...');

      final uri = Uri.parse('$baseUrl/lambs/$id');
      final Map<String, dynamic> payload = {
        'tag_id': tagId,
        'gender': gender,
        'dob': dob.toIso8601String().split('T')[0],
        'mother_id': motherId,
        'father_id': fatherId,
        'medical_records': notes,
        'image_url': imageUrl,
        'weaning_weight': weaningWeight,
      };

      payload.removeWhere((key, value) => value == null || value == '');

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      print('📡 JSON update response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('💥 Exception during JSON update: $e');
      return false;
    }
  }

  // Fetch lambs by parent tag ID
  static Future<List<Lamb>> getLambsByParentId(String parentTagId) async {
    try {
      print('🔄 Fetching lambs by parent tag: $parentTagId');
      final response = await http.get(Uri.parse('$baseUrl/lambs/by-parent/$parentTagId'));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) {
          if (json['image_url'] == null && json['image'] != null) {
            json['image_url'] = '$baseUrl/uploads/${json['image']}';
          }
          return Lamb.fromJson(json);
        }).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('❌ Failed to load lambs for parent $parentTagId. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception while fetching lambs by parent ID: $e');
      rethrow;
    }
  }
}
