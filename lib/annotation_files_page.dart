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
              'Get Annotation Files',
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
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First card - with functionality dropdown and toggles
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
                    // Functionality selector row
                    Row(
                      children: [
                        // Functionality label with blue background
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                        
                        // Dropdown button
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Stack(
                              children: [
                                // Dropdown field
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _dropdownOpen = !_dropdownOpen;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(30),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                            Icons.arrow_drop_down,
                                            color: Colors.blue.shade300,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Dropdown menu
                                if (_dropdownOpen)
                                  Positioned(
                                    top: 45,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade800,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
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
                                            selected: option == _selectedFunctionality,
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
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Toggle switches row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Species toggle
                        const Text(
                          'species',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                        
                        // Custom Toggle Switch for species
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _speciesToggle = !_speciesToggle;
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: _speciesToggle 
                                    ? Colors.blue.shade200 
                                    : Colors.grey.shade300,
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
                                    left: _speciesToggle ? 22 : 0,
                                    right: _speciesToggle ? 0 : 22,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _speciesToggle 
                                            ? Colors.blue.shade600 
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 24),
                        
                        // Genomes toggle
                        const Text(
                          'genomes',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                        
                        // Custom Toggle Switch for genomes
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _genomesToggle = !_genomesToggle;
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                color: _genomesToggle 
                                    ? Colors.blue.shade200 
                                    : Colors.grey.shade300,
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
                                    left: _genomesToggle ? 22 : 0,
                                    right: _genomesToggle ? 0 : 22,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _genomesToggle 
                                            ? Colors.blue.shade600 
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Second card - showing select functionality message
              if (_selectedFunctionality == 'Select Functionality')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
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
                      // Document icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.article_outlined,
                            size: 40,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Select a Functionality text
                      const Text(
                        'Get Functional Annotation Files',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Instruction text
                      Text(
                        'You can download functional annotation files in .tsv file format by searching organism name in the species-level. To make it user friendly, you will have the option to select species as well as strains for downloading.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Search field and buttons (shown when functionality is selected)
              if (_selectedFunctionality != 'Select Functionality') 
                Column(
                  children: [
                    // Search field
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.blue.shade300),
                        color: Colors.white,
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
                    
                    const SizedBox(height: 20),
                    
                    // Buttons row 
                    Row(
                      children: [
                        // Search button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle search
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Search'),
                          ),
                        ),
                        
                        // OR text
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        
                        // Upload button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle upload
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Upload .txt File'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}