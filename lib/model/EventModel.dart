
// Represents the unit of time for repetition
enum FrequencyUnit {
  days,
  weeks,
  months,
  years,
}

// Represents the repeat configuration
class RepeatConfig {
  final int interval; // The number of units (e.g., 2 for every 2 weeks)
  final FrequencyUnit unit; // The unit of time (days, weeks, months, years)

  const RepeatConfig({
    required this.interval,
    required this.unit,
  });

  // Helper to check if this is a valid repeat configuration
  bool get isValid => interval > 0;

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'interval': interval,
      'unit': unit.toString(),
    };
  }

  // Create from JSON for storage
  factory RepeatConfig.fromJson(Map<String, dynamic> json) {
    return RepeatConfig(
      interval: json['interval'],
      unit: FrequencyUnit.values.firstWhere(
            (e) => e.toString() == json['unit'],
      ),
    );
  }
}

// Main event model
class Event {
  final String id; // Unique identifier
  String title;
  String? description;
  DateTime endDate;
  bool includeTime;
  RepeatConfig? repeatConfig; // Optional repeat configuration
  DateTime createdAt;
  DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.endDate,
    this.includeTime = false,
    this.repeatConfig,
  }) : createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  // Calculate time remaining until the event
  Duration timeUntil() {
    final now = DateTime.now();
    return endDate.difference(now);
  }

  // Get the next occurrence of the event based on repeat configuration
  DateTime? getNextOccurrence() {
    if (repeatConfig == null || !repeatConfig!.isValid) {
      return null;
    }

    final now = DateTime.now();
    if (endDate.isAfter(now)) {
      return endDate;
    }

    switch (repeatConfig!.unit) {
      case FrequencyUnit.days:
        return DateTime(
          now.year,
          now.month,
          now.day,
          endDate.hour,
          endDate.minute,
        ).add(Duration(days: repeatConfig!.interval));

      case FrequencyUnit.weeks:
        return DateTime(
          now.year,
          now.month,
          now.day,
          endDate.hour,
          endDate.minute,
        ).add(Duration(days: 7 * repeatConfig!.interval));

      case FrequencyUnit.months:
        return DateTime(
          now.year,
          now.month + repeatConfig!.interval,
          now.day,
          endDate.hour,
          endDate.minute,
        );

      case FrequencyUnit.years:
        return DateTime(
          now.year + repeatConfig!.interval,
          endDate.month,
          endDate.day,
          endDate.hour,
          endDate.minute,
        );
    }
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'endDate': endDate.toIso8601String(),
      'includeTime': includeTime,
      'repeatConfig': repeatConfig?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON for storage
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      endDate: DateTime.parse(json['endDate']),
      includeTime: json['includeTime'],
      repeatConfig: json['repeatConfig'] != null
          ? RepeatConfig.fromJson(json['repeatConfig'])
          : null,
    )
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updatedAt = DateTime.parse(json['updatedAt']);
  }

}