class SaveRealEstateModel {
  final int id;
  final int providerId;
  final List<String> images;
  final String propertyType;
  final String title;
  final String location;
  final String? furnishingType;
  final int areaSqfeet;
  final String monthlyRent;
  final String securityDeposit;
  final String description;
  final String date;
  final String ownerName;
  final String? ownerPhn;
  final String ownerEmail;
  final String createdAt;
  final String updatedAt;

  SaveRealEstateModel({
    required this.id,
    required this.providerId,
    required this.images,
    required this.propertyType,
    required this.title,
    required this.location,
    this.furnishingType,
    required this.areaSqfeet,
    required this.monthlyRent,
    required this.securityDeposit,
    required this.description,
    required this.date,
    required this.ownerName,
    this.ownerPhn,
    required this.ownerEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaveRealEstateModel.fromJson(Map<String, dynamic> json) {
    return SaveRealEstateModel(
      id: json['id'],
      providerId: json['provider_id'],
      images: List<String>.from(json['images']),
      propertyType: json['property_type'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      furnishingType: json['furnishing_type'],
      areaSqfeet: json['area_sqfeet'],
      monthlyRent: json['monthly_rent'] ?? '0',
      securityDeposit: json['security_deposit'] ?? '0',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      ownerName: json['owner_name'] ?? '',
      ownerPhn: json['owner_phn'],
      ownerEmail: json['owner_email'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'images': images,
      'property_type': propertyType,
      'title': title,
      'location': location,
      'furnishing_type': furnishingType,
      'area_sqfeet': areaSqfeet,
      'monthly_rent': monthlyRent,
      'security_deposit': securityDeposit,
      'description': description,
      'date': date,
      'owner_name': ownerName,
      'owner_phn': ownerPhn,
      'owner_email': ownerEmail,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
