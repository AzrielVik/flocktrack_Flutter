import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/sheep.dart';
import '../services/sheep_service.dart';
import 'edit_sheep_screen.dart';

class SheepDetailScreen extends StatefulWidget {
  final Sheep sheep;

  const SheepDetailScreen({super.key, required this.sheep});

  @override
  State<SheepDetailScreen> createState() => _SheepDetailScreenState();
}

class _SheepDetailScreenState extends State<SheepDetailScreen> {
  List<Sheep> children = [];
  bool isLoadingChildren = true;

  @override
  void initState() {
    super.initState();
    _fetchChildren();
  }

  Future<void> _fetchChildren() async {
    try {
      final fetchedChildren =
          await SheepService.getChildrenByParentId(widget.sheep.tagId);
      setState(() {
        children = fetchedChildren.cast<Sheep>();
        isLoadingChildren = false;
      });
    } catch (e) {
      setState(() => isLoadingChildren = false);
    }
  }

  String _formatAge(DateTime dob) {
    final now = DateTime.now();
    final ageInDays = now.difference(dob).inDays;
    if (ageInDays >= 365) {
      final years = ageInDays ~/ 365;
      return '$years year${years > 1 ? 's' : ''}';
    } else if (ageInDays >= 30) {
      final months = ageInDays ~/ 30;
      return '$months month${months > 1 ? 's' : ''}';
    } else {
      return '$ageInDays day${ageInDays > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheep = widget.sheep;
    final String? fullImageUrl = sheep.imageUrl;

    String motherIdDisplay = (sheep.motherId == null || sheep.motherId!.isEmpty)
        ? 'Unknown'
        : sheep.motherId!;
    String fatherIdDisplay = (sheep.fatherId == null || sheep.fatherId!.isEmpty)
        ? 'Unknown'
        : sheep.fatherId!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sheep: ${sheep.tagId}'),
        backgroundColor: Colors.green[700],
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
                  errorWidget: (context, url, error) =>
                      const Icon(Icons.broken_image, size: 100),
                ),
              )
            else
              const Icon(Icons.image_not_supported, size: 100),

            const SizedBox(height: 16),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    infoRow('Tag ID', sheep.tagId),
                    infoRow('Gender', sheep.gender),
                    if (sheep.gender.toLowerCase() == 'female')
                      infoRow('Pregnant', sheep.pregnant == true ? 'Yes' : 'No'),
                    infoRow('Age', _formatAge(sheep.dob)),
                    infoRow('Weight', sheep.weight?.toString() ?? 'N/A'),
                    infoRow('Breed', sheep.breed ?? 'Unknown'),
                    infoRow('Mother ID', motherIdDisplay),
                    infoRow('Father ID', fatherIdDisplay),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medical Records',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      sheep.medicalRecords ?? 'No medical records available',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.yellow[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Offspring',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (isLoadingChildren)
                      const Center(child: CircularProgressIndicator())
                    else if (children.isEmpty)
                      const Text('No offspring found for this sheep.')
                    else
                      Column(
                        children: children.map((child) {
                          final tagId = child.tagId;
                          final imageUrl = child.imageUrl;
                          final ageStr = _formatAge(child.dob);

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: imageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[300],
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.broken_image),
                                    ),
                                  )
                                : const Icon(Icons.image),
                            title: Text('Tag: $tagId'),
                            subtitle: Text('Age: $ageStr'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SheepDetailScreen(sheep: child),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditSheepScreen(sheep: sheep),
                      ),
                    );
                    if (result == 'refresh' && context.mounted) {
                      Navigator.pop(context, 'refresh');
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete Sheep'),
                        content: const Text(
                            'Are you sure you want to delete this sheep?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, 'refresh'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == 'refresh') {
                      await SheepService.deleteSheep(sheep.id);
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
        children: [
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
