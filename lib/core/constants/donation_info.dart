/// Donation UI constants. Payment checkout is off until we enable it later.
class DonationInfo {
  DonationInfo._();

  /// Flip to `true` when Razorpay donation checkout is ready again.
  static const paymentsEnabled = false;

  static const title = 'Make a donation';

  static const summary =
      'Donate as a general donation, or to exactly one project.';

  static const paymentUnavailableMessage =
      'We are currently not accepting any payments. '
      'Please check back later or contact the alumni office.';

  /// Static project categories (slug + label). Ready for payment wiring later.
  static const projectCategories = <({String slug, String label})>[
    (slug: 'library', label: 'Library'),
    (slug: 'academic_scholarship', label: 'Academic Scholarship'),
    (slug: 'mens_hostel_amenities', label: "Men's Hostel Amenities"),
    (slug: 'ladies_hostel_amenities', label: 'Ladies Hostel Amenities'),
    (slug: 'college_buildings', label: 'College Buildings'),
    (slug: 'other', label: 'Other'),
  ];
}
