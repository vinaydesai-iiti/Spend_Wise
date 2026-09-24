enum PaymentMode { upi, card, cash, netbanking }

PaymentMode _modeFromString(String s) {
  return PaymentMode.values.firstWhere(
    (m) => m.name == s,
    orElse: () => PaymentMode.upi,
  );
}

/// A single transaction line.
/// [amountPaise] is negative for a spend and positive for a refund/credit,
/// matching the "refund reduces category total" edge case in the spec.
class Txn {
  final String id;
  final String merchantRaw;
  final String merchantName;
  final String categoryId;
  final int amountPaise;
  final DateTime at;
  final PaymentMode mode;

  const Txn({
    required this.id,
    required this.merchantRaw,
    required this.merchantName,
    required this.categoryId,
    required this.amountPaise,
    required this.at,
    required this.mode,
  });

  bool get isRefund => amountPaise > 0;

  Txn copyWith({String? categoryId}) => Txn(
        id: id,
        merchantRaw: merchantRaw,
        merchantName: merchantName,
        categoryId: categoryId ?? this.categoryId,
        amountPaise: amountPaise,
        at: at,
        mode: mode,
      );

  /// Normalises a raw merchant string ("SWIGGY*1234", "UBER   TRIP#99")
  /// so merchant rules match reliably even when the suffix changes.
  static String normalise(String raw) {
    final noSuffix = raw.split(RegExp(r'[*#]')).first;
    return noSuffix.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  factory Txn.fromJson(Map<String, dynamic> json) => Txn(
        id: json['id'] as String,
        merchantRaw: json['merchantRaw'] as String,
        merchantName: json['merchantName'] as String,
        categoryId: json['category'] as String,
        amountPaise: json['amountPaise'] as int,
        at: DateTime.parse(json['at'] as String),
        mode: _modeFromString(json['mode'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchantRaw': merchantRaw,
        'merchantName': merchantName,
        'category': categoryId,
        'amountPaise': amountPaise,
        'at': at.toUtc().toIso8601String(),
        'mode': mode.name,
      };
}
