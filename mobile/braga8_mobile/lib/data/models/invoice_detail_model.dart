

class InvoiceItem {
  final int id;
  final String description;
  final double amount;

  const InvoiceItem({
    required this.id,
    required this.description,
    required this.amount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) => InvoiceItem(
    id: json['id'] as int,
    description: json['description'] as String? ?? '-',
    amount: switch (json['amount']) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0,
    },
  );
}

class MeterPhoto {
  final String meterType;
  final String readingValue;
  final String? recordedAt;
  final String? photoUrl;

  const MeterPhoto({
    required this.meterType,
    required this.readingValue,
    this.recordedAt,
    this.photoUrl,
  });
  bool get isElectric => meterType.toLowerCase().contains('elect');

  factory MeterPhoto.fromJson(Map<String, dynamic> json) {
    final rawPath = json['photo_url'] as String? ?? json['photo_path'] as String?;
    String? resolvedUrl;
    if (rawPath != null && rawPath.isNotEmpty) {
      if (rawPath.startsWith('http')) {
        resolvedUrl = rawPath.replaceFirst('http://', 'https://');
      } else {
        resolvedUrl = 'http://172.16.4.22:8000/storage/$rawPath';
      }
    }

    // ← INI yang kurang, return MeterPhoto-nya!
    return MeterPhoto(
      meterType: json['meter_type'] as String? ?? 'electricity',
      readingValue: json['reading_value']?.toString() ?? '0',
      recordedAt: json['recorded_at']?.toString(),
      photoUrl: resolvedUrl,
    );
  }
}

class InvoiceDetail {
  final List<InvoiceItem> items;
  final List<MeterPhoto> meterPhotos;
  final String? proofImgUrl;

  const InvoiceDetail({
    required this.items,
    required this.meterPhotos,
    this.proofImgUrl,
  });

  factory InvoiceDetail.fromJson(Map<String, dynamic> json) => InvoiceDetail(
    items: (json['items'] as List<dynamic>? ?? [])
        .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    meterPhotos: (json['meter_photos'] as List<dynamic>? ?? [])
        .map((e) => MeterPhoto.fromJson(e as Map<String, dynamic>))
        .toList(),
    proofImgUrl: resolveImg(json['proof_img']?.toString()),
  );

  static String? resolveImg(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http')) return raw.replaceFirst('http://', 'https://');
    return 'http://172.16.4.22:8000/storage/$raw';
  }
}
