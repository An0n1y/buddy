class AgeGenderEthnicityData {
  AgeGenderEthnicityData({
    required this.ageRange,
    required this.gender,
    required this.ethnicity,
    required this.ageConfidence,
    required this.genderConfidence,
    required this.ethnicityConfidence,
  });
  final String ageRange; // coarse age bucket
  final String gender; // Male / Female / Unknown
  final String ethnicity; // label from dataset mapping or 'Uncertain'
  final double ageConfidence;
  final double genderConfidence;
  final double ethnicityConfidence;
}
