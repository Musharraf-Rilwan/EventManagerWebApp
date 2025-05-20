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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ticket Confirmation',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.print, color: Colors.red),
            tooltip: 'Print Ticket',
            onPressed: () => _printTicket(context),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.red),
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
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Colors.black, width: 1),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.eventTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Purchase Date: ${DateFormat('MMM dd, yyyy').format(ticket.purchaseDate)}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ticket ID: ${ticket.id}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quantity: ${ticket.quantity}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Price: \$${ticket.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const Divider(height: 32, color: Colors.black),
                    const Text(
                      'Attendee Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Name: ${ticket.userName}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    Text(
                      'Email: ${ticket.userEmail}',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Use the print or share icons in the top right to get a copy of your ticket.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
