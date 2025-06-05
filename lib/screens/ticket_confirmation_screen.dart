import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/ticket_model.dart';
import '../services/ticket_pdf_service.dart';

class TicketConfirmationScreen extends StatelessWidget {
  final TicketModel ticket;
  final _pdfService = TicketPdfService();

  TicketConfirmationScreen({super.key, required this.ticket});

  Future<void> _printTicket(BuildContext context) async {
    try {
      final pdfData = await _pdfService.generateTicketPdf(ticket);
      await Printing.layoutPdf(
        onLayout: (format) => pdfData,
        name: 'Event_Ticket_${ticket.id}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareTicket(BuildContext context) async {
    try {
      final pdfData = await _pdfService.generateTicketPdf(ticket);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/Event_Ticket_${ticket.id}.pdf');
      await file.writeAsBytes(pdfData);

      if (context.mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Event Ticket - ${ticket.eventTitle}',
          text: 'Here is your ticket for ${ticket.eventTitle}',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing ticket: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ticket Confirmation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Ticket',
            onPressed: () => _printTicket(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Ticket',
            onPressed: () => _shareTicket(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Thank you for your purchase!',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.eventTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Purchase Date: ${DateFormat('MMM dd, yyyy').format(ticket.purchaseDate)}',
                    ),
                    const SizedBox(height: 8),
                    Text('Ticket ID: ${ticket.id}'),
                    const SizedBox(height: 8),
                    Text('Quantity: ${ticket.quantity}'),
                    const SizedBox(height: 8),
                    Text(
                      'Total Price: \*${ticket.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(height: 32),
                    Text(
                      'Attendee Information',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Name: ${ticket.userName}'),
                    Text('Email: ${ticket.userEmail}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Use the print or share icons in the top right to get a copy of your ticket.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
