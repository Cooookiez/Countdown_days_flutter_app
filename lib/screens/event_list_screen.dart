import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_data.dart';
import '../models/event_model.dart';
import '../services/background_service.dart';
import 'event_form_screen.dart';

class EventListScreen extends StatefulWidget {
  static const String id = 'EventListScreen';
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  Timer? _countdownTimer;
  final BackgroundService _backgroundService = BackgroundService();

  @override
  void initState() {
    super.initState();
    // Load events when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final eventData = context.read<EventData>();
      await eventData.loadEvents();

      // Check for repeating events that need updating
      await eventData.updateRepeatingEvents();

      // Initialize background service with valid EventData provider
      _backgroundService.initialize(eventData);
    });

    // Start the countdown timer that updates every second
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    // Update every second to refresh countdown displays
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Check if any repeating events need updating
          final now = DateTime.now();
          final eventData = Provider.of<EventData>(context, listen: false);

          bool needsUpdate = eventData.events.any((event) =>
          event.isRepeating &&
              event.repeatConfig != null &&
              event.endDate.isBefore(now));

          if (needsUpdate) {
            // Don't await - just trigger the update
            eventData.updateRepeatingEvents();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _backgroundService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        actions: [
          PopupMenuButton<EventSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (EventSortType sortType) {
              context.read<EventData>().setSortType(sortType);
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: EventSortType.dateAscending,
                child: Text('Date (Earliest first)'),
              ),
              const PopupMenuItem(
                value: EventSortType.dateDescending,
                child: Text('Date (Latest first)'),
              ),
              const PopupMenuItem(
                value: EventSortType.titleAscending,
                child: Text('Title (A to Z)'),
              ),
              const PopupMenuItem(
                value: EventSortType.titleDescending,
                child: Text('Title (Z to A)'),
              ),
              const PopupMenuItem(
                value: EventSortType.createdAtNewest,
                child: Text('Recently added'),
              ),
              const PopupMenuItem(
                value: EventSortType.createdAtOldest,
                child: Text('Oldest added'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<EventData>(
        builder: (context, eventData, child) {
          if (eventData.events.isEmpty) {
            return const Center(
              child: Text('No events yet. Add your first event'),
            );
          }

          return ListView.builder(
            itemCount: eventData.sortedEvents.length,
            itemBuilder: (context, index) {
              final event = eventData.sortedEvents[index];
              return _buildEventCard(event);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
              context,
              EventFormScreen.id,
              arguments: null
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatDateTime(DateTime date, bool includeTime) {
    if (includeTime) {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimeRemaining(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days != 0) {
      return '${days > 0 ? "" : "-"}${days.abs()} days';
    } else if (hours != 0) {
      return '${hours > 0 ? "" : "-"}${hours.abs()} hours';
    } else {
      return '${minutes > 0 ? "" : "-"}${minutes.abs()} minutes';
    }
  }

  // Helper method to format repeat interval for display
  String _formatRepeatInterval(RepeatConfig config) {
    String unitStr = '';
    switch (config.unit) {
      case FrequencyUnit.days:
        unitStr = config.interval == 1 ? 'day' : 'days';
        break;
      case FrequencyUnit.weeks:
        unitStr = config.interval == 1 ? 'week' : 'weeks';
        break;
      case FrequencyUnit.months:
        unitStr = config.interval == 1 ? 'month' : 'months';
        break;
      case FrequencyUnit.years:
        unitStr = config.interval == 1 ? 'year' : 'years';
        break;
      case FrequencyUnit.hours:
        unitStr = config.interval == 1 ? 'hour' : 'hours';
        break;
      case FrequencyUnit.minutes:
        unitStr = config.interval == 1 ? 'minute' : 'minutes';
        break;
    }
    return 'Every ${config.interval} $unitStr';
  }

  Future<void> _confirmDelete(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) {
        context.read<EventData>().deleteEvent(event.id);
      }
    }
  }

  Widget _buildEventCard(Event event) {
    final bool isRepeating = event.isRepeating && event.repeatConfig != null;
    final bool hasNotifications = event.allowNotifications && event.notifications.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                event.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (hasNotifications)
              Tooltip(
                message: '${event.notifications.length} notification${event.notifications.length > 1 ? 's' : ''} set',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_active, size: 16, color: Colors.indigo),
                      const SizedBox(width: 4),
                      Text(
                        '${event.notifications.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null)
              Text(event.description!),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(event.endDate, event.includeTime),
              style: const TextStyle(color: Colors.grey),
            ),
            Row(
              children: [
                Text(
                  _formatTimeRemaining(event.timeUntil()),
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isRepeating) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatRepeatInterval(event.repeatConfig!),
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.pushNamed(
                context,
                EventFormScreen.id,
                arguments: event,
              );
            } else if (value == 'delete') {
              _confirmDelete(event);
            }
          },
        ),
      ),
    );
  }
}