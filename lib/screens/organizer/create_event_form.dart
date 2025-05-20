import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../services/auth_service.dart';

class CreateEventForm extends StatefulWidget {
  final Function(EventModel) onSubmit;
  final EventModel? eventToEdit;

  const CreateEventForm({
    super.key,
    required this.onSubmit,
    this.eventToEdit,
  });

  @override
  State<CreateEventForm> createState() => _CreateEventFormState();
}

class _CreateEventFormState extends State<CreateEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedType;
  bool _hasTickets = false;

  final List<String> _eventTypes = [
    'Conference',
    'Workshop',
    'Seminar',
    'Networking',
    'Party',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      _titleController.text = widget.eventToEdit!.title;
      _descriptionController.text = widget.eventToEdit!.description;
      _locationController.text = widget.eventToEdit!.location;
      _selectedDate = widget.eventToEdit!.date;
      _selectedTime = widget.eventToEdit!.time;
      _selectedType = widget.eventToEdit!.type;
      
      if (widget.eventToEdit!.ticketInfo != null) {
        _hasTickets = true;
        _priceController.text = widget.eventToEdit!.ticketInfo!.price.toString();
        _quantityController.text = widget.eventToEdit!.ticketInfo!.totalQuantity.toString();
      }
    } else {
      _selectedDate = DateTime.now().add(const Duration(days: 1));
      _selectedTime = TimeOfDay.now();
      _selectedType = _eventTypes[0];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser?.uid;
      
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to create events'),
          ),
        );
        return;
      }

      TicketInfo? ticketInfo;
      if (_hasTickets) {
        final price = double.parse(_priceController.text);
        final quantity = int.parse(_quantityController.text);
        ticketInfo = TicketInfo(
          price: price,
          totalQuantity: quantity,
          availableQuantity: quantity,
          isEnabled: true,
        );
      }

      final event = EventModel(
        id: widget.eventToEdit?.id ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        location: _locationController.text,
        date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
        time: _selectedTime,
        type: _selectedType,
        createdBy: userId,
        attendees: widget.eventToEdit?.attendees ?? [],
        ticketInfo: ticketInfo,
      );

      widget.onSubmit(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Event Title',
              labelStyle: TextStyle(color: Colors.black),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            style: const TextStyle(color: Colors.black),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an event title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(
              labelText: 'Event Type',
              labelStyle: TextStyle(color: Colors.black),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black),
            items: _eventTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(color: Colors.black),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            style: const TextStyle(color: Colors.black),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an event description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Venue',
              labelStyle: TextStyle(color: Colors.black),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
            ),
            style: const TextStyle(color: Colors.black),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an event venue';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Date picker
          ListTile(
            title: const Text('Event Date', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            subtitle: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
              style: const TextStyle(color: Colors.black87),
            ),
            trailing: const Icon(Icons.calendar_today, color: Colors.red),
            onTap: _selectDate,
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.black),
            ),
          ),
          const SizedBox(height: 16),

          // Time picker
          ListTile(
            title: const Text('Event Time', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            subtitle: Text(
              _selectedTime.format(context),
              style: const TextStyle(color: Colors.black87),
            ),
            trailing: const Icon(Icons.access_time, color: Colors.red),
            onTap: _selectTime,
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.black),
            ),
          ),
          const SizedBox(height: 24),

          // Ticket section
          SwitchListTile(
            title: const Text('Enable Tickets', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            value: _hasTickets,
            activeColor: Colors.red,
            onChanged: (bool value) {
              setState(() {
                _hasTickets = value;
              });
            },
          ),

          if (_hasTickets) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Ticket Price',
                labelStyle: TextStyle(color: Colors.black),
                prefixText: '\$',
                prefixStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a ticket price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Total Tickets',
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
              style: const TextStyle(color: Colors.black),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the number of tickets';
                }
                if (int.tryParse(value) == null || int.parse(value) <= 0) {
                  return 'Please enter a valid number of tickets';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              widget.eventToEdit == null ? 'Create Event' : 'Update Event',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
