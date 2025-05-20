import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../models/ticket_model.dart';
import '../services/auth_service.dart';
import '../services/ticket_service.dart';
import 'ticket_quantity_dialog.dart';
import 'ticket_confirmation_screen.dart';
import 'package:intl/intl.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _ticketService = TicketService();
  bool _isLoading = false;
  bool _hasRegistered = false;
  List<TicketModel> _userTickets = [];

  @override
  void initState() {
    super.initState();
    _checkRegistrationStatus();
  }

  Future<void> _checkRegistrationStatus() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tickets = await _ticketService.getUserTickets(currentUser.uid);

      // Check if any of the user's tickets are for this event
      final eventTickets =
          tickets.where((ticket) => ticket.eventId == widget.event.id).toList();

      setState(() {
        _userTickets = eventTickets;
        _hasRegistered = eventTickets.isNotEmpty;
      });
    } catch (e) {
      // Handle error silently
      print('Error checking registration status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleBooking(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book tickets')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    if (!context.mounted) return;
    final quantity = await showDialog<int>(
      context: context,
      builder: (context) => TicketQuantityDialog(
        availableQuantity: widget.event.ticketInfo?.availableQuantity ?? 0,
        price: widget.event.ticketInfo?.price ?? 0.0,
      ),
    );

    if (quantity == null || quantity <= 0) return;

    try {
      final ticket = await _ticketService.purchaseTickets(
        widget.event,
        currentUser.uid,
        currentUser.email!,
        currentUser.displayName ?? 'Guest',
        quantity,
      );

      // Update registration status after booking
      setState(() {
        _hasRegistered = true;
        _userTickets.add(ticket);
      });

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TicketConfirmationScreen(ticket: ticket),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error booking tickets: $e')),
      );
    }
  }

  void _viewTickets() {
    if (_userTickets.isEmpty) return;

    // Show the first ticket (most recent)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            TicketConfirmationScreen(ticket: _userTickets.first),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTicketsAvailable =
        (widget.event.ticketInfo?.availableQuantity ?? 0) > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.red),
          onPressed: () => Navigator.pop(context),
        ),
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, MMMM d, y')
                              .format(widget.event.date),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('h:mm a').format(widget.event.date),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.black),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event.location,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'About This Event',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.event.description,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ticket Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Price per ticket:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '\$${widget.event.ticketInfo?.price.toStringAsFixed(2) ?? "0.00"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available tickets:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '${widget.event.ticketInfo?.availableQuantity ?? 0}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      )
                    else if (_hasRegistered)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            border: Border.all(color: Colors.green.shade700),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'You have registered for this event',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _viewTickets,
                                child: const Text(
                                  'View Ticket',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _hasRegistered
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed:
                      isTicketsAvailable ? () => _handleBooking(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    isTicketsAvailable ? 'Book Tickets' : 'Sold Out',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
