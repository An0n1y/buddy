class AgeGenderData {
  AgeGenderData(
      {required this.ageRange, required this.gender, required this.confidence});
  final String ageRange; // e.g. "25-30"
  final String gender; // "Male", "Female", "Unknown"
  final double confidence; // 0..1
}
