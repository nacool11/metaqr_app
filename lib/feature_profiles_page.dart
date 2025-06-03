import 'dart:async';
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

  // Fuzzy search related variables
  List<String> _suggestions = [];
  bool _suggestionsLoading = false;
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();
  String _lastSearchedText = ''; // Track last searched text

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
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final currentText = _searchController.text.trim();

      // Only show suggestions if:
      // 1. Text is not empty
      // 2. We're in species mode (!toggle)
      // 3. Current text is different from last searched text (user is typing something new)
      if (currentText.isNotEmpty &&
          !toggle &&
          currentText != _lastSearchedText) {
        _getFuzzySearchSuggestions();
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    });
  }

  Future<void> _getFuzzySearchSuggestions() async {
    final prefix = _searchController.text.trim();
    if (prefix.isEmpty) return;

    print('Getting suggestions for prefix: $prefix');
    setState(() {
      _suggestionsLoading = true;
    });

    try {
      final suggestions = await ApiService.getFuzzySearchSuggestions(prefix);
      print('Received ${suggestions.length} suggestions');
      setState(() {
        _suggestions = suggestions;
        _suggestionsLoading = false;
      });
    } catch (e) {
      print('Error getting suggestions: $e');
      setState(() {
        _suggestions = [];
        _suggestionsLoading = false;
      });
    }
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _suggestions = [];
    });
    _searchFocusNode.unfocus();

    // Auto-search when suggestion is selected
    _searchSpecies();
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

    // Update last searched text to prevent suggestions when search is completed
    _lastSearchedText = rawOrganismName;

    try {
      final payload = [rawOrganismName];
      final response = await ApiService.getFuncMatrixFile(
        payload,
        _selectedFunctionality!,
        !toggle ? 'species' : 'genomes',
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

      // Reset pagination when new search is performed
      _currentPage = 0;

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
                          onTap: () => setState(() {
                            toggle = !toggle;
                            // Clear suggestions when switching modes
                            _suggestions = [];
                            // Reset last searched text when switching modes
                            _lastSearchedText = '';
                          }),
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

            // Search Section
            if (_selectedFunctionality != null) ...[
              Column(
                children: [
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Enter the Organism Name...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _suggestionsLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30)),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),

                  // Suggestions List
                  if (_suggestions.isNotEmpty && !toggle) ...[
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
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
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _suggestions.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: Colors.grey.shade200,
                        ),
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              Icons.search,
                              size: 18,
                              color: Colors.blue.shade400,
                            ),
                            title: Text(
                              _suggestions[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _selectSuggestion(_suggestions[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  _searchSpecies();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Search"),
              ),
              const SizedBox(height: 10),
            ] else
              Padding(
                padding: const EdgeInsets.only(top: 30),
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          size: 60,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Functional Feature Profiles',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Access mean derived detection profiles at species-level and functional profiles at strain-level. Download profiles for different functional categories like COG, CAZy, BiGG and more.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

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
                          childAspectRatio: 1,
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
