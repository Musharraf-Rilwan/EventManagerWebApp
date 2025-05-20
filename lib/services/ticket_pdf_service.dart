import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/ticket_model.dart';

class TicketPdfService {
  Future<Uint8List> generateTicketPdf(TicketModel ticket) async {
    final pdf = pw.Document();

    // Create a structured QR code data
    final qrData = {
      'ticketId': ticket.id,
      'eventId': ticket.eventId,
      'eventTitle': ticket.eventTitle,
      'userName': ticket.userName,
      'quantity': ticket.quantity.toString(),
      'purchaseDate': DateFormat('yyyy-MM-dd').format(ticket.purchaseDate),
    }.entries.map((e) => '${e.key}:${e.value}').join('|');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'Event Ticket',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Event: ${ticket.eventTitle}',
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text('Ticket ID: ${ticket.id}'),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Purchase Date: ${DateFormat('MMM dd, yyyy').format(ticket.purchaseDate)}',
                ),
                pw.SizedBox(height: 10),
                pw.Text('Quantity: ${ticket.quantity}'),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Total Price: \$${ticket.totalPrice.toStringAsFixed(2)}',
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Text('Attendee Information:'),
                pw.SizedBox(height: 10),
                pw.Text('Name: ${ticket.userName}'),
                pw.Text('Email: ${ticket.userEmail}'),
                pw.Expanded(child: pw.SizedBox()),
                pw.Center(
                  child: pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: qrData,
                    width: 100,
                    height: 100,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'This is an official ticket. Please present this at the event.',
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }
}
