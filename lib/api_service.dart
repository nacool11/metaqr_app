import 'dart:convert';

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
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))
    ..interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
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
  static Future<dynamic> getSpeciesNamesFromDescriptions(
          Map<String, dynamic> data) =>
      _postRequest('/getSpeciesNamesFromDescriptions', data);

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

  // Downloads ZIP from selected genome IDs
  static Future<List<int>> downloadAnnotationZip(List<String> genomeIds) async {
    try {
      final response = await _dio.post<List<int>>(
        '/annotationZip',
        data: genomeIds,
        options: Options(
          // responseType: ResponseType.,
          headers: {
            "Content-Type": "application/json",
          },
        ),
      );
      return response.data!;
    } catch (e) {
      throw Exception('POST /annotationZip download failed: $e');
    }
  }

  static Future<Uint8List> downloadAnnotationZipHttp(
      List<String> genomeIds) async {
    try {
      final uri = Uri.parse('$baseUrl/annotationZip');
      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(genomeIds),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception('Failed to download zip: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('HTTP error: $e');
    }
  }
}
