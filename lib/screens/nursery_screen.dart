import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/lamb.dart';
import '../services/lamb_service.dart';
import 'add_lamb_screen.dart';
import 'lamb_detail_screen.dart';
import 'package:intl/intl.dart';

class NurseryScreen extends StatefulWidget {
  const NurseryScreen({super.key});

  @override
  State<NurseryScreen> createState() => _NurseryScreenState();
}

class _NurseryScreenState extends State<NurseryScreen> {
  List<Lamb> lambs = [];
  List<Lamb> filteredLambs = [];
  bool isLoading = true;
  String? errorMessage;

  String searchQuery = '';
  String sortBy = 'Tag ID';

  @override
  void initState() {
    super.initState();
    fetchLambs();
  }

  Future<void> fetchLambs() async {
    try {
      final fetched = await LambService.fetchAllLambs();
      if (!mounted) return;
      setState(() {
        lambs = fetched;
        isLoading = false;
      });
      filterAndSortLambs();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load lamb data.';
        isLoading = false;
      });
    }
  }

  void filterAndSortLambs() {
    List<Lamb> filtered = lambs
        .where((lamb) =>
            lamb.tagId.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    switch (sortBy) {
      case 'Age':
        filtered.sort((a, b) => a.birthDate.compareTo(b.birthDate));
        break;
      case 'Gender':
        filtered.sort((a, b) => a.gender.compareTo(b.gender));
        break;
      case 'Tag ID':
      default:
        filtered.sort((a, b) => a.tagId.compareTo(b.tagId));
    }

    setState(() {
      filteredLambs = filtered;
    });
  }

  String formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (_) {
      return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        centerTitle: true, // ✅ Centered
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/lamblogo.jpg',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Nursery',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 🔍 Search + Filter row
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by Tag ID...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.blue.shade700, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      searchQuery = value;
                      filterAndSortLambs();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                  ),
                  child: DropdownButton<String>(
                    value: sortBy,
                    underline: const SizedBox(),
                    items: ['Tag ID', 'Age', 'Gender']
                        .map((value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        sortBy = value;
                        filterAndSortLambs();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // 🐑 Lamb list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(child: Text(errorMessage!))
                    : RefreshIndicator(
                        onRefresh: fetchLambs,
                        child: filteredLambs.isEmpty
                            ? ListView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(), // ✅ enables pull-to-refresh
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.only(top: 150),
                                    child: Center(
                                      child: Text(
                                        "No lambs yet.\nTap the '+' button below to add your first lamb.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: filteredLambs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  return _LambListTile(
                                    lamb: filteredLambs[index],
                                    onRefresh: fetchLambs,
                                    formatDate: formatDate,
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLambScreen()),
          );
          if (result == 'refresh') fetchLambs();
        },
        backgroundColor: Colors.green[700],
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _LambListTile extends StatelessWidget {
  final Lamb lamb;
  final VoidCallback onRefresh;
  final String Function(String) formatDate;

  const _LambListTile({
    required this.lamb,
    required this.onRefresh,
    required this.formatDate,
  });

  String getResolvedImageUrl() {
    final url = lamb.imageUrl;

    if (url == null || url.isEmpty) {
      return 'https://via.placeholder.com/150';
    }

    if (url.startsWith('http')) {
      return url;
    }

    if (url.startsWith('/uploads/')) {
      return 'https://nduwa-sheep-backend.onrender.com$url';
    }

    return 'https://nduwa-sheep-backend.onrender.com/uploads/$url';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = getResolvedImageUrl();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 3,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: resolvedImageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              width: 60,
              height: 60,
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            ),
          ),
        ),
        title: Text(
          'Tag: ${lamb.tagId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gender: ${lamb.gender}'),
            const SizedBox(height: 2),
            Text('DOB: ${formatDate(lamb.birthDate.toString())}'),
            const SizedBox(height: 2),
            Text('Mother: ${lamb.motherId ?? 'Unknown'}'),
            const SizedBox(height: 2),
            Text('Father: ${lamb.fatherId ?? 'Unknown'}'),
          ],
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LambDetailScreen(lamb: lamb),
            ),
          );
          if (result == 'refresh') onRefresh();
        },
      ),
    );
  }
}
