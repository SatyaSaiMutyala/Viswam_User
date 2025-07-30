class RealEstateModel {
  final int? id;
  final int? providerId;
  final List<String> images;
  final String? propertyType;
  final String? title;
  final String? location;
  final int? areaSqfeet;
  final String? monthlyRent;
  final String? securityDeposit;
  final String? description;
  final String? date;
  final String? ownerName;
  final String? ownerPhn;
  final String? ownerEmail;

  RealEstateModel({
    this.id,
    this.providerId,
    required this.images,
    this.propertyType,
    this.title,
    this.location,
    this.areaSqfeet,
    this.monthlyRent,
    this.securityDeposit,
    this.description,
    this.date,
    this.ownerName,
    this.ownerPhn,
    this.ownerEmail,
  });

  factory RealEstateModel.fromJson(Map<String, dynamic> json) {
    return RealEstateModel(
      id: json['id'],
      providerId: json['provider_id'],
      images: List<String>.from(json['images'] ?? []),
      propertyType: json['property_type'],
      title: json['title'],
      location: json['location'],
      areaSqfeet: json['area_sqfeet'],
      monthlyRent: json['monthly_rent'],
      securityDeposit: json['security_deposit'],
      description: json['description'],
      date: json['date'],
      ownerName: json['owner_name'],
      ownerPhn: json['owner_phn'],
      ownerEmail: json['owner_email'],
    );
  }
}
