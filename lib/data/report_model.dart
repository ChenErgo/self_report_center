import 'package:faker/faker.dart' as fk;

class ReportRecord {
  ReportRecord({
    this.id,
    required this.title,
    required this.owner,
    required this.department,
    required this.status,
    required this.priority,
    required this.category,
    required this.subcategory,
    required this.region,
    required this.platform,
    required this.version,
    required this.severity,
    required this.deviceId,
    required this.os,
    required this.city,
    required this.country,
    required this.contactEmail,
    required this.contactPhone,
    required this.tags,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String owner;
  final String department;
  final String status;
  final String priority;
  final String category;
  final String subcategory;
  final String region;
  final String platform;
  final String version;
  final String severity;
  final String deviceId;
  final String os;
  final String city;
  final String country;
  final String contactEmail;
  final String contactPhone;
  final String tags;
  final String updatedAt;

  Map<String, Object?> toMap({bool includeId = false}) {
    final map = <String, Object?>{
      'title': title,
      'owner': owner,
      'department': department,
      'status': status,
      'priority': priority,
      'category': category,
      'subcategory': subcategory,
      'region': region,
      'platform': platform,
      'version': version,
      'severity': severity,
      'deviceId': deviceId,
      'os': os,
      'city': city,
      'country': country,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'tags': tags,
      'updatedAt': updatedAt,
    };
    if (includeId) {
      map['id'] = id;
    }
    return map;
  }

  factory ReportRecord.fromMap(Map<String, Object?> map) {
    return ReportRecord(
      id: map['id'] as int?,
      title: (map['title'] ?? '') as String,
      owner: (map['owner'] ?? '') as String,
      department: (map['department'] ?? '') as String,
      status: (map['status'] ?? '') as String,
      priority: (map['priority'] ?? '') as String,
      category: (map['category'] ?? '') as String,
      subcategory: (map['subcategory'] ?? '') as String,
      region: (map['region'] ?? '') as String,
      platform: (map['platform'] ?? '') as String,
      version: (map['version'] ?? '') as String,
      severity: (map['severity'] ?? '') as String,
      deviceId: (map['deviceId'] ?? '') as String,
      os: (map['os'] ?? '') as String,
      city: (map['city'] ?? '') as String,
      country: (map['country'] ?? '') as String,
      contactEmail: (map['contactEmail'] ?? '') as String,
      contactPhone: (map['contactPhone'] ?? '') as String,
      tags: (map['tags'] ?? '') as String,
      updatedAt: (map['updatedAt'] ?? '') as String,
    );
  }

  ReportRecord copyWith({
    int? id,
    String? title,
    String? owner,
    String? department,
    String? status,
    String? priority,
    String? category,
    String? subcategory,
    String? region,
    String? platform,
    String? version,
    String? severity,
    String? deviceId,
    String? os,
    String? city,
    String? country,
    String? contactEmail,
    String? contactPhone,
    String? tags,
    String? updatedAt,
  }) {
    return ReportRecord(
      id: id ?? this.id,
      title: title ?? this.title,
      owner: owner ?? this.owner,
      department: department ?? this.department,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      region: region ?? this.region,
      platform: platform ?? this.platform,
      version: version ?? this.version,
      severity: severity ?? this.severity,
      deviceId: deviceId ?? this.deviceId,
      os: os ?? this.os,
      city: city ?? this.city,
      country: country ?? this.country,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static ReportRecord fake(fk.Faker faker) {
    final now = DateTime.now();
    final updated = now.subtract(Duration(days: faker.randomGenerator.integer(90)));
    return ReportRecord(
      title: faker.company.name(),
      owner: faker.person.name(),
      department: faker.job.title(),
      status: faker.randomGenerator.element(['草稿', '待审核', '已发布', '归档']),
      priority: faker.randomGenerator.element(['高', '中', '低']),
      category: faker.randomGenerator.element(['销售', '运营', '财务', '研发']),
      subcategory: faker.randomGenerator.element(['日报', '周报', '月报']),
      region: faker.address.neighborhood(),
      platform: faker.randomGenerator.element(['Web', 'iOS', 'Android', 'Desktop']),
      version: 'v${faker.randomGenerator.integer(4)}.${faker.randomGenerator.integer(10)}',
      severity: faker.randomGenerator.element(['P0', 'P1', 'P2']),
      deviceId: faker.guid.guid().substring(0, 8),
      os: faker.randomGenerator.element(['Windows', 'macOS', 'Linux']),
      city: faker.address.city(),
      country: faker.address.country(),
      contactEmail: faker.internet.email(),
      contactPhone: faker.phoneNumber.us(),
      tags: faker.randomGenerator.element(['核心', '实验', '监控', '外部']),
      updatedAt: updated.toIso8601String(),
    );
  }
}
