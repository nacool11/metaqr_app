import 'package:flutter/material.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Option titles
    final List<String> optionTitles = [
      'QR Scanner',
      'Functional Feature Profiles',
      'Functional Annotation Files',
      'Functional Description or ID',
      'Functionally-related species',
    ];

    // Option icons
    final List<IconData> optionIcons = [
      Icons.qr_code_scanner,
      Icons.featured_play_list,
      Icons.file_copy,
      Icons.description,
      Icons.category,
    ];
    
    // Option colors - pastel blue tones
    final List<Color> optionColors = [
      Colors.blue.shade400,
      Colors.indigo.shade300,
      Colors.lightBlue.shade300,
      Colors.cyan.shade400,
      Colors.blue.shade300,
    ];

    // Background gradients for buttons
    final List<List<Color>> gradients = [
      [Colors.blue.shade300, Colors.blue.shade500],
      [Colors.indigo.shade200, Colors.indigo.shade400],
      [Colors.lightBlue.shade200, Colors.lightBlue.shade400],
      [Colors.cyan.shade300, Colors.cyan.shade500],
      [Colors.blue.shade200, Colors.blue.shade400],
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade400, Colors.blue.shade700],
            ),
          ),
        ),
        title: const Text(
          'Functional Database',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome section
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.dashboard_customize,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                'Select an option',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
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
                
                // Option cards with different sizes and placements
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Row(
                          children: [
                            // Feature Profiles - Larger card
                            Expanded(
                              flex: 3,
                              child: _buildFeatureCard(
                                context,
                                title: optionTitles[1],
                                icon: optionIcons[1],
                                gradient: gradients[1],
                                index: 1,
                                height: 180,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // QR Scanner - Smaller card
                            Expanded(
                              flex: 2,
                              child: _buildFeatureCard(
                                context,
                                title: optionTitles[0],
                                icon: optionIcons[0],
                                gradient: gradients[0],
                                index: 0,
                                height: 180,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 16),
                      ),
                      SliverToBoxAdapter(
                        child: Row(
                          children: [
                            // Annotation Files - Medium card
                            Expanded(
                              flex: 1,
                              child: _buildFeatureCard(
                                context,
                                title: optionTitles[2],
                                icon: optionIcons[2],
                                gradient: gradients[2],
                                index: 2,
                                height: 150,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 16),
                      ),
                      SliverToBoxAdapter(
                        child: Row(
                          children: [
                            // Description/ID - Small card
                            Expanded(
                              flex: 2,
                              child: _buildFeatureCard(
                                context,
                                title: optionTitles[3],
                                icon: optionIcons[3],
                                gradient: gradients[3],
                                index: 3,
                                height: 140,
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Related Species - Medium card
                            Expanded(
                              flex: 3,
                              child: _buildFeatureCard(
                                context,
                                title: optionTitles[4],
                                icon: optionIcons[4],
                                gradient: gradients[4],
                                index: 4,
                                height: 140,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required int index,
    required double height,
  }) {
    return GestureDetector(
      onTap: () {
        // Navigate to the appropriate page based on button index
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/qr_scanner');
            break;
          case 1:
            Navigator.pushNamed(context, '/feature_profiles');
            break;
          case 2:
            Navigator.pushNamed(context, '/annotation_files');
            break;
          case 3:
            Navigator.pushNamed(context, '/description');
            break;
          case 4:
            Navigator.pushNamed(context, '/related_species');
            break;
        }
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          boxShadow: [
            BoxShadow(
              color: gradient[0].withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background design elements
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
              left: -10,
              top: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon with circle background
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  
                  // Tap to view
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Tap to view',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: Colors.white.withOpacity(0.8),
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