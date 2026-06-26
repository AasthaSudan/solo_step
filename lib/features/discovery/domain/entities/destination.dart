/// Domain entity representing a suggested travel destination.
class Destination {
  final String name;
  final String tagline;
  final double dailyBudgetEstimate;
  final List<String> highlights;
  final String safetyNote;

  const Destination({
    required this.name,
    required this.tagline,
    required this.dailyBudgetEstimate,
    required this.highlights,
    required this.safetyNote,
  });
}
