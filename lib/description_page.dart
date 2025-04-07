import 'package:flutter/material.dart';

class DescriptionPage extends StatefulWidget {
  const DescriptionPage({Key? key}) : super(key: key);

  @override
  State<DescriptionPage> createState() => _DescriptionPageState();
}

class _DescriptionPageState extends State<DescriptionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFunctionality = 'Select Functionality';
  bool _speciesToggle = false;
  bool _genomesToggle = false;
  bool _dropdownOpen = false;

  // Functionality options for Description/ID
  final List<String> _functionalityOptions = [
    'Select Functionality',
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
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 30.0), // Extra bottom padding
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.blue.shade50],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
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
                                                : Colors.blue.shade700,
                                            fontWeight: _selectedFunctionality == 'Select Functionality'
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _dropdownOpen
                                                ? Icons.keyboard_arrow_up
                                                : Icons.keyboard_arrow_down,
                                            color: Colors.blue.shade700,
                                            size: 18,
                                          ),
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
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.blue.shade700, Colors.indigo.shade800],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        padding: EdgeInsets.zero,
                                        itemCount: _functionalityOptions.length,
                                        itemBuilder: (context, index) {
                                          final option = _functionalityOptions[index];
                                          return Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: option == _selectedFunctionality 
                                                  ? Colors.blue.shade400.withOpacity(0.3)
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: ListTile(
                                              dense: true,
                                              title: Text(
                                                option,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: option == _selectedFunctionality 
                                                      ? FontWeight.bold 
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                              leading: option == _selectedFunctionality
                                                  ? const Icon(Icons.check_circle, color: Colors.white)
                                                  : null,
                                              onTap: () {
                                                setState(() {
                                                  _selectedFunctionality = option;
                                                  _dropdownOpen = false;
                                                });
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Toggle switches
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Search field and buttons row
              if (_selectedFunctionality != 'Select Functionality') 
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
                            decoration: InputDecoration(
                              hintText: 'Enter ID or description keywords...',
                              prefixIcon: Icon(Icons.search, color: Colors.blue.shade400),
                              suffixIcon: _searchController.text.isNotEmpty 
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      color: Colors.blue.shade400,
                                      onPressed: () {
                                        _searchController.clear();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                            ),
                          ),
                        ),
                      ),
                      
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                        child: Row(
                          children: [
                            // Search button
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle search
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade500,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                onPressed: () {
                                  // Handle upload
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyan.shade400,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
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
              
              // Results area
              if (_selectedFunctionality != 'Select Functionality')
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade300, Colors.blue.shade500],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.list_alt, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Results',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Results content (placeholder)
                          SizedBox(
                            height: 200, // Fixed height for placeholder
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 60,
                                    color: Colors.blue.shade200,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Enter search criteria to find results',
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