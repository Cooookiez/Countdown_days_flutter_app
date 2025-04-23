import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/event_data.dart';
import '../services/dev_mode_service.dart';

class DevModeUtils {
  // Helper method to safely show dialogs
  static void _safeShowDialog({
    required BuildContext context,
    required WidgetBuilder builder,
  }) {
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: builder,
      );
    }
  }

  // Helper method to safely show SnackBars
  static void _safeShowSnackBar(
      BuildContext context,
      String message, {
        Color backgroundColor = Colors.green,
      }) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
        ),
      );
    }
  }

  /// Show a confirmation dialog to clear all data
  static Future<void> showClearDataDialog(BuildContext context, EventData eventData) async {
    if (!kDebugMode) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete ALL events from the database. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Store a local variable for context before awaiting any async operations
      final currentContext = context;

      // Show loading indicator
      _safeShowDialog(
        context: currentContext,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Delete all events
        final events = List.from(eventData.events);
        for (final event in events) {
          await eventData.deleteEvent(event.id);
        }

        // Hide loading indicator - only if context is still mounted
        if (currentContext.mounted) {
          Navigator.of(currentContext).pop();

          // Show success message
          _safeShowSnackBar(
            currentContext,
            'All data cleared successfully',
          );
        }
      } catch (e) {
        // Handle errors
        print('Error clearing data: $e');

        if (currentContext.mounted) {
          Navigator.of(currentContext).pop(); // Close loading dialog

          _safeShowSnackBar(
            currentContext,
            'Error clearing data: $e',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  /// Show a developer menu with various options
  static void showDevMenu(BuildContext context, EventData eventData) {
    if (!kDebugMode) return;

    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.data_array),
              title: const Text('Add Demo Data'),
              onTap: () async {
                // Save a reference to the original context
                final currentContext = context;

                // Close the bottom sheet
                Navigator.pop(bottomSheetContext);

                // Only continue if the original context is still valid
                if (!currentContext.mounted) return;

                // Show loading indicator
                _safeShowDialog(
                  context: currentContext,
                  builder: (dialogContext) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );

                try {
                  // Add demo data
                  final eventData = Provider.of<EventData>(currentContext, listen: false);
                  final devService = DevModeService();
                  await devService.addDemoData(eventData);

                  // Only update UI if context is still valid
                  if (currentContext.mounted) {
                    Navigator.pop(currentContext); // Close loading dialog

                    _safeShowSnackBar(
                      currentContext,
                      'Demo data added successfully!',
                    );
                  }
                } catch (e) {
                  // Handle errors
                  print('Error adding demo data: $e');

                  if (currentContext.mounted) {
                    Navigator.pop(currentContext); // Close loading dialog

                    _safeShowSnackBar(
                      currentContext,
                      'Error adding demo data: $e',
                      backgroundColor: Colors.red,
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
              onTap: () {
                // Store context before pop
                final currentContext = context;
                Navigator.pop(bottomSheetContext);

                // Only continue if the original context is still valid
                if (currentContext.mounted) {
                  showClearDataDialog(currentContext, eventData);
                }
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Testing'),
              children: [
                ListTile(
                  leading: const Icon(Icons.notification_add),
                  title: const Text('Send Immediate Notification'),
                  onTap: () async {
                    final currentContext = context;
                    Navigator.pop(bottomSheetContext);

                    try {
                      final devService = DevModeService();
                      await devService.testNotification();

                      if (currentContext.mounted) {
                        _safeShowSnackBar(
                          currentContext,
                          'Test notification sent!',
                          backgroundColor: Colors.blue,
                        );
                      }
                    } catch (e) {
                      if (currentContext.mounted) {
                        _safeShowSnackBar(
                          currentContext,
                          'Error sending notification: $e',
                          backgroundColor: Colors.red,
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Schedule Notification (1 min)'),
                  onTap: () async {
                    final currentContext = context;
                    Navigator.pop(bottomSheetContext);

                    try {
                      final devService = DevModeService();
                      await devService.testScheduledNotification(minutesFromNow: 1);

                      if (currentContext.mounted) {
                        _safeShowSnackBar(
                          currentContext,
                          'Notification scheduled for 1 minute from now',
                          backgroundColor: Colors.blue,
                        );
                      }
                    } catch (e) {
                      if (currentContext.mounted) {
                        _safeShowSnackBar(
                          currentContext,
                          'Error scheduling notification: $e',
                          backgroundColor: Colors.red,
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_sweep),
                  title: const Text('Cancel All Notifications'),
                  onTap: () async {
                    final currentContext = context;
                    Navigator.pop(bottomSheetContext);

                    try {
                      final devService = DevModeService();
                      await devService.cancelAllNotifications();

                      if (currentContext.mounted) {
                        _safeShowSnackBar(
                          currentContext,
                          'All notifications cancelled',
                          backgroundColor: Colors.orange,
                        );
                      }
                    } catch (e) {
                      if (currentContext.mounted) {
                        _safeShowSnackBar(
                          currentContext,
                          'Error canceling notifications: $e',
                          backgroundColor: Colors.red,
                        );
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('Reset Badge Counter'),
                  onTap: () async {
                    final currentContext = context;
                    Navigator.pop(bottomSheetContext);

                    try {
                      final devService = DevModeService();
                      await devService.resetBadgeCounter();

                      if (currentContext.mounted) {
                        _safeShowSnackBar(
                          currentContext,
                          'Badge counter reset',
                          backgroundColor: Colors.green,
                        );
                      }
                    } catch (e) {
                      if (currentContext.mounted) {
                        _safeShowSnackBar(
                          currentContext,
                          'Error resetting badge counter: $e',
                          backgroundColor: Colors.red,
                        );
                      }
                    }
                  },
                ),
              ],
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Dev Mode'),
              onTap: () {
                final currentContext = context;
                Navigator.pop(bottomSheetContext);

                if (currentContext.mounted) {
                  showDialog(
                    context: currentContext,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Development Mode'),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('This app is running in development mode.'),
                          SizedBox(height: 16),
                          Text('Features available in dev mode:'),
                          SizedBox(height: 8),
                          Text('• Add demo data'),
                          Text('• Clear all data'),
                          Text('• Test notifications'),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}