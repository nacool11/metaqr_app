import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:blue_ui_app/api_service.dart';
import 'package:blue_ui_app/dropdown.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FeatureProfilesPage extends StatefulWidget {
  const FeatureProfilesPage({Key? key}) : super(key: key);

  @override
  State<FeatureProfilesPage> createState() => _FeatureProfilesPageState();
}

class _FeatureProfilesPageState extends State<FeatureProfilesPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFunctionality;
  bool toggle = false; // false = species, true = genomes

  final List<String> _functionalityOptions = [
    'cazy',
    'COG',
    'BiGG',
    'KEGG_Module',
    'KEGG Orthologs',
    'KEGG_Reaction',
    'EC',
    'PFAMs',
  ];

  bool speciesLoading = false;
  bool downloadLoading = false;

  // Species data (existing)
  List<List<dynamic>>? speciesData;

  // Genome data (new)
  Map<String, dynamic>? genomePreviewData;
  bool genomeLoading = false;
  String _lastSearchedSpeciesName =
      ''; // Store the searched species name for genome downloads

  // Fuzzy search related variables
  List<String> _suggestions = [];
  bool _suggestionsLoading = false;
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();
  String _lastSearchedText = '';

  // Pagination for species
  int _currentPage = 0;
  static const int _itemsPerPage = 30;

  // Pagination for genomes
  int _genomePage = 1;
  static const int _genomePageSize = 10;

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

      // Show suggestions for both species and genomes when typing
      if (currentText.isNotEmpty && currentText != _lastSearchedText) {
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

    final searchType = toggle ? 'genomes' : 'species';
    print('Getting suggestions for prefix: $prefix, type: $searchType');

    setState(() {
      _suggestionsLoading = true;
    });

    try {
      final suggestions =
          await ApiService.getFuzzySearchSuggestions(prefix, searchType);
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
    if (toggle) {
      _searchGenomes();
    } else {
      _searchSpecies();
    }
  }

  Future<void> _searchSpecies() async {
    setState(() {
      speciesLoading = true;
    });

    final rawOrganismName = _searchController.text.trim();

    if (rawOrganismName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an organism name")),
      );
      setState(() {
        speciesLoading = false;
      });
      return;
    }

    _lastSearchedText = rawOrganismName;

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

      _currentPage = 0;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Found ${speciesData?.length ?? 0} rows.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching species data")),
      );
    }

    setState(() {
      speciesLoading = false;
    });
  }

  Future<void> _searchGenomes() async {
    if (_selectedFunctionality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select functionality first")),
      );
      return;
    }

    final searchText = _searchController.text.trim();
    if (searchText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a species name")),
      );
      return;
    }

    setState(() {
      genomeLoading = true;
      _genomePage = 1; // Reset to first page
    });

    _lastSearchedText = searchText;
    _lastSearchedSpeciesName = searchText; // Store for download functionality

    try {
      // Updated API call to include POST data with species name
      final response = await ApiService.getGenomeFuncMatrixPreviewWithSpecies(
        funcType: _selectedFunctionality!,
        speciesName: searchText,
        page: _genomePage,
        pageSize: _genomePageSize,
      );

      if (response != null) {
        setState(() {
          genomePreviewData = response;
        });

        final totalColumns = response['pagination']?['total_columns'] ?? 0;
        final speciesCount = response['species_data']?.length ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Found $speciesCount species with $totalColumns functional columns."),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error fetching genome data")),
        );
        setState(() {
          genomePreviewData = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching genome data: $e")),
      );
      setState(() {
        genomePreviewData = null;
      });
    }

    setState(() {
      genomeLoading = false;
    });
  }

  Future<void> _loadGenomePage(int page) async {
    if (_selectedFunctionality == null || _lastSearchedSpeciesName.isEmpty) {
      return;
    }

    setState(() {
      genomeLoading = true;
    });

    try {
      final response = await ApiService.getGenomeFuncMatrixPreviewWithSpecies(
        funcType: _selectedFunctionality!,
        speciesName: _lastSearchedSpeciesName,
        page: page,
        pageSize: _genomePageSize,
      );

      if (response != null) {
        setState(() {
          genomePreviewData = response;
          _genomePage = page;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading page: $e")),
      );
    }

    setState(() {
      genomeLoading = false;
    });
  }

  Future<void> _downloadFullFile() async {
    if (_selectedFunctionality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select functionality first.")),
      );
      return;
    }

    // For species mode, we need search text. For genomes, we need the searched species name
    if (!toggle && _searchController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete the search first.")),
      );
      return;
    }

    if (toggle && _lastSearchedSpeciesName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please search for genomes first.")),
      );
      return;
    }

    setState(() {
      downloadLoading = true;
    });

    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          final writeStatus = await Permission.storage.request();
          if (!writeStatus.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Storage permission denied")),
            );
            setState(() {
              downloadLoading = false;
            });
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Text(toggle
                  ? "Downloading genome functional matrix CSV file..."
                  : "Downloading species functional matrix ZIP file..."),
            ],
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      late Uint8List fileBytes;

      if (toggle) {
        // For genome mode - download CSV for the searched species
        fileBytes = await ApiService.downloadGenomeFuncMatrixFull(
          [_lastSearchedSpeciesName], // Use the searched species name
          _selectedFunctionality!,
        );
      } else {
        // For species mode - download for specific organism as ZIP
        fileBytes = await ApiService.downloadGenomeFuncMatrixFull(
          [_searchController.text.trim()],
          _selectedFunctionality!,
        );
      }

      Directory downloadsDir;
      if (Platform.isAndroid) {
        final possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];

        downloadsDir = Directory(possiblePaths[0]);
        for (final path in possiblePaths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            downloadsDir = dir;
            break;
          }
        }

        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } else {
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String fileName;

      if (toggle) {
        // For genome mode - CSV file for specific species
        final speciesName = _lastSearchedSpeciesName.replaceAll(' ', '_');
        fileName =
            'genome_functional_matrix_${speciesName}_${_selectedFunctionality}_$timestamp.csv';
      } else {
        // For species mode - ZIP file containing CSV files
        final organismName = _searchController.text.trim().replaceAll(' ', '_');
        fileName =
            'species_functional_matrix_${organismName}_${_selectedFunctionality}_$timestamp.zip';
      }

      final file = File('${downloadsDir.path}/$fileName');

      await file.writeAsBytes(fileBytes);

      if (await file.exists()) {
        final fileSize = await file.length();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully downloaded $fileName\nSize: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB\nLocation: ${file.path}${toggle ? '\n\nCSV file ready for analysis.' : '\n\nExtract the ZIP file to access CSV files.'}',
            ),
            duration: const Duration(seconds: 7),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("File was not created successfully");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Download failed: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      debugPrint("Download error: $e");
    } finally {
      setState(() {
        downloadLoading = false;
      });
    }
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
                              // Clear previous data when functionality changes
                              speciesData = null;
                              genomePreviewData = null;
                              _lastSearchedSpeciesName = '';
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
                            _suggestions = [];
                            _lastSearchedText = '';
                            _lastSearchedSpeciesName = '';
                            // Clear data when switching modes
                            speciesData = null;
                            genomePreviewData = null;
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
              TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: toggle
                      ? 'Enter the Species Name for genomes...'
                      : 'Enter the Organism Name...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _suggestionsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),

              // FIXED: Suggestions List with proper height constraints
              if (_suggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 200, // Fixed height instead of flexible
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Icon(
                            toggle ? Icons.biotech : Icons.search,
                            size: 16,
                            color: Colors.blue.shade400,
                          ),
                          title: Text(
                            _suggestions[index],
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () => _selectSuggestion(_suggestions[index]),
                        );
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (toggle) {
                        _searchGenomes();
                      } else {
                        _searchSpecies();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("Search"),
                  ),
                  // Download button - show for both species and genome data
                  if ((!toggle &&
                          speciesData != null &&
                          speciesData!.isNotEmpty) ||
                      (toggle && genomePreviewData != null))
                    ElevatedButton(
                      onPressed: downloadLoading ? null : _downloadFullFile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: downloadLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.download, size: 18),
                    ),
                ],
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
            if (speciesLoading || genomeLoading)
              const Center(child: CircularProgressIndicator())
            else if (!toggle &&
                speciesData != null &&
                speciesData!.isNotEmpty) ...[
              // Species Results (existing implementation)
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
            ] else if (toggle && genomePreviewData != null) ...[
              // Genome Results with improved UI theme
              Expanded(
                child: Column(
                  children: [
                    // Functional Headers Section with better design
                    if (genomePreviewData!['functional_headers'] != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.blue.shade100],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.blue.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.functions,
                                    color: Colors.blue.shade700, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Functional Headers',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade600,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${genomePreviewData!['functional_headers'].length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount:
                                    genomePreviewData!['functional_headers']
                                        .length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.category,
                                            color: Colors.blue.shade600,
                                            size: 16),
                                        const SizedBox(height: 4),
                                        Text(
                                          genomePreviewData![
                                              'functional_headers'][index],
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey.shade700,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Species Data Section with enhanced design
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            genomePreviewData!['species_data']?.length ?? 0,
                        itemBuilder: (context, speciesIndex) {
                          final speciesItem =
                              genomePreviewData!['species_data'][speciesIndex];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              childrenPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.biotech,
                                  color: Colors.blue.shade700,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                speciesItem['Species_Name'] ??
                                    'Unknown Species',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Container(
                                margin: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Genomes: ${speciesItem['Total_Genome_Count']}',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (speciesItem['More_Genomes_Available'])
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'More available',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              children: [
                                ...speciesItem['Genomes'].map<Widget>((genome) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.science,
                                            color: Colors.blue.shade600,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                genome['Genome_ID'] ??
                                                    'Unknown ID',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Values: ${genome['Functional_Values']?.take(5).join(', ')}${genome['Functional_Values']?.length > 5 ? '...' : ''}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.blue.shade700,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Enhanced Pagination Section
                    if (genomePreviewData!['pagination'] != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.grey.shade50, Colors.grey.shade100],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.grey.shade600, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Page $_genomePage of ${genomePreviewData!['pagination']['total_pages']}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Total Functional Columns: ${genomePreviewData!['pagination']['total_columns']}',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_genomePage > 1)
                                  ElevatedButton.icon(
                                    onPressed: genomeLoading
                                        ? null
                                        : () =>
                                            _loadGenomePage(_genomePage - 1),
                                    icon: const Icon(Icons.chevron_left,
                                        size: 18),
                                    label: const Text("Previous"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                  ),
                                if (_genomePage > 1 &&
                                    _genomePage <
                                        (genomePreviewData!['pagination']
                                                ['total_pages'] ??
                                            1))
                                  const SizedBox(width: 16),
                                if (_genomePage <
                                    (genomePreviewData!['pagination']
                                            ['total_pages'] ??
                                        1))
                                  ElevatedButton.icon(
                                    onPressed: genomeLoading
                                        ? null
                                        : () =>
                                            _loadGenomePage(_genomePage + 1),
                                    icon: const Icon(Icons.chevron_right,
                                        size: 18),
                                    label: const Text("Next"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade400,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (genomeLoading) ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.blue.shade600),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if ((toggle &&
                    genomePreviewData == null &&
                    _lastSearchedText.isNotEmpty) ||
                (!toggle && speciesData != null && speciesData!.isEmpty))
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.orange.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No results found",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Try searching with a different term",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
