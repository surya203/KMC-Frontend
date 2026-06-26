import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    // Mobile
    if (width < 900) {
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        toolbarHeight: 80,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.primary),
          onPressed: () {},
        ),
        title: Image.asset(
          'assets/images/logo.png',
          height: 50,
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none,
              color: AppColors.primary,
            ),
            onPressed: () {},
          ),
        ],
      );
    }

    // Desktop
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      toolbarHeight: 90,
      automaticallyImplyLeading: false,
      titleSpacing: 30,
      title: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            height: 55,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text("Home"),
        ),
        TextButton(
          onPressed: () {},
          child: const Text("About"),
        ),
        TextButton(
          onPressed: () {},
          child: const Text("Events"),
        ),
        TextButton(
          onPressed: () {},
          child: const Text("Gallery"),
        ),
        TextButton(
          onPressed: () {},
          child: const Text("MY KMC"),
        ),
        const SizedBox(width: 40),
        TextButton(
          onPressed: () {},
          child: const Text("Sign in"),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 30, left: 10),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff12284C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: const Text(
              "Join Network",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(90);
}