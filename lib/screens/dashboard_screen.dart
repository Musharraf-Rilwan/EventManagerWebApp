import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/ticket_service.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../models/attendee_model.dart';
import 'ticket_confirmation_screen.dart';
import 'ticket_quantity_dialog.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EventService _eventService = EventService();
  final TicketService _ticketService = TicketService();
  List<EventModel> _events = [];
  bool _isLoading = true;
  AuthService? _authService;

  @override
  void initState() {
    super.initState();
    _authService = Provider.of<AuthService>(context, listen: false);
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final events = await _eventService.getAllEvents();
      setState(() {
        _events = events;
      });
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

  Future<void> _registerForEvent(EventModel event) async {
    try {
      final user = _authService?.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to register for events')),
        );
        return;
      }

      // Create attendee model with user details
      final attendee = AttendeeModel(
        id: user.uid,
        name: user.displayName ?? 'Anonymous',
        email: user.email ?? '',
        phoneNumber: user.phoneNumber,
        registrationDate: DateTime.now(),
      );

      if (event.ticketInfo?.isEnabled ?? false) {
        // Show quantity selection dialog for ticketed events
        await _showTicketQuantityDialog(event);
      } else {
        // Direct registration for free events
        await _eventService.registerAttendee(event.id, attendee);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully registered for event')),
          );
        }
      }

      // Refresh events list
      if (mounted) {
        setState(() {
          _loadEvents();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showTicketQuantityDialog(EventModel event) async {
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) => TicketQuantityDialog(
        availableQuantity: event.ticketInfo?.availableQuantity ?? 0,
        price: event.ticketInfo?.price ?? 0.0,
      ),
    );

    if (quantity != null && quantity > 0) {
      try {
        final user = _authService?.currentUser;
        if (user == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to purchase tickets')),
          );
          return;
        }

        final ticket = await _ticketService.purchaseTickets(
          event,
          user.uid,
          user.email!,
          user.displayName ?? 'Anonymous',
          quantity,
        );

        if (!mounted) return;

        // Navigate to ticket confirmation screen
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TicketConfirmationScreen(ticket: ticket),
          ),
        );

        // Refresh events
        setState(() {
          _loadEvents();
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error purchasing tickets: $e')),
        );
      }
    }
  }

  Future<void> _unregisterFromEvent(EventModel event) async {
    final userId = _authService?.currentUser?.uid;
    if (userId == null) return;

    try {
      await _eventService.unregisterAttendee(event.id, userId);
      await _loadEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully unregistered from event')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error unregistering from event: $e')),
      );
    }
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
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 22,
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
                const SizedBox(height: 24),
                if (_authService?.currentUser?.uid != null &&
                    !event.attendees.contains(_authService?.currentUser?.uid))
                  Center(
                    child: ElevatedButton(
                      onPressed: event.ticketInfo?.availableQuantity == 0
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              _registerForEvent(event);
                            },
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
                      child: Text(
                        event.ticketInfo != null
                            ? event.ticketInfo!.availableQuantity > 0
                                ? 'Purchase Tickets'
                                : 'Sold Out'
                            : 'Register',
                      ),
                    ),
                  )
                else if (_authService?.currentUser?.uid != null &&
                    event.attendees.contains(_authService?.currentUser?.uid))
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'You are registered for this event',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _unregisterFromEvent(event);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Cancel Registration'),
                        ),
                      ],
                    ),
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
            'assets/images/dmu_logo1.png',
            fit: BoxFit.contain,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadEvents,
          ),
          if (_authService?.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.black),
              onPressed: () async {
                try {
                  await _authService?.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushReplacementNamed('/login');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.red))
          : _events.isEmpty
              ? const Center(
                  child: Text(
                    'No events available',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  itemBuilder: (context, index) {
                    final event = _events[index];
                    final isRegistered =
                        _authService?.currentUser?.uid != null &&
                            event.attendees
                                .contains(_authService?.currentUser?.uid);

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
                            Text(
                              'Location: ${event.location}',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            if (event.ticketInfo != null)
                              Text(
                                'Tickets: ${event.ticketInfo!.availableQuantity}/${event.ticketInfo!.totalQuantity} available - \$${event.ticketInfo!.price.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.black87),
                              ),
                            if (isRegistered)
                              const Text(
                                'Registered',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.info_outline, color: Colors.red),
                          onPressed: () => _showEventDetails(event),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
