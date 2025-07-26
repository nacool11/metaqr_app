import 'dart:async';
import 'dart:io';

import 'package:blue_ui_app/api_service.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

import 'package:permission_handler/permission_handler.dart';

class AnnotationFilesPage extends StatefulWidget {
  const AnnotationFilesPage({Key? key}) : super(key: key);

  @override
  State<AnnotationFilesPage> createState() => _AnnotationFilesPageState();
}

class _AnnotationFilesPageState extends State<AnnotationFilesPage> {
  final TextEditingController _searchController = TextEditingController();
  List<String> genomeResults = [];
  Set<String> selectedGenomeIds = {};
  bool genomeLoading = false;
  bool downloadLoading = false; // Add download loading state

  // Fuzzy search related variables
  List<String> _suggestions = [];
  bool _suggestionsLoading = false;
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();
  String _lastSearchedText = ''; // Track last searched text
  String _currentDisplayedSpecies =
      ''; // Track the species name for current results

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
      // 2. Current text is different from last searched text (user is typing something new)
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

    print('Getting suggestions for prefix: $prefix');
    setState(() {
      _suggestionsLoading = true;
    });

    try {
      final suggestions =
          await ApiService.getFuzzySearchSuggestions(prefix, 'species');
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
    _searchGenomeIDs();
  }

  Future<void> _searchGenomeIDs() async {
    final rawOrganismName = _searchController.text.trim();
    if (rawOrganismName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an organism name")),
      );
      return;
    }

    // Update last searched text to prevent suggestions when search is completed
    _lastSearchedText = rawOrganismName;
    _currentDisplayedSpecies =
        rawOrganismName; // Store the species name for current results

    setState(() {
      genomeLoading = true;
      genomeResults = [];
      selectedGenomeIds = {};
    });

    try {
      final payload = [rawOrganismName];
      final response = await ApiService.getGenomeIDs(payload);
      final key = rawOrganismName.toLowerCase().replaceAll(' ', '_');
      final dataList = response[key] ?? [];

      genomeResults =
          List<String>.from(dataList.map((item) => item.toString()));
      selectedGenomeIds = {};

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Found ${genomeResults.length} results.")),
      );
    } catch (e) {
      genomeResults = [];
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching genome IDs")),
      );
    }

    setState(() {
      genomeLoading = false;
    });
  }

  Future<void> _downloadSelectedFiles() async {
    if (selectedGenomeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one file.")),
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
          // Try requesting WRITE_EXTERNAL_STORAGE as fallback
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

      // Show download progress
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
              Text("Downloading ${selectedGenomeIds.length} files..."),
            ],
          ),
          duration: const Duration(seconds: 30), // Longer duration for download
        ),
      );

      // Download the zip file using the API service
      final zipBytes =
          await ApiService.downloadAnnotationZip(selectedGenomeIds.toList());

      // Determine the downloads directory
      Directory downloadsDir;
      if (Platform.isAndroid) {
        // Try multiple possible download paths
        final possiblePaths = [
          '/storage/emulated/0/Download',
          '/storage/emulated/0/Downloads',
          '/sdcard/Download',
          '/sdcard/Downloads',
        ];

        downloadsDir = Directory(possiblePaths[0]); // Default
        for (final path in possiblePaths) {
          final dir = Directory(path);
          if (await dir.exists()) {
            downloadsDir = dir;
            break;
          }
        }

        // Create directory if it doesn't exist
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }
      } else {
        // For iOS or other platforms, use a different approach
        downloadsDir = await getApplicationDocumentsDirectory();
      }

      // Generate a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'annotations_${timestamp}.zip';
      final file = File('${downloadsDir.path}/$fileName');

      // Write the downloaded bytes to file
      await file.writeAsBytes(zipBytes);

      // Verify file was created successfully
      if (await file.exists()) {
        final fileSize = await file.length();
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully downloaded $fileName\nSize: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB\nLocation: ${file.path}',
            ),
            duration: const Duration(seconds: 5),
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.blue.shade500, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Expanded(
              flex: 4,
              child: Text("GENOME ID", style: TextStyle(color: Colors.white))),
          Expanded(
              flex: 4,
              child:
                  Text("SPECIES NAME", style: TextStyle(color: Colors.white))),
          Expanded(
              flex: 2,
              child: Text("SELECT",
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _buildRow(String genomeId) {
    final selected = selectedGenomeIds.contains(genomeId);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: Text(genomeId)),
          Expanded(
              flex: 4,
              child: Text(_currentDisplayedSpecies)), // Use stored species name
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Checkbox(
                value: selected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      selectedGenomeIds.add(genomeId);
                    } else {
                      selectedGenomeIds.remove(genomeId);
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = selectedGenomeIds.length == genomeResults.length &&
        genomeResults.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Get Annotation Files"),
        backgroundColor: Colors.blue.shade400,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar with Fuzzy Search
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Enter Organism Name',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _suggestionsLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: genomeLoading ? null : _searchGenomeIDs,
                      child: genomeLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Search"),
                    ),
                  ],
                ),

                // Suggestions List
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
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
            const SizedBox(height: 20),

            // Header Controls
            if (genomeResults.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Search Results (${genomeResults.length} items)",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: allSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              selectedGenomeIds = {...genomeResults};
                            } else {
                              selectedGenomeIds.clear();
                            }
                          });
                        },
                      ),
                      Text(allSelected ? "Deselect All" : "Select All",
                          style: const TextStyle(color: Colors.blue)),
                      const SizedBox(width: 10),
                      if (selectedGenomeIds.isNotEmpty)
                        ElevatedButton(
                          onPressed:
                              downloadLoading ? null : _downloadSelectedFiles,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(12),
                            shape: const CircleBorder(),
                          ),
                          child: downloadLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.download),
                        )
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 12),

            // Table + Rows
            if (genomeLoading)
              const CircularProgressIndicator()
            else if (genomeResults.isNotEmpty)
              Expanded(
                child: Column(
                  children: [
                    _buildTableHeader(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: genomeResults.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          return _buildRow(genomeResults[index]);
                        },
                      ),
                    ),
                  ],
                ),
              )
            else if (!genomeLoading)
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
                        'Functional Annotation Files',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Download functional annotation files in .tsv format by searching organism names at the species level. User-friendly interface allows selection of both species and strains for downloading.',
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
          ],
        ),
      ),
    );
  }
}
