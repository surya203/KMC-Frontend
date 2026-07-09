import 'package:flutter/material.dart';

import 'event_hero_image.dart';

/// Hero banner for member event detail pages.
class EventsHeroBanner extends StatelessWidget {
  const EventsHeroBanner({super.key, this.height = 280});

  final double height;

  @override
  Widget build(BuildContext context) {
    return EventHeroImage(height: height);
  }
}
