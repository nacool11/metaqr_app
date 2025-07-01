import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
// import 'package:dio_logger/dio_logger.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.3.133:8000';
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {"Content-Type": "application/json"},
    connectTimeout:
        const Duration(seconds: 30), // Increased timeout for downloads
    receiveTimeout:
        const Duration(seconds: 60), // Increased timeout for downloads
  ))
    ..interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: false, // Don't log response body for large files
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
        enabled: kDebugMode,
        filter: (options, args) {
          // don't print requests with uris containing '/posts'
          if (options.path.contains('/posts')) {
            return false;
          }
          // don't print responses with unit8 list data
          return !args.isResponse || !args.hasUint8ListData;
        }));

  // POST: /getGenomeIDs
  static Future<dynamic> getGenomeIDs(List<String> data) =>
      _postRequest('/getGenomeIDs', data);

  // POST: /annotationZip
  static Future<dynamic> getAnnotationZip(Map<String, dynamic> data) =>
      _postRequest('/annotationZip', data);

  // GET: /getExactFuncMatches
  static Future<dynamic> getExactFuncMatches() =>
      _getRequest('/getExactFuncMatches');

  // GET: /getMMFile
  static Future<dynamic> getMMFile() => _getRequest('/getMMFile');

  // GET: /getSpeciesAnalysisHtmls
  static Future<dynamic> getSpeciesAnalysisHtmls() =>
      _getRequest('/getSpeciesAnalysisHtmls');

  // GET: /getAnalysisZip
  static Future<dynamic> getAnalysisZip() => _getRequest('/getAnalysisZip');

  // GET: /getDescriptionName
  static Future<dynamic> getDescriptionName() =>
      _getRequest('/getDescriptionName');

  // POST: /getSpeciesNamesFromDescriptions
  // Updated to match the actual API specification
  static Future<dynamic> getSpeciesNamesFromDescriptions(
          List<String> descriptions) =>
      _postRequest('/getSpeciesNamesFromDescriptions', descriptions);

  // POST: /getSpeciesNNFile
  static Future<dynamic> getSpeciesNNFile(Map<String, dynamic> data) =>
      _postRequest('/getSpeciesNNFile', data);

  // POST: /mlPipeline
  static Future<dynamic> mlPipeline(Map<String, dynamic> data) =>
      _postRequest('/mlPipeline', data);

  // GET: /results/{job_id}/sampleid_list
  static Future<dynamic> getSampleIdList(String jobId) =>
      _getRequest('/results/$jobId/sampleid_list');

  // GET: /results/{job_id}/{sample_id}/
  static Future<dynamic> getSamplePage(String jobId, String sampleId) =>
      _getRequest('/results/$jobId/$sampleId/');

  // GET: /results/{job_id}/{sample_id}/download
  static Future<dynamic> downloadZip(String jobId, String sampleId) =>
      _getRequest('/results/$jobId/$sampleId/download');

  // GET: /
  static Future<dynamic> getRoot() => _getRequest('/');

  static Future<List<String>> getDescriptionSuggestions(String descName) async {
    try {
      final url = Uri.parse('$baseUrl/getDescriptionName?desc_name=$descName');

      print('Making API call to: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Extract the closest_desc_name array from the response
        if (jsonResponse.containsKey('closest_desc_name') &&
            jsonResponse['closest_desc_name'] is List) {
          final List<dynamic> suggestions = jsonResponse['closest_desc_name'];

          // Convert to List<String> and filter out any null or empty values
          return suggestions
              .where(
                  (item) => item != null && item.toString().trim().isNotEmpty)
              .map((item) => item.toString().trim())
              .toList();
        } else {
          print('Invalid response format: missing closest_desc_name array');
          return [];
        }
      } else {
        print('API call failed with status code: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error in getDescriptionSuggestions: $e');
      return [];
    }
  }

  // NEW: GET fuzzy search suggestions for species
  static Future<List<String>> getFuzzySearchSuggestions(String prefix) async {
    try {
      print('Making API call to: $baseUrl/autocompleteSpecies?prefix=$prefix');
      final response = await _dio.get(
        '/autocompleteSpecies',
        queryParameters: {'prefix': prefix},
      );

      print('API Response: ${response.data}');

      // Assuming the API returns: {"suggestions": ["species1", "species2"]}
      if (response.data is Map<String, dynamic> &&
          response.data['suggestions'] is List) {
        final suggestions = List<String>.from(response.data['suggestions']);
        print('Parsed suggestions: $suggestions');
        return suggestions;
      }
      print('Invalid response format: ${response.data}');
      return [];
    } catch (e) {
      print('Error in getFuzzySearchSuggestions: $e');
      // Return empty list on error to avoid breaking the UI
      return [];
    }
  }

  // Generic POST request handler
  static Future<dynamic> _postRequest(String endpoint, dynamic data) async {
    try {
      final response = await _dio.post(endpoint, data: data);
      return response.data;
    } catch (e) {
      throw Exception('POST $endpoint failed: $e');
    }
  }

  // Generic GET request handler
  static Future<dynamic> _getRequest(String endpoint) async {
    try {
      final response = await _dio.get(endpoint);
      return response.data;
    } catch (e) {
      throw Exception('GET $endpoint failed: $e');
    }
  }

  static Future<dynamic> getFuncMatrixFile(
    List<String> data,
    String funcType,
    String taxanomy,
  ) async {
    try {
      final response = await _dio.post(
        '/getFuncMatrixFile',
        data: data,
        queryParameters: {
          'func_type': funcType,
          'taxanomy': taxanomy,
        },
      );
      return response.data;
    } catch (e) {
      throw Exception('POST /getFuncMatrixFile failed: $e');
    }
  }

  // NEW: Download full functional matrix file
  static Future<Uint8List> downloadGenomeFuncMatrixFull(
    List<String> data,
    String funcType,
  ) async {
    try {
      print(
          'Downloading full functional matrix for: $data with func_type: $funcType');

      final response = await _dio.post<List<int>>(
        '/getGenomeFuncMatrixFull',
        data: data,
        queryParameters: {
          'func_type': funcType,
        },
        options: Options(
          responseType:
              ResponseType.bytes, // Important: specify bytes response type
          headers: {
            'accept': '*/*',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Convert List<int> to Uint8List
        final bytes = Uint8List.fromList(response.data!);
        print('Download completed successfully. Size: ${bytes.length} bytes');
        return bytes;
      } else {
        throw Exception(
            'Failed to download functional matrix: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error in downloadGenomeFuncMatrixFull: $e');
      if (e is DioException) {
        print('DioException details: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status code: ${e.response?.statusCode}');
      }
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  // Main download method using Dio for better error handling and progress tracking
  static Future<Uint8List> downloadAnnotationZip(List<String> genomeIds) async {
    try {
      print('Downloading annotation zip for genome IDs: $genomeIds');

      final response = await _dio.post<List<int>>(
        '/annotationZip',
        data: genomeIds,
        options: Options(
            responseType:
                ResponseType.bytes, // Important: specify bytes response type
            headers: {
              "Content-Type": "application/json",
              "Accept": "*/*",
            }),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Convert List<int> to Uint8List
        final bytes = Uint8List.fromList(response.data!);
        print('Download completed successfully. Size: ${bytes.length} bytes');
        return bytes;
      } else {
        throw Exception('Failed to download zip: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Error in downloadAnnotationZip: $e');
      if (e is DioException) {
        print('DioException details: ${e.message}');
        print('Response data: ${e.response?.data}');
        print('Response status code: ${e.response?.statusCode}');
      }
      throw Exception('Download failed: ${e.toString()}');
    }
  }

  // Fallback HTTP method (keeping for compatibility)
  static Future<Uint8List> downloadAnnotationZipHttp(
      List<String> genomeIds) async {
    try {
      print('Downloading annotation zip via HTTP for genome IDs: $genomeIds');

      final uri = Uri.parse('$baseUrl/annotationZip');
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Accept": "*/*",
        },
        body: jsonEncode(genomeIds),
      );

      print('HTTP Response status: ${response.statusCode}');
      print('HTTP Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        print(
            'Download completed successfully. Size: ${response.bodyBytes.length} bytes');
        return response.bodyBytes;
      } else {
        print('HTTP Response body: ${response.body}');
        throw Exception(
            'Failed to download zip: HTTP ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e) {
      print('Error in downloadAnnotationZipHttp: $e');
      throw Exception('HTTP download failed: ${e.toString()}');
    }
  }

  // Test method to verify the API endpoint is working
  static Future<bool> testAnnotationZipEndpoint(List<String> genomeIds) async {
    try {
      final uri = Uri.parse('$baseUrl/annotationZip');
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(genomeIds),
      );

      print('Test response status: ${response.statusCode}');
      print('Test response headers: ${response.headers}');
      print('Test response body length: ${response.bodyBytes.length}');

      return response.statusCode == 200;
    } catch (e) {
      print('Test failed: $e');
      return false;
    }
  }
}
