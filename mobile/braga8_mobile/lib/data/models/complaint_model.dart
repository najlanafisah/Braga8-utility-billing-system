class Complaint {
  final int id;
  final String title; 
  final String description;
  final String status;
  final String? imageUrl;
  final String? reportDate;
  final String? solution;

  const Complaint({
    required this.id,
    required this.title, 
    required this.description,
    required this.status,
    this.imageUrl,
    this.reportDate,
    this.solution,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final int parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return Complaint(
      id: parsedId,
      title: json['title']?.toString() ?? '', 
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      imageUrl: json['image']?.toString(),
      reportDate: json['report_date']?.toString(),
      solution: json['solution']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title, 
    'description': description,
    'status': status,
    if (imageUrl != null) 'image': imageUrl,
    if (reportDate != null) 'report_date': reportDate,
    if (solution != null) 'solution': solution,
  };

  Complaint copyWith({
    int? id,
    String? title,
    String? description,
    String? status,
    String? imageUrl,
    String? reportDate,
    String? solution,
  }) => Complaint(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    imageUrl: imageUrl ?? this.imageUrl,
    reportDate: reportDate ?? this.reportDate,
    solution: solution ?? this.solution,
  );
}
