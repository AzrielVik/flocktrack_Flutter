import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/lamb.dart';
import '../services/lamb_service.dart';
import 'edit_lamb_screen.dart';

class LambDetailScreen extends StatelessWidget {
  final Lamb lamb;

  const LambDetailScreen({super.key, required this.lamb});

  @override
  Widget build(BuildContext context) {
    final String? fullImageUrl = lamb.imageUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lamb: ${lamb.tagId}'),
        backgroundColor: Colors.brown[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (fullImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: fullImageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              )
            else
              const Icon(Icons.image_not_supported, size: 100),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    infoRow('Tag ID', lamb.tagId),
                    infoRow('Gender', lamb.gender),
                    infoRow('Birth Date',
                        lamb.birthDate.toLocal().toString().split(' ')[0]),
                    infoRow('Mother ID', lamb.motherTagId ?? 'Unknown'),
                    infoRow('Father ID', lamb.fatherTagId ?? 'Unknown'),
                    if (lamb.weaningWeight != null)
                      infoRow('Weaning Weight', '${lamb.weaningWeight} kg'),
                  ],
                ),
              ),
            ),
            if (lamb.notes != null && lamb.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Notes',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.brown[800],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.brown.shade200),
                ),
                child: Text(
                  lamb.notes!,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditLambScreen(lamb: lamb),
                      ),
                    );
                    if (result == 'refresh' && context.mounted) {
                      Navigator.pop(context, 'refresh');
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Lamb'),
                        content: const Text(
                            'Are you sure you want to delete this lamb?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, 'refresh'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == 'refresh') {
                      await LambService.deleteLamb(lamb.id);
                      if (context.mounted) {
                        Navigator.pop(context, 'refresh');
                      }
                    }
                  },
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
