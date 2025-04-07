import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  String? _scanResult;
  bool _hasPermission = true;
  bool _hasLaunched = false; // Track if we've already launched a URL
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    _hasLaunched = false; // Reset flag when disposed
    super.dispose();
  }

  // Function to launch URL
  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
              'QR Scanner',
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
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.torchState,
              builder: (context, state, child) {
                switch (state as TorchState) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.white);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state as CameraFacing) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front, color: Colors.white);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear, color: Colors.white);
                }
              },
            ),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scanner area
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: _hasPermission
                  ? Stack(
                      children: [
                        // Camera view
                        MobileScanner(
                          controller: controller,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            for (final barcode in barcodes) {
                              // Set the scan result text
                              setState(() {
                                _scanResult = barcode.rawValue;
                              });
                              
                              // If it's a URL, automatically launch it
                              if (!_hasLaunched && barcode.rawValue != null && 
                                  (barcode.rawValue!.startsWith('http://') || 
                                   barcode.rawValue!.startsWith('https://'))) {
                                setState(() {
                                  _hasLaunched = true; // Set flag to prevent multiple launches
                                });
                                
                                // Pause the scanner to prevent further scanning
                                controller.stop();
                                
                                // Launch the URL directly
                                _launchURL(barcode.rawValue!);
                              }
                            }
                          },
                        ),
                        
                        // Scanner overlay
                        Center(
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.blue,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        
                        // Instruction text
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'Position the QR code in the scanner frame',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.no_photography,
                              size: 60,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Camera permission denied',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              controller.start();
                              setState(() {
                                _hasPermission = true;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text('Request Permission'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          
          // Results section
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Result',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Center(
                    child: _scanResult != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Scanned QR Code:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _scanResult!,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              if (_hasLaunched && (_scanResult!.startsWith('http://') || 
                                  _scanResult!.startsWith('https://')))
                                const Text(
                                  'Opening link in browser...',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Copy to clipboard
                                      if (_scanResult != null) {
                                        Clipboard.setData(ClipboardData(text: _scanResult!));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Copied to clipboard'),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.copy),
                                    label: const Text('Copy'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Reset scanner and scan again
                                      setState(() {
                                        _scanResult = null;
                                        _hasLaunched = false;
                                      });
                                      controller.start();
                                    },
                                    icon: const Icon(Icons.qr_code_scanner),
                                    label: const Text('Scan Again'),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Text(
                                'No QR code detected yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}