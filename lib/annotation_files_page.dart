import 'package:blue_ui_app/dropdown.dart';
import 'package:flutter/material.dart';

class AnnotationFilesPage extends StatefulWidget {
  const AnnotationFilesPage({Key? key}) : super(key: key);

  @override
  State<AnnotationFilesPage> createState() => _AnnotationFilesPageState();
}

class _AnnotationFilesPageState extends State<AnnotationFilesPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFunctionality;
  bool toggle = false;
  final bool _dropdownOpen = false;

  // Functionality options for Annotation Files
  final List<String> _functionalityOptions = [
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

                        // Dropdown button
                        // Dropdown button
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

                        // Custom Toggle Switch for genomes
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                toggle = !toggle;
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
                        const Text(
                          'genomes',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 50),

              // Second card - showing select functionality message
              if (_selectedFunctionality == null)
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
                        textAlign: TextAlign.center,
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
              if (_selectedFunctionality != null)
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
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
