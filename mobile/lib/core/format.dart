
import 'package:intl/intl.dart';

int asInt(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? fallback;
}

double asDouble(dynamic v, [double fallback = 0]) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? fallback;
}

String asString(dynamic v, [String fallback = '']) =>
    v == null ? fallback : '$v';

bool asBool(dynamic v) => v == true;

List<Map<String, dynamic>> mapList(dynamic v) {
  if (v is! List) return const [];
  return v
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
}

List<String> stringList(dynamic v) {
  if (v is! List) return const [];
  return v.map((e) => '$e').toList();
}

String money(num paise) {
  final hasPaise = paise % 100 != 0;
  final f = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: hasPaise ? 2 : 0,
  );
  return f.format(paise / 100);
}

String rupeesInput(num paise) => (paise / 100).toStringAsFixed(0);

String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return 'P';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

String firstName(String name) {
  final p = name.trim().split(RegExp(r'\s+'));
  return p.isEmpty ? name : p.first;
}

DateTime? parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse('$v')?.toLocal();
}

String dateTime(dynamic v) {
  final d = parseDate(v);
  if (d == null) return '—';
  return DateFormat('d MMM, h:mm a').format(d);
}

String dateOnly(dynamic v) {
  final d = parseDate(v);
  if (d == null) return '—';
  return DateFormat('d MMM yyyy').format(d);
}

String relative(dynamic v) {
  final d = parseDate(v);
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM').format(d);
}

String statusLabel(String status) {
  const labels = {
    'assigned': 'New order',
    'accepted': 'Accepted',
    'at_pickup': 'At pickup',
    'picked_up': 'Picked up',
    'arrived': 'Arrived',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
    'not_started': 'Not started',
    'in_review': 'In review',
    'verified': 'Verified',
    'rejected': 'Rejected',
    'pending': 'Pending',
    'open': 'Open',
    'resolved': 'Resolved',
    'closed': 'Closed',
    'active': 'Active',
    'suspended': 'Suspended',
    'deactivated': 'Deactivated',
    'paid': 'Paid',
    'processing': 'Processing',
    'failed': 'Failed',
    'instant': 'Instant',
    'weekly': 'Weekly',
  };
  return labels[status] ?? status.replaceAll('_', ' ');
}

String docLabel(String type) {
  const labels = {
    'aadhaar': 'Aadhaar card',
    'pan': 'PAN card',
    'driving_licence': 'Driving licence',
    'vehicle_rc': 'Vehicle RC',
    'vehicle_insurance': 'Vehicle insurance',
    'pucc': 'Pollution certificate',
    'police_verification': 'Police verification',
    'selfie': 'Selfie',
  };
  return labels[type] ?? type.replaceAll('_', ' ');
}

String vehicleLabel(String type) {
  const labels = {
    'motorbike': 'Motorbike',
    'scooter': 'Scooter',
    'electric_scooter': 'Electric scooter',
    'bicycle': 'Bicycle',
  };
  return labels[type] ?? type.replaceAll('_', ' ');
}

// Supported app language labels.
String langLabel(String code) {
  const labels = {
    'en': 'English',
    'ta': 'Tamil',
    'si': 'Sinhala',
    'hi': 'Hindi',
    'ml': 'Malayalam',
    'te': 'Telugu',
    'kn': 'Kannada',
    'ms': 'Malay',
    'ms_SG': 'Malay (Singapore)',
  };

  return labels[code] ?? 'English';
}

String ledgerLabel(String type) {
  const labels = {
    'delivery_base': 'Delivery pay',
    'delivery_distance': 'Distance pay',
    'tip': 'Customer tip',
    'bonus': 'Bonus',
    'incentive': 'Incentive',
    'deduction': 'Deduction',
    'adjustment': 'Adjustment',
    'payout': 'Payout',
    'payout_fee': 'Payout fee',
  };
  return labels[type] ?? type.replaceAll('_', ' ');
}
