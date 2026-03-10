enum AlibiStyle {
  goofy,
  serious;

  String get apiValue => name;

  String get label => switch (this) {
        AlibiStyle.goofy => 'GOOFY',
        AlibiStyle.serious => 'SERIOUS',
      };

  String get description => switch (this) {
        AlibiStyle.goofy => 'Surreal nonsense with suspicious confidence.',
        AlibiStyle.serious => 'Professional damage control with a straight face.',
      };
}
