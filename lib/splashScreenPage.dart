import 'dart:async';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const SplashScreen({super.key, required this.onFinish});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> teamMembers = [
    {
      'name': 'Diera Syafira Parinissa',
      'nim': '101012340096',
      'image': 'assets/stev.jpg',
    },
    {
      'name': 'Citra Kusumadewi Sribawono',
      'nim': '101012340196',
      'image': 'assets/stev.jpg',
    },
    {
      'name': 'Aulia Rahma',
    'nim': '101012340340',
    'image': 'assets/stev.jpg'
    },
    {
      'name': 'Stevannie Pratama',
      'nim': '101012340343',
      'image': 'assets/stev.jpg',
    },
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
    Timer(const Duration(seconds: 10), widget.onFinish);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        height: screenHeight,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFBF8F3), Color(0xFFFFF8DC), Color(0xFFD7CCC8)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // LOGO
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8D6E63).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bakery_dining ,
                        size: 40,
                        color: Color(0xFF8D6E63),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Luxelle Bakery',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Meet Our Expert Team',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6D4C41)),
                    ),

                    const SizedBox(height: 40),

                    // TEAM GRID
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: teamMembers.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 4,
                            crossAxisSpacing: 4,
                            childAspectRatio: 1.25,
                          ),
                      itemBuilder: (context, index) {
                        final member = teamMembers[index];
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: const Color(
                                0xFF8D6E63,
                              ).withOpacity(0.2),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundImage: AssetImage(member['image']!),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              member['name']!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF3E2723),
                              ),
                            ),
                            Text(
                              member['nim']!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF6D4C41),
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'GROUP 1',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6D4C41),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // LOADING BAR
                    SizedBox(
                      width: 160,
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: Color(0xFFEFEBE9),
                        valueColor: AlwaysStoppedAnimation(Color(0xFF8D6E63)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
