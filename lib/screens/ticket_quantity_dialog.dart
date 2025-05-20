import 'package:flutter/material.dart';

class TicketQuantityDialog extends StatefulWidget {
  final int availableQuantity;
  final double price;

  const TicketQuantityDialog({
    super.key,
    required this.availableQuantity,
    required this.price,
  });

  @override
  State<TicketQuantityDialog> createState() => _TicketQuantityDialogState();
}

class _TicketQuantityDialogState extends State<TicketQuantityDialog> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text(
        'Select Ticket Quantity',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.red),
                onPressed:
                    _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Text(
                _quantity.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.red),
                onPressed: _quantity < widget.availableQuantity
                    ? () => setState(() => _quantity++)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Total: \$${(widget.price * _quantity).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
          onPressed: () => Navigator.of(context).pop(_quantity),
        ),
      ],
    );
  }
}
