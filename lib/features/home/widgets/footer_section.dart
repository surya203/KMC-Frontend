// import 'package:flutter/material.dart';

// class FooterSection extends StatelessWidget {
//   const FooterSection({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       color: const Color(0xff12284A),
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.symmetric(
//               horizontal: 80,
//               vertical: 60,
//             ),
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// LEFT
//                 Expanded(
//                   flex: 3,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Image.asset(
//                             "assets/images/kmc-logo.png",
//                             height: 54,
//                             width: 54,
//                             fit: BoxFit.contain,
//                           ),
//                           const SizedBox(width: 16),
//                           Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: const [
//                               Text(
//                                 "KMC Alumni Connect",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 27,
//                                 //   fontWeight: FontWeight.bold,
//                                 fontWeight: FontWeight.w700,
//                                   fontFamily: "Georgia",
//                                 ),
//                               ),
//                               SizedBox(height: 4),
//                               Text(
//                                 "ESTD. 1959 • WARANGAL",
//                                 style: TextStyle(
//                                   color: Color(0xffB7C0D1),
//                                   letterSpacing: 2,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 32),
//                       const SizedBox(
//                         width: 520,
//                         child: Text(
//                           "The official alumni engagement platform for Kakatiya Medical College — uniting alumni batches, doctors, researchers, practicing doctors, clinical researchers, policy makers and pharmaceutical industry advisors across the world.",
//                           style: TextStyle(
//                             color: Color(0xffD4D9E2),
//                             fontSize: 18,
//                             height: 1.9,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(width: 120),

//                 /// CENTER
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "EXPLORE",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700,
//                           fontFamily: "Georgia",
//                         ),
//                       ),
//                       const SizedBox(height: 30),
//                       footerLink("About"),
//                       footerLink("Events"),
//                       footerLink("Gallery"),
//                       footerLink("MY KMC"),
//                     ],
//                   ),
//                 ),

//                 // const SizedBox(width: 100),

//                 /// RIGHT
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: const [
//                       Text(
//                         "OFFICE",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold,
//                           fontFamily: "Georgia",
//                         ),
//                       ),
//                       SizedBox(height: 30),
//                       FooterInfo(
//                         "Kakatiya Medical College",
//                       ),
//                       SizedBox(height: 12),
//                       FooterInfo(
//                         "Rangampet, Warangal — 506007",
//                       ),
//                       SizedBox(height: 12),
//                       FooterInfo(
//                         "alumni@kmc.edu.in",
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           Container(
//             height: 1,
//             color: Colors.white.withOpacity(.12),
//           ),

//             Padding(
//             padding: const EdgeInsets.fromLTRB(
//                 24,
//                 56,
//                 24,
//                 48,
//             ),
//             child: Row(
//               children: const [
//                 Text(
//                   "© 2026 KMC Alumni Association. All rights reserved.",
//                   style: TextStyle(
//                     color: Color(0xffAEB8C7),
//                     fontSize: 17,
//                   ),
//                 ),
//                 Spacer(),
//                 Text(
//                   "Official Platform • Estd. 1959",
//                   style: TextStyle(
//                     color: Color(0xffAEB8C7),
//                     fontSize: 17,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   static Widget footerLink(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 18),
//       child: Text(
//         title,
//         style: const TextStyle(
//           color: Color(0xffD6DCE7),
//           fontSize: 16,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }
// }

// class FooterInfo extends StatelessWidget {
//   final String text;

//   const FooterInfo(this.text, {super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       text,
//       style: const TextStyle(
//         color: Color(0xffD6DCE7),
//         fontSize: 18,
//         height: 1.6,
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF12284A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 55, 60, 45),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 560,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/kmc-logo.png",
                            width: 52,
                            height: 52,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 18),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "KMC Alumni Connect",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: "Georgia",
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "ESTD. 1959 • WARANGAL",
                                style: TextStyle(
                                  color: Color(0xFFB7C0D1),
                                  fontSize: 13,
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      const SizedBox(
                        width: 520,
                        child: Text(
                          "The official alumni engagement platform for Kakatiya Medical College — connecting alumni, doctors, researchers, academicians and healthcare leaders across the globe.",
                          style: TextStyle(
                            color: Color(0xFFD8DEE8),
                            fontSize: 16,
                            height: 1.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "EXPLORE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Georgia",
                        ),
                      ),
                      const SizedBox(height: 26),
                      footerLink("About"),
                      footerLink("Events"),
                      footerLink("Gallery"),
                      footerLink("MY KMC"),
                    ],
                  ),
                ),

                const SizedBox(width: 90),

                SizedBox(
                  width: 300,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "OFFICE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Georgia",
                        ),
                      ),
                      SizedBox(height: 26),

                      FooterInfo(
                        "Kakatiya Medical College",
                      ),

                      SizedBox(height: 10),

                      FooterInfo(
                        "Rangampet,\nWarangal - 506007",
                      ),

                      SizedBox(height: 10),

                      FooterInfo(
                        "alumni@kmc.edu.in",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            height: 1,
            color: Colors.white12,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 60,
              vertical: 18,
            ),
            child: Row(
              children: const [
                Text(
                  "© 2026 KMC Alumni Association. All rights reserved.",
                  style: TextStyle(
                    color: Color(0xFFB8C2D2),
                    fontSize: 15,
                  ),
                ),

                Spacer(),

                Text(
                  "Official Platform • Estd. 1959",
                  style: TextStyle(
                    color: Color(0xFFB8C2D2),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget footerLink(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFD7DEE8),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  }

class FooterInfo extends StatelessWidget {
  final String text;

  const FooterInfo(
    this.text, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFD7DEE8),
        fontSize: 16,
        height: 1.8,
      ),
    );
  }
}