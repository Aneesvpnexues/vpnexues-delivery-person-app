import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ui/design.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  InkResponse(
                    onTap: () => Navigator.of(context).maybePop(),
                    radius: 24,
                    child: const SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                        color: C.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: C.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _Heading('VP Nexues Delivery Partner App'),
                          SizedBox(height: 8),
                          _Body('Effective date: November 27, 2026'),
                          _Body('Last updated: November 27, 2026'),
                          SizedBox(height: 12),
                          _Body(
                            '[Company Legal Name] ("VP Nexues", "we", "us", "our") operates the VP Nexues Delivery Partner mobile application (the "App"). This Privacy Policy explains how we collect, use, share, store, and protect information when delivery partners ("you", "your") register, use, or interact with the App.',
                          ),
                          SizedBox(height: 8),
                          _Note(
                            'This is a draft and should be reviewed by your legal/compliance team before publishing.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _section(
                      '1. Information We Collect',
                      const [
                        _Subheading('A. Information you provide'),
                        _Bullet('Account and profile details: Full name, mobile number, email address, profile photo/selfie, city/hub, and language preference.'),
                        _Bullet('Identity and verification documents: Aadhaar, PAN, driving licence, vehicle RC, vehicle insurance, PUCC, police verification, and other KYC/onboarding documents required by law or company policy.'),
                        _Bullet('Vehicle details: Vehicle type, registration number, and related document details.'),
                        _Bullet('Payout details: Bank account details, IFSC, account holder name, UPI ID, and payout-related information.'),
                        _Bullet('Support and communications: Messages, support tickets, call/chat records where applicable, SOS/emergency contact details, feedback, and ratings.'),
                        SizedBox(height: 10),
                        _Subheading('B. Information collected automatically'),
                        _Bullet('Device and app information: Device model, OS version, app version, device identifiers, IP address, crash logs, and diagnostic data.'),
                        _Bullet('Location information: Precise or approximate location when required for delivery operations, such as going online, receiving orders, navigation, pickup/delivery tracking, and safety features. Location collection depends on your device permissions and app settings.'),
                        _Bullet('Usage information: Login/activity timestamps, order actions, delivery status updates, app interactions, and notification logs.'),
                        SizedBox(height: 10),
                        _Subheading('C. Information from others'),
                        _Bullet('Customers/businesses/platform partners: Order details, pickup/drop locations, delivery instructions, and contact information necessary to complete deliveries. Customer contact details may be masked where supported.'),
                        _Bullet('Service providers: Payment/payout processors, SMS/OTP providers, mapping services, cloud hosting, analytics, and verification vendors may provide status or transaction information.'),
                      ],
                    ),
                    _section(
                      '2. How We Use Your Information',
                      const [
                        _Body('We use your information to:'),
                        SizedBox(height: 8),
                        _Bullet('Create and manage your delivery partner account.'),
                        _Bullet('Verify identity, eligibility, documents, and vehicle compliance.'),
                        _Bullet('Assign, manage, and track orders and deliveries.'),
                        _Bullet('Process earnings, payouts, incentives, and related records.'),
                        _Bullet('Provide customer support, safety/SOS features, and fraud prevention.'),
                        _Bullet('Send service messages, OTPs, notifications, and important updates.'),
                        _Bullet('Improve app performance, reliability, and user experience.'),
                        _Bullet('Comply with legal, regulatory, tax, insurance, and law-enforcement obligations.'),
                        _Bullet('Enforce our terms, policies, and partner agreements.'),
                      ],
                    ),
                    _section(
                      '3. How We Share Your Information',
                      const [
                        _Body('We do not sell your personal information. We may share information with:'),
                        SizedBox(height: 8),
                        _Bullet('Customers/recipients as needed for delivery: Limited details such as your name, photo, vehicle details, location/status, and masked contact details where applicable.'),
                        _Bullet('Service providers: Hosting, cloud storage, SMS/OTP, maps/navigation, analytics, crash reporting, payment/payout, KYC/verification, and support vendors.'),
                        _Bullet('Business/legal entities: Affiliates, auditors, insurers, legal advisors, or authorities when required by law, legal process, safety concerns, fraud investigation, or business protection.'),
                        _Bullet('Business transfers: In case of merger, acquisition, restructuring, or asset transfer, subject to applicable law.'),
                      ],
                    ),
                    _section(
                      '4. Legal Basis / Consent',
                      const [
                        _Body(
                          'Where required by applicable law, we process your information based on your consent, performance of a contract, compliance with legal obligations, legitimate business interests, or protection of vital interests (such as safety/SOS situations).',
                        ),
                      ],
                    ),
                    _section(
                      '5. Data Retention',
                      const [
                        _Body(
                          'We retain personal information only as long as necessary for the purposes described in this policy, including account management, legal/regulatory compliance, dispute resolution, fraud prevention, tax/accounting, and enforcement of agreements. Retention periods may vary by data type and legal requirement.',
                        ),
                      ],
                    ),
                    _section(
                      '6. Data Security',
                      const [
                        _Body(
                          'We use reasonable administrative, technical, and physical safeguards to protect personal information. However, no system is completely secure, and we cannot guarantee absolute security.',
                        ),
                      ],
                    ),
                    _section(
                      '7. Your Choices and Rights',
                      const [
                        _Body('Depending on applicable law, you may have rights to:'),
                        SizedBox(height: 8),
                        _Bullet('Access, correct, or update certain profile information.'),
                        _Bullet('Request deletion or restriction of certain data, subject to legal/operational requirements.'),
                        _Bullet('Withdraw consent where processing is based on consent.'),
                        _Bullet('Object to certain processing, where applicable.'),
                        _Bullet('Request information about how your data is processed.'),
                        SizedBox(height: 8),
                        _Body(
                          'To exercise these rights, contact us using the details below. We may need to verify your identity before responding.',
                        ),
                      ],
                    ),
                    _section(
                      '8. Location Permissions',
                      const [
                        _Body(
                          'You can control location permissions through your device settings. Disabling location may affect core delivery features, including going online, receiving orders, navigation, and delivery tracking.',
                        ),
                      ],
                    ),
                    _section(
                      '9. Children’s Privacy',
                      const [
                        _Body(
                          'The App is intended for delivery partners who are legally eligible to work. We do not knowingly collect personal information from children.',
                        ),
                      ],
                    ),
                    _section(
                      '10. Third-Party Services',
                      const [
                        _Body(
                          'The App may use third-party services (such as maps, SMS/OTP, payment, or analytics providers). Their processing is governed by their own policies and terms where applicable.',
                        ),
                      ],
                    ),
                    _section(
                      '11. Grievance Officer / Contact Us',
                      const [
                        _Body('For privacy questions, concerns, or complaints, contact:'),
                        SizedBox(height: 8),
                        _Bullet('Grievance Officer: [Name]'),
                        _Bullet('Company: [Company Legal Name]'),
                        _Bullet('Address: [Full Address]'),
                        _Bullet('Email: [privacy@yourdomain.com]'),
                        _Bullet('Phone: [Support/Grievance Number]'),
                        _Bullet('Working hours: [Days/Hours]'),
                      ],
                    ),
                    _section(
                      '12. Changes to This Policy',
                      const [
                        _Body(
                          'We may update this Privacy Policy from time to time. We will notify you through the App or other appropriate channels when required. The "Last updated" date will reflect the latest version.',
                        ),
                      ],
                    ),
                    _section(
                      'Before publishing',
                      const [
                        _Note('Fill in company legal name, address, grievance/contact details, data retention periods, third-party services used, location collection details, and jurisdiction-specific rights (for example, India DPDP Act references, if applicable).'),
                      ],
                      icon: LucideIcons.circleAlert,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _section(String title, List<Widget> children, {IconData icon = LucideIcons.shield}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF5DB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: C.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: C.ink,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  static Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: C.line),
        boxShadow: sh(8, 20, .04),
      ),
      child: child,
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: C.ink,
        height: 1.25,
      ),
    );
  }
}

class _Subheading extends StatelessWidget {
  const _Subheading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: C.ink,
          height: 1.35,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
        color: Color(0xFF333333),
        height: 1.55,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0DC8C)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF795109),
          height: 1.45,
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7),
            width: 5,
            height: 5,
            decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
