class ServiceItem {
  final String id;
  final String name;
  final String? subtitle;
  final String? iconName;
  final String? gradientStart;
  final String? gradientEnd;

  ServiceItem({
    required this.id,
    required this.name,
    this.subtitle,
    this.iconName,
    this.gradientStart,
    this.gradientEnd,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'],
      name: json['name'],
      subtitle: json['subtitle'],
      iconName: json['icon_name'],
      gradientStart: json['gradient_start'],
      gradientEnd: json['gradient_end'],
    );
  }
}
