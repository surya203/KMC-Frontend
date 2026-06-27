import 'package:flutter/material.dart';

class GalleryPreview extends StatelessWidget {
  const GalleryPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
      child: Column(
        children: [
          const Text(
            "Gallery",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 40),

          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: List.generate(
              6,
              (index) => ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  "https://picsum.photos/400/300?random=$index",
                  width: 300,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          ElevatedButton(
            onPressed: () {},

            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFDB02A),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 18,
              ),
            ),

            child: const Text(
              "View Full Gallery",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}