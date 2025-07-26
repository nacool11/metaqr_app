import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:blue_ui_app/dropdown.dart';
import 'package:blue_ui_app/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DescriptionPage extends StatefulWidget {
  const DescriptionPage({Key? key}) : super(key: key);

  @override
  State<DescriptionPage> createState() => _DescriptionPageState();
}

class _DescriptionPageState extends State<DescriptionPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFunctionality;
  bool toggle = false;
  final bool _dropdownOpen = false;

  // Search suggestions related variables
  List<String> _suggestions = [];
  bool _suggestionsLoading = false;
  Timer? _debounceTimer;
  final FocusNode _searchFocusNode = FocusNode();
  String _lastSearchedText = ''; // Track last searched text
  final Map<String, List<String>> _suggestionCache =
      {}; // Cache for suggestions

  // Download related variables
  bool _isDownloading = false;
  String _downloadingItem = '';

  // Functionality options for Description/ID
  final List<String> _functionalityOptions = [
    'Gene ID',
    'Protein ID',
    'GO Terms',
    'EC Number',
    'Pathway ID',
    'Domain ID',
    'InterPro ID',
    'Custom ID',
  ];

  @override
  void initState() {
    super.initState();
    // Add listener to search controller for real-time search
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Modified method to handle text changes with debouncing - now triggers from 1 character
  void _onSearchTextChanged() {
    final currentText = _searchController.text.trim();

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Only search if functionality is selected and text is not empty
    if (_selectedFunctionality == null || currentText.isEmpty) {
      setState(() {
        _suggestions = [];
        _suggestionsLoading = false;
      });
      return;
    }

    // Don't search if text hasn't changed - REMOVED the length < 2 check
    if (currentText == _lastSearchedText) {
      return;
    }

    // Set up debounced search (300ms delay) - now triggers from 1 character
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && currentText == _searchController.text.trim()) {
        _getSearchSuggestions();
      }
    });
  }

  Future<void> _getSearchSuggestions() async {
    final descName = _searchController.text.trim().toLowerCase();
    // CHANGED: Now only checks if empty, not length < 2
    if (descName.isEmpty) return;

    // Check cache first
    if (_suggestionCache.containsKey(descName)) {
      setState(() {
        _suggestions = _suggestionCache[descName]!;
        _suggestionsLoading = false;
      });
      return;
    }

    print('Getting search suggestions for: $descName');
    setState(() {
      _suggestionsLoading = true;
    });

    try {
      final suggestions = await ApiService.getDescriptionSuggestions(descName);
      print('Received ${suggestions.length} search suggestions');

      // Cache the results
      _suggestionCache[descName] = suggestions;

      // Limit cache size to prevent memory issues
      if (_suggestionCache.length > 50) {
        final oldestKey = _suggestionCache.keys.first;
        _suggestionCache.remove(oldestKey);
      }

      // Only update if the search text hasn't changed while we were waiting
      if (_searchController.text.trim().toLowerCase() == descName) {
        setState(() {
          _suggestions = suggestions;
          _suggestionsLoading = false;
        });
      }
    } catch (e) {
      print('Error getting search suggestions: $e');

      // Only update if the search text hasn't changed while we were waiting
      if (_searchController.text.trim().toLowerCase() == descName) {
        setState(() {
          _suggestions = [];
          _suggestionsLoading = false;
        });

        // Show error message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load suggestions: ${e.toString()}'),
              backgroundColor: Colors.red.shade400,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  void _selectSuggestion(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _suggestions = [];
    });
    _searchFocusNode.unfocus();

    // Update last searched text to prevent suggestions when suggestion is selected
    _lastSearchedText = suggestion;
  }

  // New method to handle downloading species/genomes data
  Future<void> _downloadSpeciesData(String description) async {
    // Show confirmation dialog
    final bool? shouldDownload = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Download Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Download ${toggle ? 'genomes' : 'species'} data for:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade500,
                foregroundColor: Colors.white,
              ),
              child: const Text('Download'),
            ),
          ],
        );
      },
    );

    if (shouldDownload != true) return;

    setState(() {
      _isDownloading = true;
      _downloadingItem = description;
    });

    try {
      // Call the API to get species names from descriptions
      final response =
          await ApiService.getSpeciesNamesFromDescriptions([description]);

      print('API Response: $response');

      // Create a JSON string from the response
      final jsonString = const JsonEncoder.withIndent('  ').convert(response);

      // Create filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final mode = toggle ? 'genomes' : 'species';
      final filename = '${mode}_data_${timestamp}.json';

      if (kIsWeb) {
        // For web platform, show the data in a dialog and let user copy it
        _showDataDialog(jsonString, filename);
      } else {
        // For mobile/desktop, save to file
        await _saveToFile(jsonString, filename);
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully downloaded ${toggle ? 'genomes' : 'species'} data!'),
            backgroundColor: Colors.green.shade400,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error downloading species data: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download data: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isDownloading = false;
        _downloadingItem = '';
      });
    }
  }

  // Method to show data in dialog for web platform
  void _showDataDialog(String jsonString, String filename) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Download: $filename'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonString,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                // Copy to clipboard logic could be added here
                Navigator.of(context).pop();
              },
              child: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  // Method to save file to device storage
  // Method to save file to device Downloads folder
  Future<void> _saveToFile(String content, String filename) async {
    try {
      // Request storage permission for Android
      if (Platform.isAndroid) {
        final status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          // Try requesting WRITE_EXTERNAL_STORAGE as fallback
          final writeStatus = await Permission.storage.request();
          if (!writeStatus.isGranted) {
            throw Exception("Storage permission denied");
          }
        }
      }

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

      // Create the file in Downloads folder
      final file = File('${downloadsDir.path}/$filename');
      await file.writeAsString(content);

      // Verify file was created successfully
      if (await file.exists()) {
        final fileSize = await file.length();
        print('File saved to Downloads: ${file.path}');
        print('File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

        // Show success message with file location
        // Show success message (remove the existing success message and replace with this)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Successfully downloaded ${toggle ? 'genomes' : 'species'} data to Downloads folder!'),
              backgroundColor: Colors.green.shade400,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception("File was not created successfully");
      }
    } catch (e) {
      print('Error saving file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: ${e.toString()}'),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      rethrow;
    }
  }

  void _handleSearch() {
    final searchText = _searchController.text.trim();
    if (searchText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter search criteria")),
      );
      return;
    }

    if (_selectedFunctionality == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a functionality type")),
      );
      return;
    }

    // Update last searched text
    _lastSearchedText = searchText;

    // Get suggestions if not already loaded for this text
    if (_suggestions.isEmpty ||
        _searchController.text.trim().toLowerCase() !=
            _lastSearchedText.toLowerCase()) {
      _getSearchSuggestions();
    }

    // TODO: Implement your search logic here
    print('Searching for: $searchText');
    print('Functionality: $_selectedFunctionality');
    print('Mode: ${!toggle ? 'species' : 'genomes'}');
  }

  void _handleUpload() {
    // TODO: Implement file upload logic
    print('Upload file functionality');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("File upload functionality coming soon...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade300, Colors.blue.shade700],
            ),
          ),
        ),
        elevation: 0,
        title: const Row(
          children: [
            Text(
              'Database',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ' > ',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            Text(
              'Functional Description or ID',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              16.0, 16.0, 16.0, 30.0), // Extra bottom padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Functionality selection row
              Container(
                padding: const EdgeInsets.all(16),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            'Functionality:',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomDropDown(
                            itemsList: _functionalityOptions,
                            onChanged: ({required value}) {
                              setState(() {
                                _selectedFunctionality = value;
                                // Clear suggestions and cache when functionality changes
                                _suggestions = [];
                                _suggestionCache.clear();
                                _lastSearchedText = '';
                                // Trigger search if there's text in the search field
                                if (_searchController.text.trim().isNotEmpty) {
                                  _onSearchTextChanged();
                                }
                              });
                            },
                            selectedValue: _selectedFunctionality,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Toggle switches row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Species toggle
                        Text(
                          'species',
                          style: TextStyle(
                            color: !toggle
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight:
                                !toggle ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),

                        // Custom Toggle Switch for genomes
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                toggle = !toggle;
                                // Clear suggestions and cache when switching modes
                                _suggestions = [];
                                _suggestionCache.clear();
                                _lastSearchedText = '';
                                // Trigger search if there's text in the search field
                                if (_searchController.text.trim().isNotEmpty &&
                                    _selectedFunctionality != null) {
                                  _onSearchTextChanged();
                                }
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: Colors.blue.shade200,
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 0.5,
                                ),
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

                        // Genomes toggle
                        Text(
                          'genomes',
                          style: TextStyle(
                            color: toggle
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight:
                                toggle ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Search field and buttons row
              if (_selectedFunctionality != null)
                Container(
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
                    children: [
                      // Search field
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              colors: [Colors.blue.shade50, Colors.white],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            border: Border.all(
                              color: Colors.blue.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            decoration: InputDecoration(
                              hintText: toggle
                                  ? 'Enter ID or description keywords for genomes...'
                                  : 'Enter ID or description keywords (e.g., "lipid")...',
                              hintStyle: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(Icons.search,
                                  color: Colors.blue.shade400),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      color: Colors.blue.shade400,
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _suggestions = [];
                                          _lastSearchedText = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 18),
                            ),
                          ),
                        ),
                      ),

                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16, right: 16, bottom: 16),
                        child: Row(
                          children: [
                            // Search button
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: _handleSearch,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade500,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  elevation: 3,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search),
                                    SizedBox(width: 8),
                                    Text(
                                      'Search',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // OR text
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Upload button
                            Expanded(
                              flex: 3,
                              child: ElevatedButton(
                                onPressed: _handleUpload,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyan.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  elevation: 3,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_file),
                                    SizedBox(width: 8),
                                    Text(
                                      'Upload .txt File',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Results area - Now shows suggestions based on real-time typing
              if (_selectedFunctionality != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Container(
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Results header
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade300,
                                  Colors.blue.shade500
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.list_alt, color: Colors.white),
                                const SizedBox(width: 8),
                                const Text(
                                  'Results',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                if (_suggestionsLoading) ...[
                                  const SizedBox(width: 16),
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Results content
                          SizedBox(
                            height: 300,
                            child: _suggestionsLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : _suggestions.isNotEmpty
                                    ? ListView.builder(
                                        itemCount: _suggestions.length,
                                        itemBuilder: (context, index) {
                                          return _SuggestionItem(
                                            suggestion: _suggestions[index],
                                            onTap: () => _selectSuggestion(
                                                _suggestions[index]),
                                            onDownload: () =>
                                                _downloadSpeciesData(
                                                    _suggestions[index]),
                                            isLast: index ==
                                                _suggestions.length - 1,
                                            isDownloading: _isDownloading &&
                                                _downloadingItem ==
                                                    _suggestions[index],
                                          );
                                        },
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search,
                                              size: 60,
                                              color: Colors.blue.shade200,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _searchController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? 'Start typing to see suggestions'
                                                  : 'No suggestions found',
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
                  ),
                )
              else
                // Initial state guidance
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
                          'Search by Functional Description',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'For advanced level browsing, you can search by any functional feature description or any database ID (For example, COG ID, KEGG MODULE ID etc.) and you will get the species names which contain those functional features encoded in their genomes.',
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

              // Extra space at the bottom to prevent overflow
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate widget for suggestion items to improve performance
class _SuggestionItem extends StatelessWidget {
  final String suggestion;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final bool isLast;
  final bool isDownloading;

  const _SuggestionItem({
    required this.suggestion,
    required this.onTap,
    required this.onDownload,
    required this.isLast,
    required this.isDownloading,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          border: !isLast
              ? Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 0.5))
              : null,
        ),
        child: Row(
          children: [
            // Main suggestion content (tappable)
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 18,
                        color: Colors.blue.shade400,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Download button
            Container(
              padding: const EdgeInsets.only(right: 16),
              child: isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : IconButton(
                      onPressed: onDownload,
                      icon: Icon(
                        Icons.download,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      tooltip: 'Download species/genomes data',
                      splashRadius: 20,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
