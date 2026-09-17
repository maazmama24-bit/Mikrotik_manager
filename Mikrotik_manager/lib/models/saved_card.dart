

// =============================================================================
// Saved Card
// =============================================================================

/// كرت واحد محفوظ محلياً.
class SavedCard {
  String name;
  String password;
  String profile;
  String limitUptime;
  String limitGb;
  String limitBytesTotal;
  String comment;

  SavedCard({
    required this.name,
    required this.password,
    this.profile = '',
    this.limitUptime = '',
    this.limitGb = '',
    this.limitBytesTotal = '',
    this.comment = '',
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'password': password,
    'profile': profile,
    'limitUptime': limitUptime,
    'limitGb': limitGb,
    'limitBytesTotal': limitBytesTotal,
    'comment': comment,
  };

  factory SavedCard.fromJson(Map<String, dynamic> json) {
    return SavedCard(
      name: json['name'] as String? ?? '',
      password: json['password'] as String? ?? '',
      profile: json['profile'] as String? ?? '',
      limitUptime: json['limitUptime'] as String? ?? '',
      limitGb: json['limitGb'] as String? ?? '',
      limitBytesTotal: json['limitBytesTotal'] as String? ?? '',
      comment: json['comment'] as String? ?? '',
    );
  }

  /// للتحويل إلى Map يسهل استخدامه في الطباعة.
  Map<String, String> toPrintMap() => {
    'name': name,
    'password': password,
    'profile': profile,
    'limit-uptime': limitUptime,
    'limit-gb': limitGb,
    'limit-bytes-total': limitBytesTotal,
    'comment': comment,
  };
}

// =============================================================================
// Saved Group (مجموعة كروت محفوظة)
// =============================================================================

/// مجموعة من الكروت المحفوظة (من عملية توليد واحدة).
class SavedGroup {
  String id;

  /// اسم المجموعة (يظهر في القائمة).
  String name;

  /// تاريخ الإنشاء (ISO format).
  String createdAt;

  /// عدد الكروت.
  int count;

  /// اسم الشبكة (للطباعة).
  String networkName;

  /// البروفايل المستخدم.
  String profile;

  /// المدة.
  String limitUptime;

  /// الباقة بالجيجا.
  String limitGb;

  /// الكروت.
  List<SavedCard> cards;

  SavedGroup({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.count,
    this.networkName = '',
    this.profile = '',
    this.limitUptime = '',
    this.limitGb = '',
    required this.cards,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt,
    'count': count,
    'networkName': networkName,
    'profile': profile,
    'limitUptime': limitUptime,
    'limitGb': limitGb,
    'cards': cards.map((c) => c.toJson()).toList(),
  };

  factory SavedGroup.fromJson(Map<String, dynamic> json) {
    return SavedGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      networkName: json['networkName'] as String? ?? '',
      profile: json['profile'] as String? ?? '',
      limitUptime: json['limitUptime'] as String? ?? '',
      limitGb: json['limitGb'] as String? ?? '',
      cards: (json['cards'] as List<dynamic>?)
          ?.map((c) => SavedCard.fromJson(c as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  /// تاريخ العرض.
  String get displayDate {
    if (createdAt.isEmpty) return '';

    try {
      final dt = DateTime.parse(createdAt);
      final y = dt.year.toString();
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');

      return '$y/$m/$d - $h:$min';
    } catch (_) {
      return '';
    }
  }

  /// نص الوصف للمجموعة.
  String get summary {
    final parts = <String>[];

    if (profile.isNotEmpty) parts.add(profile);
    if (limitUptime.isNotEmpty) parts.add('⏱ $limitUptime');
    if (limitGb.isNotEmpty) parts.add('📊 $limitGb GB');

    return parts.join(' • ');
  }
}