import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../utils/phone_country_codes.dart';
import '../utils/validators.dart';

class MobileNumberField extends StatefulWidget {
  const MobileNumberField({
    super.key,
    required this.dialCodeController,
    required this.numberController,
    this.required = true,
  });

  final TextEditingController dialCodeController;
  final TextEditingController numberController;
  final bool required;

  @override
  State<MobileNumberField> createState() => _MobileNumberFieldState();
}

class _MobileNumberFieldState extends State<MobileNumberField> {
  PhoneCountryCode get _country =>
      phoneCountryFromDialCode(widget.dialCodeController.text);

  Future<void> _openCountryPicker() async {
    final selected = await showModalBottomSheet<PhoneCountryCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CountryCodePickerSheet(
        selectedDialCode: normalizeDialCode(widget.dialCodeController.text),
      ),
    );
    if (selected == null || !mounted) return;
    widget.dialCodeController.text = selected.dialCode;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final country = _country;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.mutedText,
            ),
            children: [
              const TextSpan(text: 'MOBILE NUMBER'),
              if (widget.required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.error),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 108,
              child: TextField(
                controller: widget.dialCodeController,
                keyboardType: TextInputType.phone,
                inputFormatters: const [DialCodeInputFormatter()],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '+91',
                  helperText: 'Code',
                  helperStyle: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.mutedText,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.6,
                    ),
                  ),
                  suffixIcon: IconButton(
                    tooltip: 'Browse countries',
                    icon: const Icon(Icons.public, size: 18),
                    onPressed: _openCountryPicker,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.numberController,
                keyboardType: TextInputType.phone,
                inputFormatters: mobileNumberInputFormattersFor(country),
                decoration: InputDecoration(
                  hintText: country.localMinLength == country.localMaxLength
                      ? List.filled(country.localMaxLength, '0').join()
                      : 'Phone number',
                  helperText: country.localMinLength == country.localMaxLength
                      ? 'Enter ${country.localMaxLength}-digit number'
                      : 'Enter ${country.localMinLength}-${country.localMaxLength} digit number',
                  helperStyle: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.6,
                    ),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Type any country code (e.g. +91, +1, +44) or tap the globe to search all countries.',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.mutedText,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class DialCodeInputFormatter extends TextInputFormatter {
  const DialCodeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 4) {
      digits = digits.substring(0, 4);
    }
    final text = digits.isEmpty ? '+' : '+$digits';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _CountryCodePickerSheet extends StatefulWidget {
  const _CountryCodePickerSheet({required this.selectedDialCode});

  final String? selectedDialCode;

  @override
  State<_CountryCodePickerSheet> createState() =>
      _CountryCodePickerSheetState();
}

class _CountryCodePickerSheetState extends State<_CountryCodePickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PhoneCountryCode> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return phoneCountryCodes;
    return phoneCountryCodes.where((country) {
      return country.label.toLowerCase().contains(q) ||
          country.dialCode.contains(q) ||
          country.code.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Select country code',
                style: GoogleFonts.fraunces(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.heading,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search country or code',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        'No countries found',
                        style: GoogleFonts.inter(color: AppColors.mutedText),
                      ),
                    )
                  : ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 20, endIndent: 20),
                      itemBuilder: (context, index) {
                        final country = items[index];
                        final selected =
                            country.dialCode == widget.selectedDialCode;
                        return ListTile(
                          title: Text(
                            country.label,
                            style: GoogleFonts.inter(
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: Text(
                            country.dialCode,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          selected: selected,
                          onTap: () => Navigator.of(context).pop(country),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
