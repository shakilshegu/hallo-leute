class Country {
  final String name;
  final String isoCode;
  final String dialCode;
  final String flag;

  const Country({
    required this.name,
    required this.isoCode,
    required this.dialCode,
    required this.flag,
  });
}

const countries = [
  Country(name: 'United States', isoCode: 'US', dialCode: '+1', flag: '🇺🇸'),
  Country(name: 'India', isoCode: 'IN', dialCode: '+91', flag: '🇮🇳'),
  Country(name: 'United Kingdom', isoCode: 'GB', dialCode: '+44', flag: '🇬🇧'),
  Country(name: 'Canada', isoCode: 'CA', dialCode: '+1', flag: '🇨🇦'),
  Country(name: 'Australia', isoCode: 'AU', dialCode: '+61', flag: '🇦🇺'),
  Country(name: 'Germany', isoCode: 'DE', dialCode: '+49', flag: '🇩🇪'),
  Country(name: 'France', isoCode: 'FR', dialCode: '+33', flag: '🇫🇷'),
  Country(name: 'United Arab Emirates', isoCode: 'AE', dialCode: '+971', flag: '🇦🇪'),
  Country(name: 'Singapore', isoCode: 'SG', dialCode: '+65', flag: '🇸🇬'),
  Country(name: 'Pakistan', isoCode: 'PK', dialCode: '+92', flag: '🇵🇰'),
];
