import 'package:flutter/material.dart';

class AnnotationFilesPage extends StatefulWidget {
  const AnnotationFilesPage({Key? key}) : super(key: key);

  @override
  State<AnnotationFilesPage> createState() => _AnnotationFilesPageState();
}

class _AnnotationFilesPageState extends State<AnnotationFilesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFunctionality = 'Select Functionality';
  bool _speciesToggle = false;
  bool _genomesToggle = false;
  bool _dropdownOpen = false;

  // Functionality options for Annotation Files
  final List<String> _functionalityOptions = [
    'Select Functionality',
    'GFF',
    'GTF',
    'BED',
    'VCF',
    'BAM',
    'SAM',
    'FASTA',
    'FASTQ',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Text(
              'Database',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ' > ',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            Text(
              'Get Annotation Files',
              style: TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(
          color: Colors.blue,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Functionality selection row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Functionality:',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Dropdown button
                Expanded(
                  child: Stack(
                    children: [
                      // Dropdown field
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _dropdownOpen = !_dropdownOpen;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedFunctionality,
                                  style: TextStyle(
                                    color: _selectedFunctionality == 'Select Functionality'
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                Icon(
                                  _dropdownOpen
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Dropdown list
                      if (_dropdownOpen)
                        Positioned(
                          top: 50,
                          left: 0,
                          right: 0,
                          child: Card(
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                itemCount: _functionalityOptions.length,
                                itemBuilder: (context, index) {
                                  final option = _functionalityOptions[index];
                                  return ListTile(
                                    dense: true,
                                    title: Text(
                                      option,
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    leading: option == 'Select Functionality'
                                        ? const Icon(Icons.check, color: Colors.white)
                                        : null,
                                    onTap: () {
                                      setState(() {
                                        _selectedFunctionality = option;
                                        _dropdownOpen = false;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Toggle switches
                const Text(
                  'species',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Species toggle
                Switch(
                  value: _speciesToggle,
                  onChanged: (value) {
                    setState(() {
                      _speciesToggle = value;
                    });
                  },
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue.shade200,
                ),
                
                const SizedBox(width: 16),
                
                const Text(
                  'genomes',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                
                // Genomes toggle
                Switch(
                  value: _genomesToggle,
                  onChanged: (value) {
                    setState(() {
                      _genomesToggle = value;
                    });
                  },
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue.shade200,
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Search field and buttons row
            if (_selectedFunctionality != 'Select Functionality') 
              Row(
                children: [
                  // Search field
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.blue.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Enter the Organism Name...',
                          prefixIcon: Icon(Icons.search, color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  
                  // Search button
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Handle search
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Search'),
                  ),
                  
                  // OR text
                  const SizedBox(width: 16),
                  const Text(
                    'or',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  
                  // Upload button
                  ElevatedButton(
                    onPressed: () {
                      // Handle upload
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Upload .txt File'),
                  ),
                ],
              ),
            
            // Placeholder for results
            const Expanded(
              child: Center(
                child: Text(
                  'Select functionality and search for results',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}