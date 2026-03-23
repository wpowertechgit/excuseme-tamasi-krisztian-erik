class CountBucket {
  const CountBucket({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  factory CountBucket.fromJson(Map<String, dynamic> json) {
    return CountBucket(
      label: json['label'] as String? ?? '',
      value: (json['value'] as num?)?.toInt() ?? 0,
    );
  }
}

class DailyActivityPoint {
  const DailyActivityPoint({
    required this.date,
    required this.count,
  });

  final String date;
  final int count;

  factory DailyActivityPoint.fromJson(Map<String, dynamic> json) {
    return DailyActivityPoint(
      date: json['date'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class StatsOverview {
  const StatsOverview({
    required this.totalGenerations,
    required this.publishedCount,
    required this.categoryBreakdown,
    required this.styleBreakdown,
    required this.languageBreakdown,
    required this.dailyActivity,
  });

  final int totalGenerations;
  final int publishedCount;
  final List<CountBucket> categoryBreakdown;
  final List<CountBucket> styleBreakdown;
  final List<CountBucket> languageBreakdown;
  final List<DailyActivityPoint> dailyActivity;

  factory StatsOverview.fromJson(Map<String, dynamic> json) {
    return StatsOverview(
      totalGenerations: (json['totalGenerations'] as num?)?.toInt() ?? 0,
      publishedCount: (json['publishedCount'] as num?)?.toInt() ?? 0,
      categoryBreakdown: (json['categoryBreakdown'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CountBucket.fromJson)
          .toList(),
      styleBreakdown: (json['styleBreakdown'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CountBucket.fromJson)
          .toList(),
      languageBreakdown: (json['languageBreakdown'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CountBucket.fromJson)
          .toList(),
      dailyActivity: (json['dailyActivity'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(DailyActivityPoint.fromJson)
          .toList(),
    );
  }
}

