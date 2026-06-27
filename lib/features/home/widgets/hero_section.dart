// import 'package:flutter/material.dart';

// import '../../../core/constants/app_colors.dart';

// class HeroSection extends StatelessWidget {
//   const HeroSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(
//         horizontal: 24,
//         vertical: 40,
//       ),
//       decoration: const BoxDecoration(
//         color: AppColors.primary,
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Welcome to\nKMC Alumni Connect",
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 32,
//               fontWeight: FontWeight.bold,
//               height: 1.3,
//             ),
//           ),

//           const SizedBox(height: 16),

//           const Text(
//             "Connecting alumni, students, and faculty through one unified platform.",
//             style: TextStyle(
//               color: Colors.white70,
//               fontSize: 16,
//               height: 1.6,
//             ),
//           ),

//           const SizedBox(height: 30),

//           ElevatedButton(
//             onPressed: () {},
//             style: ElevatedButton.styleFrom(
//               backgroundColor: AppColors.secondary,
//               foregroundColor: Colors.white,
//               padding: const EdgeInsets.symmetric(
//                 horizontal: 30,
//                 vertical: 16,
//               ),
//             ),
//             child: const Text("Explore"),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 700,
      width: double.infinity,
      child: Stack(
        children: [

          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Dark Overlay
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.55),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 30),

                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white24,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Icon(
                        Icons.auto_awesome,
                        color: Colors.orange,
                        size: 18,
                      ),

                      SizedBox(width: 8),

                      Text(
                        "Kakatiya Medical College • ESTD 1959",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 35),

                // Title
                RichText(
                  text: TextSpan(
                    children: [

                      TextSpan(
                        text: "KMC ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width < 600 ? 56 : 70,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),

                      TextSpan(
                        text: "Alumni",
                        style: TextStyle(
                          backgroundColor: Colors.orange,
                          color: Colors.white,
                          fontSize: width < 600 ? 56 : 70,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),

                      TextSpan(
                        text: "\nConnect",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width < 600 ? 56 : 70,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                const Text(
                  "Connecting generations of medical excellence.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 25),

                const SizedBox(
                  width: 600,
                  child: Text(
                    "The official alumni engagement platform for Kakatiya Medical College, Warangal — uniting alumni batches, doctors, researchers, practicing doctors, clinical researchers, policy makers and pharmaceutical industry advisors across the world.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      height: 1.7,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Wrap(
                  spacing: 20,
                  runSpacing: 15,
                  children: [

                    ElevatedButton.icon(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xff132B59),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text(
                        "Join Alumni Network",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Colors.white54,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                      child: const Text(
                        "Explore Platform",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}