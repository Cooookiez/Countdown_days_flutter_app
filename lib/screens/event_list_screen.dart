
import 'package:countdown_days_flutter_app/screens/event_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/event_data.dart';
import '../models/event_model.dart';

class EventListScreen extends StatefulWidget {
  static const String id = 'EventListScreen';
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();

}

class _EventListScreenState extends State<EventListScreen> {
  @override
  void initState() {
    super.initState();
    // Load events when screen opens
    print("EventListScreen initialized"); // Debug print
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Loading events in EventListScreen"); // Debug print
      context.read<EventData>().loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        actions: [
          // TODO
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
            itemCount: eventData.events.length,
            itemBuilder: (context, index) {
              final event = eventData.events[index];
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
    if (duration.isNegative) {
      return 'Event has passed';
    }

    if (duration.inDays > 0) {
      return '${duration.inDays} days remaining';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours remaining';
    } else {
      return '${duration.inMinutes} minutes remaining';
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