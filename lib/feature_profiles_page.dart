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
  final bool _dropdownOpen = false;

  List<String> genomResponse = ["ho", "by"];

  // Functionality options based on the provided list
  final List<String> _functionalityOptions = [
    'CAZy',
    'COG',
    'BiGG',
    'KEGG Module',
    'KEGG Orthologs',
    'KEGG Reactions',
    'EC Number',
    'PFAMs',
    'Combined',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool genomeLoading = false;

  Future<void> _searchGenomeIDs() async {
    genomeLoading = true;
    setState(() {});
    final organismName = _searchController.text.trim();

    if (organismName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an organism name")),
      );
      return;
    }

    try {
      final payload = [organismName]; // or reorder based on backend requirement
      final response = await ApiService.getGenomeIDs(payload);

      final dataList = response['absicoccus_porci'];

      genomResponse =
          List<String>.from(dataList.map((item) => item.toString()));

      print("API Response: $response");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Found \${response.length} results.")),
      );
    } catch (e) {
      print("API error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error fetching genome IDs")),
      );
    }

    genomeLoading = false;
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
                        const Text(
                          'species',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                          ),
                        ),
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
                      const Text(
                        'Get Functional Feature Profiles',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Here you will get the the mean derived detection profiles in species-level as well as functional profiles in strain-level. You will have the option to download the profiles for different functional categories like COG, CAZy, BiGG etc.',
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
              if (_selectedFunctionality != null)
                Column(
                  children: [
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
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (toggle == true) {
                                _searchGenomeIDs();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Switch to 'genomes' to search.")),
                                );
                              }
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
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
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
                    const SizedBox(height: 30),
                    genomeLoading
                        ? CircularProgressIndicator()
                        : ListView.separated(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: genomResponse.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                // leading: const Icon(Icons.label),
                                title: Text(genomResponse[index]),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const Divider(),
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
