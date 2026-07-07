import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';

class VerificationStep extends StatelessWidget {
  const VerificationStep({
    super.key,
    required this.email,
    required this.otpController,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.sending,
    required this.verifying,
    this.onUploadDocument,
    this.uploadingDocument = false,
    this.otpSentMessage,
    this.debugOtp,
    this.errorMessage,
    this.verified = false,
  });

  final String email;
  final TextEditingController otpController;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback? onUploadDocument;
  final bool uploadingDocument;
  final String? otpSentMessage;
  final bool sending;
  final bool verifying;
  final String? debugOtp;
  final String? errorMessage;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verify your email',
          style: GoogleFonts.fraunces(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.heading,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We will send a 6-digit code to $email. '
          'If email is not configured on the server, a development code appears below after you click Send.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.bodyText,
            height: 1.5,
          ),
        ),
        if (otpSentMessage != null) ...[
          const SizedBox(height: 16),
          _banner(otpSentMessage!, isError: false),
        ],
        if (errorMessage != null) ...[
          const SizedBox(height: 16),
          _banner(errorMessage!, isError: true),
        ],
        if (debugOtp != null) ...[
          const SizedBox(height: 16),
          _banner(
            'Development code (use this if email did not arrive): $debugOtp',
            isError: false,
          ),
        ],
        if (verified) ...[
          const SizedBox(height: 16),
          _banner('Email verified successfully.', isError: false),
        ],
        const SizedBox(height: 24),
        OutlinedButton(
          key: const ValueKey('membership-send-otp'),
          onPressed: sending ? null : onSendOtp,
          child: sending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send verification code'),
        ),
        const SizedBox(height: 16),
        Text(
          'ENTER OTP',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('membership-otp-field'),
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.muted,
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
        const SizedBox(height: 16),
        ElevatedButton(
          key: const ValueKey('membership-verify-otp'),
          onPressed: verifying || verified ? null : onVerifyOtp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: verifying
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Verify code'),
        ),
        if (onUploadDocument != null) ...[
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'OR',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Verify with a document instead — upload a PDF, JPG, or PNG '
            '(degree certificate or ID, max 5 MB).',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.bodyText,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            key: const ValueKey('membership-upload-document'),
            onPressed:
                uploadingDocument || verified ? null : onUploadDocument,
            icon: uploadingDocument
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_outlined),
            label: const Text('Upload verification document'),
          ),
        ],
      ],
    );
  }

  Widget _banner(String message, {required bool isError}) {
    final color = isError ? AppColors.error : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        message,
        style: GoogleFonts.inter(color: color, fontSize: 14),
      ),
    );
  }
}
