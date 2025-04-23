
// Represents the unit of time for repetition
enum FrequencyUnit {
  minutes,
  hours,
  days,
  weeks,
  months,
  years,
}

// Main event models
class Event {
  final String id; // Unique identifier
  String title;
  String? description;
  DateTime endDate;
  bool includeTime;
  bool isRepeating;
  RepeatConfig? repeatConfig; // Optional repeat configuration
  bool allowNotifications;
  List<NotificationConfig> notifications;
  DateTime createdAt;
  DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.endDate,
    this.includeTime = false,
    this.isRepeating = false,
    this.repeatConfig,
    this.allowNotifications = false,
    List<NotificationConfig>? notifications,
  }) : notifications = notifications ?? [],
       createdAt = DateTime.now(),
       updatedAt = DateTime.now();

  // Calculate time remaining until the event
  Duration timeUntil() {
    final now = DateTime.now();
    return endDate.difference(now);
  }

  // Get the next occurrence of the event based on repeat configuration
  DateTime getNextOccurrence() {
    if (!isRepeating || repeatConfig == null || !repeatConfig!.isValid) {
      return endDate; // Return current date if not repeating
    }

    final now = DateTime.now();

    // If the event is still in the future, just return its date
    if (endDate.isAfter(now)) {
      return endDate;
    }

    // Calculate how many repetition units have passed since the event date
    int repetitions = 0;
    DateTime nextDate = endDate;

    while (nextDate.isBefore(now)) {
      repetitions++;

      switch (repeatConfig!.unit) {
        case FrequencyUnit.minutes:
          nextDate = endDate.add(Duration(minutes: repeatConfig!.interval * repetitions));
          break;
        case FrequencyUnit.hours:
          nextDate = endDate.add(Duration(hours: repeatConfig!.interval * repetitions));
          break;
        case FrequencyUnit.days:
          nextDate = endDate.add(Duration(days: repeatConfig!.interval * repetitions));
          break;
        case FrequencyUnit.weeks:
          nextDate = endDate.add(Duration(days: 7 * repeatConfig!.interval * repetitions));
          break;
        case FrequencyUnit.months:
        // Handle month addition correctly
          int monthsToAdd = repeatConfig!.interval * repetitions;
          int year = endDate.year + (endDate.month + monthsToAdd - 1) ~/ 12;
          int month = (endDate.month + monthsToAdd - 1) % 12 + 1;

          // Handle potential day-of-month issues (e.g., Jan 31 -> Feb 28)
          int day = endDate.day;
          int daysInMonth = DateTime(year, month + 1, 0).day;
          if (day > daysInMonth) {
            day = daysInMonth;
          }

          nextDate = DateTime(
            year,
            month,
            day,
            endDate.hour,
            endDate.minute,
          );
          break;
        case FrequencyUnit.years:
          nextDate = DateTime(
            endDate.year + (repeatConfig!.interval * repetitions),
            endDate.month,
            endDate.day,
            endDate.hour,
            endDate.minute,
          );
          break;
      }
    }

    return nextDate;
  }

  // Convert to JSON for storage
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      endDate: DateTime.parse(json['endDate']),
      includeTime: json['includeTime'] == 1, // Convert integer to boolean
      isRepeating: json['repeatConfigId'] != null, // Set based on repeatConfigId
      repeatConfig: null, // This will be set separately in getEvent
      allowNotifications: json['allowNotifications'] == 1,
    )
      ..createdAt = DateTime.parse(json['createdAt'])
      ..updatedAt = DateTime.parse(json['updatedAt']);
  }

  // Create to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'endDate': endDate.toIso8601String(),
      'includeTime': includeTime ? 1 : 0, // Convert boolean to integer
      'repeatConfig': repeatConfig?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

}

class NotificationConfig {
  final String id; // Unique identifier for this notification
  final int amount; // The amount of time before the event
  final FrequencyUnit unit; // The unit of time (minutes, hours, days, etc)
  final bool isEnabled; // Whether this notification is enabled

  const NotificationConfig({
    required this.id,
    required this.amount,
    required this.unit,
    this.isEnabled = true,
  });

  // Calculate when this notification should trigger based on event date
  DateTime getNotificationTime(DateTime eventDate) {
    switch (unit) {
      case FrequencyUnit.minutes:
        return eventDate.subtract(Duration(minutes: amount));
      case FrequencyUnit.hours:
        return eventDate.subtract(Duration(hours: amount));
      case FrequencyUnit.days:
        return eventDate.subtract(Duration(days: amount));
      case FrequencyUnit.weeks:
        return eventDate.subtract(Duration(days: amount * 7));
      case FrequencyUnit.months:
        return DateTime(
          eventDate.year,
          eventDate.month - amount,
          eventDate.day,
          eventDate.hour,
          eventDate.minute,
        );
      case FrequencyUnit.years:
        return DateTime(
          eventDate.year - amount,
          eventDate.month,
          eventDate.day,
          eventDate.hour,
          eventDate.minute,
        );
    }
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'unit': unit.toString(),
      'isEnabled': isEnabled ? 1 : 0,
    };
  }

  // Create from JSON for storage
  factory NotificationConfig.fromJson(Map<String, dynamic> json) {
    return NotificationConfig(
      id: json['id'],
      amount: json['amount'],
      unit: FrequencyUnit.values.firstWhere(
            (e) => e.toString() == json['unit'],
      ),
      isEnabled: json['isEnabled'] == 1,
    );
  }
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