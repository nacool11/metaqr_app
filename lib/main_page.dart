import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaPadding = MediaQuery.of(context).padding;
    final availableHeight = screenHeight -
        safeAreaPadding.top -
        safeAreaPadding.bottom -
        100; // Allow space for bottom navigation bar if present

    // Option titles - Removed Functionally-related species
    final List<String> optionTitles = [
      'QR Scanner',
      'Functional Feature Profiles',
      'Functional Annotation Files',
      'Functional Description or ID',
    ];

    // Option icons - Removed Functionally-related species
    final List<IconData> optionIcons = [
      Icons.qr_code_scanner,
      Icons.featured_play_list,
      Icons.file_copy,
      Icons.description,
    ];

    // Option colors - Removed Functionally-related species
    final List<Color> optionColors = [
      Colors.blue.shade400,
      Colors.indigo.shade300,
      Colors.lightBlue.shade300,
      Colors.cyan.shade300,
    ];

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
        title: const Text(
          'MiFRiX', // Changed to match the screenshot
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24, // Increased size to match screenshot
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(), // Prevent bouncing
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0,
              35.0), // Increased bottom padding to prevent overflow
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade100.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.dashboard_customize,
                              color: Colors.blue,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Select an option',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Choose from the available functional tools below:',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // First row: Feature Profiles and QR Scanner
              SizedBox(
                height: availableHeight *
                    0.38, // Increased height for better proportion
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Functional Feature Profiles - Larger card
                    Expanded(
                      flex: 3,
                      child: _buildFeatureCard(
                        context,
                        title: optionTitles[1],
                        icon: optionIcons[1],
                        color: optionColors[1],
                        route: '/feature_profiles',
                        titleFontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // QR Scanner - Smaller card with reduced padding
                    Expanded(
                      flex: 2,
                      child: _buildFeatureCard(
                        context,
                        title: optionTitles[0],
                        icon: optionIcons[0],
                        color: optionColors[0],
                        route: '/qr_scanner',
                        titleFontSize: 20,
                        compactLayout: true,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Second row: Annotation Files and Description/ID
              SizedBox(
                height: availableHeight *
                    0.38, // Increased height for better proportion
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Functional Annotation Files - First card
                    Expanded(
                      flex: 1,
                      child: _buildFeatureCard(
                        context,
                        title: optionTitles[2],
                        icon: optionIcons[2],
                        color: optionColors[2],
                        route: '/annotation_files',
                        titleFontSize: 18,
                        compactLayout: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Functional Description - Second card
                    Expanded(
                      flex: 1,
                      child: _buildFeatureCard(
                        context,
                        title: optionTitles[3],
                        icon: optionIcons[3],
                        color: optionColors[3],
                        route: '/description',
                        titleFontSize: 18,
                        compactLayout: true,
                      ),
                    ),
                  ],
                ),
              ),

              // Additional space at bottom to prevent overflow
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required String route,
    double titleFontSize = 20,
    bool compactLayout = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none, // Prevent overflow
          children: [
            // Background circles for decoration - positioned to avoid overflow
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: 20,
              top: 20,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),

            // Title and tap to view with adjusted padding for smaller cards
            Positioned(
              left: compactLayout ? 16 : 20,
              bottom: compactLayout ? 16 : 20,
              right: compactLayout
                  ? 8
                  : 16, // Reduced right padding for compact layout
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: titleFontSize,
                    ),
                    maxLines: 2, // Limit to 2 lines for long text
                    overflow: TextOverflow
                        .ellipsis, // Show ellipsis if text is too long
                  ),
                  const SizedBox(height: 6), // Reduced space for compact layout
                  const Row(
                    children: [
                      Text(
                        'Tap to view',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(width: 4), // Reduced space
                      Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 14, // Smaller icon
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
