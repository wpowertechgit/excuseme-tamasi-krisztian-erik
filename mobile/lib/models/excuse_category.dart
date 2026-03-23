enum ExcuseCategory {
  work,
  personal,
  family,
  romance,
  health,
  sports,
  travel,
  other;

  String get apiValue => name;

  String get label => switch (this) {
        ExcuseCategory.work => 'Work',
        ExcuseCategory.personal => 'Personal',
        ExcuseCategory.family => 'Family',
        ExcuseCategory.romance => 'Romance',
        ExcuseCategory.health => 'Health',
        ExcuseCategory.sports => 'Sports',
        ExcuseCategory.travel => 'Travel',
        ExcuseCategory.other => 'Other',
      };

  static ExcuseCategory fromApi(String? value) {
    return ExcuseCategory.values.firstWhere(
      (category) => category.apiValue == value,
      orElse: () => ExcuseCategory.other,
    );
  }
}

