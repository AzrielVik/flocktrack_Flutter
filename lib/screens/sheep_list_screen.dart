import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/sheep.dart';
import '../services/sheep_service.dart';
import 'sheep_detail_screen.dart';
import 'add_sheep_screen.dart';
import 'nursery_screen.dart';
import 'package:intl/intl.dart';

class SheepListScreen extends StatefulWidget {
  const SheepListScreen({super.key});

  @override
  State<SheepListScreen> createState() => _SheepListScreenState();
}

class _SheepListScreenState extends State<SheepListScreen> {
  List<Sheep> sheepList = [];
  List<Sheep> filteredSheepList = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = '';
  String sortBy = 'Tag ID';

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchSheep();
  }

  Future<void> fetchSheep() async {
    try {
      final fetchedSheep = await SheepService.getSheep();
      if (!mounted) return;
      setState(() {
        sheepList = fetchedSheep;
        isLoading = false;
      });
      filterAndSortSheep();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load sheep data.';
        isLoading = false;
      });
    }
  }

  void filterAndSortSheep() {
    List<Sheep> filtered = sheepList
        .where((sheep) =>
            sheep.tagId.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    switch (sortBy) {
      case 'Age':
        filtered.sort((a, b) => a.age.compareTo(b.age));
        break;
      case 'Gender':
        filtered.sort((a, b) => a.gender.compareTo(b.gender));
        break;
      case 'Tag ID':
      default:
        filtered.sort((a, b) => a.tagId.compareTo(b.tagId));
    }

    setState(() {
      filteredSheepList = filtered;
    });
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String? resolveImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    return imageUrl; // Expected to be full Cloudinary URL
  }

  Widget _buildAllSheepTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
          child: Text(errorMessage!,
              style: const TextStyle(color: Colors.red)));
    }
    if (filteredSheepList.isEmpty) {
      return const Center(child: Text('No sheep found.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by Tag ID...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                    filterAndSortSheep();
                  },
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: sortBy,
                items: ['Tag ID', 'Age', 'Gender']
                    .map((value) => DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    sortBy = value;
                    filterAndSortSheep();
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchSheep,
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: filteredSheepList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sheep = filteredSheepList[index];
                final imageUrl = resolveImageUrl(sheep.imageUrl);

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SheepDetailScreen(sheep: sheep)),
                    );
                    if (!mounted) return;
                    if (result == 'refresh') fetchSheep();
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const SizedBox(
                                            width: 70,
                                            height: 70,
                                            child: Center(
                                                child:
                                                    CircularProgressIndicator())),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 30,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      size: 30,
                                      color: Colors.grey,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sheep.tagId,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('Gender: ${sheep.gender}'),
                                if (sheep.gender.toLowerCase() == 'female')
                                  Text(
                                    'Pregnancy: ${sheep.pregnant == true ? "Yes" : "No"}',
                                    style: const TextStyle(
                                        color: Colors.deepOrangeAccent),
                                  ),
                                Text('DOB: ${formatDate(sheep.dob)}'),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNurseryTab() {
    return const NurseryScreen();
  }

  Widget _buildAddSheepTab() {
    return const AddSheepScreen();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _buildAllSheepTab(),
      _buildNurseryTab(),
      _buildAddSheepTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/newlogo.jpg',
                  height: 36,
                  width: 36,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'FlockTrack',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue[800],
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "All Sheep",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.child_care),
            label: "Nursery",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: "Add Sheep",
          ),
        ],
      ),
    );
  }
}
