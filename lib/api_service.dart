import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
// import 'package:dio_logger/dio_logger.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.16.203:8000';
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    headers: {"Content-Type": "application/json"},
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))..interceptors.add(PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        responseHeader: false,
        error: true,
        compact: true,
        maxWidth: 90,
        enabled: kDebugMode,
        filter: (options, args){
            // don't print requests with uris containing '/posts' 
            if(options.path.contains('/posts')){
              return false;
            }
            // don't print responses with unit8 list data
            return !args.isResponse || !args.hasUint8ListData;
          }
      ));

  // POST: /getGenomeIDs
  static Future<dynamic> getGenomeIDs(List<String> data) => _postRequest('/getGenomeIDs', data);

  // POST: /annotationZip
  static Future<dynamic> getAnnotationZip(Map<String, dynamic> data) => _postRequest('/annotationZip', data);

  // POST: /getFuncMatrixFile
  static Future<dynamic> getFuncMatrixFile(Map<String, dynamic> data) => _postRequest('/getFuncMatrixFile', data);

  // GET: /getExactFuncMatches
  static Future<dynamic> getExactFuncMatches() => _getRequest('/getExactFuncMatches');

  // GET: /getMMFile
  static Future<dynamic> getMMFile() => _getRequest('/getMMFile');

  // GET: /getSpeciesAnalysisHtmls
  static Future<dynamic> getSpeciesAnalysisHtmls() => _getRequest('/getSpeciesAnalysisHtmls');

  // GET: /getAnalysisZip
  static Future<dynamic> getAnalysisZip() => _getRequest('/getAnalysisZip');

  // GET: /getDescriptionName
  static Future<dynamic> getDescriptionName() => _getRequest('/getDescriptionName');

  // POST: /getSpeciesNamesFromDescriptions
  static Future<dynamic> getSpeciesNamesFromDescriptions(Map<String, dynamic> data) => _postRequest('/getSpeciesNamesFromDescriptions', data);

  // POST: /getSpeciesNNFile
  static Future<dynamic> getSpeciesNNFile(Map<String, dynamic> data) => _postRequest('/getSpeciesNNFile', data);

  // POST: /mlPipeline
  static Future<dynamic> mlPipeline(Map<String, dynamic> data) => _postRequest('/mlPipeline', data);

  // GET: /results/{job_id}/sampleid_list
  static Future<dynamic> getSampleIdList(String jobId) => _getRequest('/results/$jobId/sampleid_list');

  // GET: /results/{job_id}/{sample_id}/
  static Future<dynamic> getSamplePage(String jobId, String sampleId) => _getRequest('/results/$jobId/$sampleId/');

  // GET: /results/{job_id}/{sample_id}/download
  static Future<dynamic> downloadZip(String jobId, String sampleId) => _getRequest('/results/$jobId/$sampleId/download');

  // GET: /
  static Future<dynamic> getRoot() => _getRequest('/');

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
}