import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';
import '../../services/event_service.dart';
import 'create_event_form.dart';

class OrganizerPanel extends StatefulWidget {
  const OrganizerPanel({super.key});

  @override
  State<OrganizerPanel> createState() => _OrganizerPanelState();
}

class _OrganizerPanelState extends State<OrganizerPanel> {
  final EventService _eventService = EventService();
  List<EventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      if (userId != null) {
        final events = await _eventService.getEventsByCreator(userId);
        setState(() {
          _events = events;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading events: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showCreateEventDialog({EventModel? eventToEdit}) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eventToEdit == null ? 'Create New Event' : 'Edit Event',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                CreateEventForm(
                  eventToEdit: eventToEdit,
                  onSubmit: (event) async {
                    try {
                      if (eventToEdit == null) {
                        await _eventService.createEvent(event);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event created successfully')),
                        );
                      } else {
                        await _eventService.updateEvent(eventToEdit.id, event);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event updated successfully')),
                        );
                      }
                      Navigator.of(context).pop();
                      _loadEvents();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEventDetails(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.black, width: 1),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Event Details',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type: ${event.type}',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Description: ${event.description}',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Location: ${event.location}',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${event.date.day}/${event.date.month}/${event.date.year}',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 8),
                Text(
                  'Time: ${event.time.format(context)}',
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 16),
                
                if (event.ticketInfo != null) ...[
                  const Divider(color: Colors.black),
                  const SizedBox(height: 8),
                  const Text(
                    'Ticket Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Price: \$${event.ticketInfo!.price.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Available Tickets: ${event.ticketInfo!.availableQuantity}/${event.ticketInfo!.totalQuantity}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],

                const Divider(color: Colors.black),
                const SizedBox(height: 8),
                const Text(
                  'Attendees',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                if (event.attendees.isEmpty)
                  const Text(
                    'No attendees yet',
                    style: TextStyle(color: Colors.black87, fontStyle: FontStyle.italic),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: event.attendees.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          event.attendees[index],
                          style: const TextStyle(color: Colors.black87),
                        ),
                        dense: true,
                      );
                    },
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showCreateEventDialog(eventToEdit: event);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text(
                              'Confirm Delete',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            content: const Text(
                              'Are you sure you want to delete this event? This action cannot be undone.',
                              style: TextStyle(color: Colors.black87),
                            ),
                            actions: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.black,
                                ),
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.of(context).pop(false),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                                onPressed: () => Navigator.of(context).pop(true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await _eventService.deleteEvent(event.id);
                            Navigator.of(context).pop();
                            _loadEvents();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Event deleted successfully'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error deleting event: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 120,
          width: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'assets/images/dmu_logo.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.signOut();
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed('/login');
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out: $e')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _events.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No events yet. Create your first event!',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _showCreateEventDialog(),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black, width: 1),
                      ),
                      child: ListTile(
                        title: Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.type,
                              style: const TextStyle(color: Colors.black87),
                            ),
                            Text(
                              'Date: ${event.date.day}/${event.date.month}/${event.date.year}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            if (event.ticketInfo != null)
                              Text(
                                'Tickets: ${event.ticketInfo!.availableQuantity}/${event.ticketInfo!.totalQuantity} available',
                                style: const TextStyle(color: Colors.black87),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.info_outline, color: Colors.red),
                          onPressed: () => _showEventDetails(event),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onPressed: () => _showCreateEventDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
