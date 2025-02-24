import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../models/event_data.dart';

class EventFormScreen extends StatefulWidget {
  static const String id = 'EventFormScreen';

  const EventFormScreen({super.key});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  bool _includeTime = false;
  Event? eventToEdit;
  bool _isRepeating = false;
  int _repeatInterval = 1;
  FrequencyUnit _repeatUnit = FrequencyUnit.months;
  bool _allowNotifications = false;
  List<NotificationConfig> _notifications = [
    NotificationConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: 1,
      unit: FrequencyUnit.hours,
      isEnabled: true,
    )
  ];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedDate = DateTime.now();
    _selectedTime = null;
    _includeTime = false;
    _allowNotifications = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadEventFromArguments();
  }

  // Load event from route arguments
  Future<void> _loadEventFromArguments() async {
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args == null) return;

    // If the argument is an Event, use it directly
    if (args is Event) {
      _setupEventForEditing(args);
      return;
    }

    // If the argument is a String (event ID), load the event
    if (args is String) {
      setState(() => _isLoading = true);
      try {
        final eventData = Provider.of<EventData>(context, listen: false);
        final event = await eventData.getEvent(args);

        if (event != null && mounted) {
          _setupEventForEditing(event);
        }
      } catch (e) {
        print('Error loading event: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load event details')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Set up form fields for editing an event
  void _setupEventForEditing(Event event) {
    eventToEdit = event;
    setState(() {
      _titleController.text = eventToEdit!.title;
      _descriptionController.text = eventToEdit?.description ?? '';

      _isRepeating = eventToEdit!.isRepeating;
      if (_isRepeating && eventToEdit!.repeatConfig != null) {
        _repeatInterval = eventToEdit!.repeatConfig!.interval;
        _repeatUnit = eventToEdit!.repeatConfig!.unit;
      }

      _selectedDate = eventToEdit!.endDate;

      if (eventToEdit!.includeTime) {
        _selectedTime = TimeOfDay.fromDateTime(eventToEdit!.endDate);
        _includeTime = true;
      }

      _allowNotifications = eventToEdit!.allowNotifications;
      if (_allowNotifications && eventToEdit!.notifications.isNotEmpty) {
        _notifications = eventToEdit!.notifications;
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Confirm before discarding changes
        if (_hasChanges()) {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Discard Changes?'),
              content: const Text('You have unsaved changes. Are you sure you want to discard them?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard'),
                ),
              ],
            ),
          ) ?? false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(eventToEdit == null ? 'Add Event' : 'Edit Event'),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  hintText: 'Enter event title',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Enter event description (optional)',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Date Selection
              Card(
                child: ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                ),
              ),

              const SizedBox(height: 8),

              // Time Selection
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Include Time'),
                      value: _includeTime,
                      onChanged: (value) {
                        setState(() {
                          _includeTime = value;
                          if (value && _selectedTime == null) {
                            _selectedTime = TimeOfDay.now();
                          }
                        });
                      },
                    ),
                    if (_includeTime)
                      ListTile(
                        title: const Text('Time'),
                        subtitle: Text(
                          _formatTime(_selectedTime),
                          style: const TextStyle(fontSize: 16),
                        ),
                        trailing: const Icon(Icons.access_time),
                        onTap: _selectTime,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Repeat Event'),
                      value: _isRepeating,
                      onChanged: (value) {
                        setState(() {
                          _isRepeating = value;
                        });
                      },
                    ),
                    if (_isRepeating) ...[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Repeat every',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                                initialValue: _repeatInterval.toString(),
                                onChanged: (value) {
                                  setState(() {
                                    _repeatInterval = int.tryParse(value) ?? 1;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<FrequencyUnit>(
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  border: OutlineInputBorder(),
                                ),
                                value: _repeatUnit,
                                items: FrequencyUnit.values.map((unit) {
                                  return DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit.toString().split('.').last),
                                  );
                                }).toList(),
                                onChanged: (FrequencyUnit? value) {
                                  if (value != null) {
                                    setState(() {
                                      _repeatUnit = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),

              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable notifications'),
                      value: _allowNotifications,
                      onChanged: (value) {
                        setState(() {
                          _allowNotifications = value;
                        });
                      },
                    ),
                    if (_allowNotifications) ...[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            ..._notifications.asMap().entries.map(
                                  (entry) => _buildNotificationCard(entry.value, entry.key),
                            ),

                            const SizedBox(height: 8),

                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 4,
                              ),
                              child: FilledButton.tonal(
                                onPressed: () {
                                  setState(() {
                                    _notifications = List.from(_notifications)
                                      ..add(NotificationConfig(
                                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                                        amount: 1,
                                        unit: FrequencyUnit.hours,
                                      ));
                                  });
                                },
                                style: ButtonStyle(
                                  minimumSize: WidgetStateProperty.all(const Size.fromHeight(48)),
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                child: const Text('Add notification'),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),


              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  eventToEdit == null ? 'Add Event' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationConfig notification, int index) {
    return Card(
      child: ListTile(
        title: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.red,
                size: 24,
              ),
              onPressed: () {
                setState(() {
                  _notifications = List.from(_notifications)..removeAt(index);
                });
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                keyboardType: TextInputType.number,
                initialValue: notification.amount.toString(),
                onChanged: (value) {
                  final newAmount = int.tryParse(value) ?? 1;
                  setState(() {
                    _notifications = List.from(_notifications)
                      ..[index] = NotificationConfig(
                        id: notification.id,
                        amount: newAmount,
                        unit: notification.unit,
                        isEnabled: notification.isEnabled,
                      );
                  });
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<FrequencyUnit>(
                value: notification.unit,
                items: FrequencyUnit.values.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(unit.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (FrequencyUnit? value) {
                  if (value != null) {
                    setState(() {
                      _notifications = List.from(_notifications)
                        ..[index] = NotificationConfig(
                          id: notification.id,
                          amount: notification.amount,
                          unit: value,
                          isEnabled: notification.isEnabled,
                        );
                    });
                  }
                },
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Before',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Select time';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _hasChanges() {
    if (eventToEdit == null) {
      return _titleController.text.isNotEmpty || _descriptionController.text.isNotEmpty;
    }

    return _titleController.text != eventToEdit!.title ||
        _descriptionController.text != (eventToEdit?.description ?? '') ||
        _selectedDate != eventToEdit!.endDate ||
        _includeTime != eventToEdit!.includeTime ||
        (_includeTime && _selectedTime != TimeOfDay.fromDateTime(eventToEdit!.endDate));
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime?.hour ?? 0,
          _selectedTime?.minute ?? 0,
        );
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTime = picked;
        // Update the date to include the new time
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _saveEvent() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final eventData = context.read<EventData>();

    final DateTime finalDateTime = _includeTime && _selectedTime != null
        ? DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    )
        : DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    final event = Event(
        id: eventToEdit?.id ?? DateTime
            .now()
            .millisecondsSinceEpoch
            .toString(),
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        endDate: finalDateTime,
        includeTime: _includeTime,
        isRepeating: _isRepeating,
        repeatConfig: _isRepeating
            ? RepeatConfig(
          interval: _repeatInterval,
          unit: _repeatUnit,
        )
            : null,
        allowNotifications: _allowNotifications,
        notifications: _allowNotifications ? _notifications : []
    );

    if (eventToEdit == null) {
      eventData.addEvent(event);
    } else {
      eventData.updateEvent(event);
    }

    Navigator.pop(context);
  }
}