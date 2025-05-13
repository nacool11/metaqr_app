import 'dart:io';

import 'package:blue_ui_app/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> _searchGenomeIDs() async {
    final rawOrganismName = _searchController.text.trim();
    if (rawOrganismName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an organism name")),
      );
      return;
    }

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

    try {
      final zipBytes =
          await ApiService.downloadAnnotationZipHttp(selectedGenomeIds.toList());
          
      final uri = Uri.parse('http://192.168.16.203:8000/annotationZip');
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(selectedGenomeIds.toList()),
    );

    if (response.statusCode != 200) {
      throw Exception("Server error ${response.statusCode}");
    }

    // Get Downloads directory path
    final downloadsDir = Directory('/storage/emulated/0/Download');
    final file = File('${downloadsDir.path}/annotations.zip');
    await file.writeAsBytes(response.bodyBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to ${file.path}')),
    );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [Colors.blue.shade500, Colors.blue.shade700]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: const [
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
          Expanded(flex: 4, child: Text(_searchController.text.trim())),
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
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Enter Organism Name',
                      border: OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _searchGenomeIDs,
                  child: const Text("Search"),
                ),
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
                        ElevatedButton.icon(
                          onPressed: _downloadSelectedFiles,
                          icon: const Icon(Icons.download),
                          label: const Text(""),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                          ),
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
              const Text("No results found."),
          ],
        ),
      ),
    );
  }
}
