import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sheep.dart';
import '../models/lamb.dart';

class SheepService {
  static const String baseUrl = 'https://nduwa-sheep-backend.onrender.com';

  static Future<List<Sheep>> fetchAllSheep() async {
    try {
      print('🔄 Fetching ALL sheep...');
      final response = await http.get(Uri.parse('$baseUrl/sheep'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => Sheep.fromJson(item)).toList();
      } else {
        throw Exception('❌ Failed to fetch all sheep. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception in fetchAllSheep(): $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllSheep() async {
    try {
      print('🔄 Fetching id & tag_id for all sheep...');
      final response = await http.get(Uri.parse('$baseUrl/sheep'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          return {
            'id': item['id'],
            'tag_id': item['tag_id'],
          };
        }).toList();
      } else {
        throw Exception('❌ Failed to load sheep list. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error in getAllSheep(): $e');
      return [];
    }
  }

  static Future<List<Sheep>> getSheep() async {
    try {
      print('🔄 Fetching all sheep from $baseUrl/sheep ...');
      final response = await http.get(Uri.parse('$baseUrl/sheep'));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('🧪 Decoded JSON type: ${decoded.runtimeType}');

        List<dynamic> data;

        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map && decoded.containsKey('data')) {
          data = decoded['data'];
        } else {
          print('❌ Unexpected JSON structure.');
          return [];
        }

        print('✅ Parsed ${data.length} sheep from response.');

        final filteredData = data.where((item) => item['is_lamb'] != true).toList();

        return filteredData.map((json) => Sheep.fromJson(json)).toList();
      } else {
        print('❌ Failed to load sheep. Status code: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('💥 Exception while fetching sheep: $e');
      return [];
    }
  }

  static Future<Sheep?> fetchSheep(String tagId) async {
    try {
      print('🔍 Fetching sheep by tag_id: $tagId ...');
      final response = await http.get(Uri.parse('$baseUrl/sheep/tag/$tagId'));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Sheep.fromJson(jsonData['data']);
      } else {
        print('❌ Failed to fetch sheep by tag_id. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('💥 Exception in fetchSheep(): $e');
      return null;
    }
  }

  static Future<Sheep> fetchSheepById(int id) async {
    try {
      print('🔍 Fetching sheep with ID $id ...');
      final response = await http.get(Uri.parse('$baseUrl/sheep/$id'));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Sheep.fromJson(jsonData['data']);
      } else {
        throw Exception('❌ Failed to load sheep by ID. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception while fetching sheep by ID: $e');
      rethrow;
    }
  }

  static Future<bool> deleteSheep(int id) async {
    try {
      print('🗑️ Deleting sheep with ID $id ...');
      final response = await http.delete(Uri.parse('$baseUrl/sheep/$id'));

      print('📡 Delete response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('💥 Exception while deleting sheep: $e');
      return false;
    }
  }

  static Future<bool> updateSheep({
    required int id,
    required String tagId,
    required String gender,
    required bool pregnant,
    required DateTime dob,
    String? motherId,
    String? fatherId,
    required double weight,
    required String breed,
    required String medicalRecords,
    String? imageUrl, // now only url as string
  }) async {
    try {
      print('✏️ Updating sheep via JSON (ID: $id) ...');

      final uri = Uri.parse('$baseUrl/sheep/$id');
      final Map<String, dynamic> payload = {
        'tag_id': tagId,
        'gender': gender,
        'pregnant': pregnant,
        'dob': dob.toIso8601String().split('T')[0],
        'mother_id': motherId,
        'father_id': fatherId,
        'weight': weight,
        'breed': breed,
        'medical_records': medicalRecords,
        'image_url': imageUrl,
      };

      // Clean up null/empty values
      payload.removeWhere((key, value) => value == null || value == '');

      final response = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      print('📡 Sheep JSON update response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('💥 Exception during sheep JSON update: $e');
      return false;
    }
  }

  static Future<bool> addSheep({
    required String tagId,
    required String gender,
    required bool isPregnant,
    required String medicalRecords,
    required String dob,
    String? imageUrl,
    double? weight,
    String? breed,
    String? motherId,
    String? fatherId,
    bool isLamb = false,
  }) async {
    try {
      print('➕ Adding new sheep (JSON) with imageUrl...');
      final response = await http.post(
        Uri.parse('$baseUrl/sheep'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'tag_id': tagId,
          'gender': gender,
          'pregnant': isPregnant,
          'medical_records': medicalRecords,
          'dob': dob,
          'is_lamb': isLamb,
          if (weight != null) 'weight': weight,
          if (breed != null) 'breed': breed,
          if (motherId != null) 'mother_id': motherId,
          if (fatherId != null) 'father_id': fatherId,
          if (imageUrl != null) 'image_url': imageUrl,
        }),
      );

      print('📡 Add response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');
      return response.statusCode == 201;
    } catch (e) {
      print('💥 Exception while adding sheep: $e');
      return false;
    }
  }

  static Future<List<Lamb>> getLambsByParentId(String parentId) async {
    try {
      print('🔄 Fetching lambs for parent ID: $parentId ...');
      final response = await http.get(Uri.parse('$baseUrl/lambs/by-parent/$parentId'));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Lamb.fromJson(json)).toList();
      } else {
        throw Exception('❌ Failed to load lambs for parent $parentId. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception while fetching lambs by parent ID: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getChildrenByParentId(String parentId) async {
    try {
      print('🔄 Fetching all children (sheep + lambs) for parent ID: $parentId ...');
      final response = await http.get(Uri.parse('$baseUrl/sheep/offspring/$parentId'));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Sheep> sheepChildren = (data['sheep_children'] as List)
            .map((json) => Sheep.fromJson(json))
            .toList();

        final List<Lamb> lambChildren = (data['lamb_children'] as List)
            .map((json) => Lamb.fromJson(json))
            .toList();

        return [...sheepChildren, ...lambChildren];
      } else {
        throw Exception('❌ Failed to load offspring. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception while fetching offspring: $e');
      return [];
    }
  }
}
