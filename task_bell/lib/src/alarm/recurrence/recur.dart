abstract class Recur {
  /// Returns the next occurrence of the recurrence based on the provided [time].
  DateTime? getNextOccurrence(DateTime time);

  /// Converts the recurrence settings to a [Map<String, dynamic>].
  Map<String, dynamic> toMap();
}
