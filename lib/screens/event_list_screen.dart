import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_data.dart';
import '../models/event_model.dart';
import 'event_form_screen.dart';

class EventListScreen extends StatefulWidget {
  static const String id = 'EventListScreen';
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Load events when screen opens
    print("EventListScreen initialized"); // Debug print
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Loading events in EventListScreen"); // Debug print
      context.read<EventData>().loadEvents();
    });

    // Start the countdown timer that updates every second
    _startCountdownTimer();
  }

  void _startCountdownTimer() {
    // Update every minute to refresh countdown displays
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // This will rebuild the UI with updated countdown values
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          event.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
            Text(
              _formatTimeRemaining(event.timeUntil()),
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.w500,
              ),
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