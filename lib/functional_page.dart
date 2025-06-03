import 'package:flutter/material.dart';

class FunctionalPage extends StatefulWidget {
  const FunctionalPage({super.key});

  @override
  State<FunctionalPage> createState() => _FunctionalPageState();
}

class _FunctionalPageState extends State<FunctionalPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _inputController = TextEditingController();

  // Selected dropdown values for each dropdown
  final List<String?> _selectedValues = List.filled(8, null);

  // Search query result
  String _searchResult = '';
  bool _isSearching = false;

  // Mock categories and options for dropdowns
  final List<String> _dropdownTitles = [
    'Category',
    'Type',
    'Brand',
    'Model',
    'Year',
    'Color',
    'Size',
    'Price Range'
  ];

  // Mock options for each dropdown
  final List<List<String>> _dropdownOptions = [
    ['Electronics', 'Clothing', 'Home', 'Sports', 'Beauty'],
    ['New', 'Used', 'Refurbished'],
    ['Apple', 'Samsung', 'Sony', 'Nike', 'Adidas', 'IKEA'],
    ['Basic', 'Premium', 'Pro', 'Ultra'],
    ['2022', '2023', '2024', '2025'],
    ['Blue', 'Red', 'Green', 'Black', 'White'],
    ['Small', 'Medium', 'Large', 'X-Large'],
    ['\$0-\$50', '\$50-\$200', '\$200-\$500', '\$500+'],
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  void _performSearch() {
    setState(() {
      _isSearching = true;
    });

    // Simulate a database search operation
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isSearching = false;
        // Construct a result based on selected values and input
        final List<String> activeFilters = [];

        for (int i = 0; i < _selectedValues.length; i++) {
          if (_selectedValues[i] != null) {
            activeFilters.add('${_dropdownTitles[i]}: ${_selectedValues[i]}');
          }
        }

        String searchQuery = _searchController.text.trim();

        if (searchQuery.isNotEmpty) {
          _searchResult = 'Search results for "$searchQuery"';
          if (activeFilters.isNotEmpty) {
            _searchResult += ' with filters: ${activeFilters.join(', ')}';
          }

          if (_inputController.text.isNotEmpty) {
            _searchResult += '\nCustom input: ${_inputController.text}';
          }

          _searchResult += '\n\nFound 5 matching items.';
        } else if (activeFilters.isNotEmpty) {
          _searchResult = 'Filtered by: ${activeFilters.join(', ')}';
          if (_inputController.text.isNotEmpty) {
            _searchResult += '\nCustom input: ${_inputController.text}';
          }
          _searchResult += '\n\nFound 8 matching items.';
        } else {
          _searchResult = 'Please enter a search term or select filters';
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get arguments passed from the main page
    final Map<String, dynamic> args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {'title': 'Option', 'index': 1};

    final String title = args['title'] as String;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue.shade600,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onSubmitted: (_) => _performSearch(),
              ),
              const SizedBox(height: 16),

              // Dropdown menus in a grid
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Dropdowns
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 3.0,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: 8,
                        itemBuilder: (context, index) {
                          return _buildDropdown(index);
                        },
                      ),

                      const SizedBox(height: 24),

                      // Input field (shown when dropdown is selected)
                      if (_selectedValues.any((value) => value != null))
                        Column(
                          children: [
                            TextField(
                              controller: _inputController,
                              decoration: InputDecoration(
                                labelText: 'Enter details',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Search button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSearching ? null : _performSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isSearching
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Search',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Search results
                      if (_searchResult.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            _searchResult,
                            style: const TextStyle(fontSize: 16),
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
    );
  }

  Widget _buildDropdown(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButton<String>(
          value: _selectedValues[index],
          hint: Text(_dropdownTitles[index]),
          isExpanded: true,
          underline: Container(),
          icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
          onChanged: (String? newValue) {
            setState(() {
              _selectedValues[index] = newValue;
            });
          },
          items: _dropdownOptions[index]
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}
