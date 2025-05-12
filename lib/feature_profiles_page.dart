import 'package:blue_ui_app/api_service.dart';
import 'package:blue_ui_app/dropdown.dart';
import 'package:flutter/material.dart';

class FeatureProfilesPage extends StatefulWidget {
  const FeatureProfilesPage({Key? key}) : super(key: key);

  @override
  State<FeatureProfilesPage> createState() => _FeatureProfilesPageState();
}

class _FeatureProfilesPageState extends State<FeatureProfilesPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFunctionality;
  bool toggle = false;

  final List<String> _functionalityOptions = [
    'cazy',
    'COG',
    'BiGG',
    'KEGG_Module',
    'KEGG Orthologs',
    'KEGG_Reaction',
    'EC',
    'PFAMs',
    'Combined',
  ];

  bool speciesLoading = false;
  List<List<dynamic>>? speciesData;

  int _currentPage = 0;
  static const int _itemsPerPage = 30;

  List<List<dynamic>> get _paginatedResults {
    if (speciesData == null) return [];
    int start = _currentPage * _itemsPerPage;
    int end = (_currentPage + 1) * _itemsPerPage;
    end = end > speciesData!.length ? speciesData!.length : end;
    return speciesData!.sublist(start, end);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchSpecies() async {
    speciesLoading = true;
    setState(() {});

    final rawOrganismName = _searchController.text.trim();

    if (rawOrganismName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an organism name")),
      );
      speciesLoading = false;
      setState(() {});
      return;
    }

    try {
      final payload = [rawOrganismName];
      final response = await ApiService.getFuncMatrixFile(
        payload,
        _selectedFunctionality!,
        'species',
      );

      final raw = response.toString();
      final lines = raw.split('\n');
      final cleanedLines =
          lines.where((line) => line.trim().isNotEmpty).toList();

      speciesData = cleanedLines
          .map((line) {
            final parts = line.split(',');
            return parts.map((e) => e.trim()).toList();
          })
          .where((row) => row.length == 2)
          .toList();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Found ${speciesData?.length ?? 0} rows.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching species data")),
      );
    }

    speciesLoading = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
        title: const Text(
          'Functional Feature Profiles',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown + toggle
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Functionality:',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomDropDown(
                          itemsList: _functionalityOptions,
                          onChanged: ({required value}) {
                            setState(() {
                              _selectedFunctionality = value;
                            });
                          },
                          selectedValue: _selectedFunctionality,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('species',
                          style: TextStyle(color: Colors.blue)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => toggle = !toggle),
                          child: Container(
                            width: 50,
                            height: 28,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.blue.shade200,
                              border: Border.all(
                                  color: Colors.grey.shade400, width: 0.5),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  left: toggle ? 22 : 0,
                                  right: toggle ? 0 : 22,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Text('genomes',
                          style: TextStyle(color: Colors.blue)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Search
            if (_selectedFunctionality != null) ...[
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Enter the Organism Name...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  if (!toggle) {
                    _searchSpecies();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Switch to 'species' to search.")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Search"),
              ),
              const SizedBox(height: 10),
            ],

            // Result Section
            if (speciesLoading)
              const Center(child: CircularProgressIndicator())
            else if (speciesData != null && speciesData!.length > 1) ...[
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.builder(
                        itemCount: _paginatedResults.length,
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1, // ✅ FIXED: Enough vertical space
                        ),
                        itemBuilder: (context, index) {
                          final row = _paginatedResults[index];
                          return Card(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(row[0],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(row[1]),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentPage > 0)
                          ElevatedButton(
                            onPressed: () => setState(() => _currentPage--),
                            child: const Text("Previous"),
                          ),
                        const SizedBox(width: 16),
                        if ((_currentPage + 1) * _itemsPerPage <
                            (speciesData?.length ?? 0))
                          ElevatedButton(
                            onPressed: () => setState(() => _currentPage++),
                            child: const Text("Next"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (speciesData != null)
              const Center(child: Text("No results found")),
          ],
        ),
      ),
    );
  }
}
