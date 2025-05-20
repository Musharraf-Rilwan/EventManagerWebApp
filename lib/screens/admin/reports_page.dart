import 'package:flutter/material.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  const ReportsPage({
    super.key,
    this.refreshIndicatorKey,
  });

  @override
  State<ReportsPage> createState() => ReportsPageState();
}

class ReportsPageState extends State<ReportsPage> {
  final ReportService _reportService = ReportService();
  bool _isLoading = true;
  List<ReportModel> _reports = [];
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> refreshData() async {
    if (mounted) {
      await _loadReports();
    }
  }

  Future<void> _loadReports() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final reports = await _reportService.getAllReports();
      if (!mounted) return;
      
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reports: $e')),
      );
    }
  }

  Future<void> _generateReport(ReportType type) async {
    try {
      setState(() {
        _isLoading = true;
      });

      Map<String, dynamic> reportData;
      String name;
      String description;

      switch (type) {
        case ReportType.eventAttendance:
          reportData = await _reportService.generateEventAttendanceReport(_startDate, _endDate);
          name = 'Event Attendance Report';
          description = 'Event attendance statistics from ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}';
          break;
        case ReportType.userActivity:
          reportData = await _reportService.generateUserActivityReport(_startDate, _endDate);
          name = 'User Activity Report';
          description = 'User activity statistics from ${DateFormat('yyyy-MM-dd').format(_startDate)} to ${DateFormat('yyyy-MM-dd').format(_endDate)}';
          break;
        default:
          throw Exception('Unsupported report type');
      }

      final report = ReportModel(
        id: '',
        name: name,
        description: description,
        type: type,
        format: ReportFormat.csv,
        parameters: {
          'startDate': _startDate.toIso8601String(),
          'endDate': _endDate.toIso8601String(),
        },
        createdAt: DateTime.now(),
        createdBy: 'admin', // Replace with actual user ID
      );

      final reportId = await _reportService.createReport(report);
      final csvContent = await _reportService.generateReportCsv(reportData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generated successfully')),
        );
        refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating report: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      key: widget.refreshIndicatorKey,
      onRefresh: refreshData,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Reports',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showDateRangePicker,
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}',
                      ),
                    ),
                    const SizedBox(width: 16),
                    PopupMenuButton<ReportType>(
                      onSelected: _generateReport,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: ReportType.eventAttendance,
                          child: Text('Generate Event Attendance Report'),
                        ),
                        const PopupMenuItem(
                          value: ReportType.userActivity,
                          child: Text('Generate User Activity Report'),
                        ),
                      ],
                      child: ElevatedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.add),
                        label: const Text('Generate Report'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _reports.length,
                  itemBuilder: (context, index) {
                    final report = _reports[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(_getReportTypeIcon(report.type)),
                        title: Text(report.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(report.description),
                            const SizedBox(height: 4),
                            Text(
                              'Generated on: ${DateFormat('MMM d, y HH:mm').format(report.createdAt)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (report.isScheduled)
                              const Icon(
                                Icons.schedule,
                                color: Colors.blue,
                              ),
                            IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () {
                                // Download report
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Report'),
                                    content: const Text('Are you sure you want to delete this report?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await _reportService.deleteReport(report.id);
                                    refreshData();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error deleting report: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getReportTypeIcon(ReportType type) {
    switch (type) {
      case ReportType.eventAttendance:
        return Icons.people;
      case ReportType.userActivity:
        return Icons.trending_up;
      case ReportType.revenue:
        return Icons.attach_money;
      case ReportType.feedback:
        return Icons.feedback;
      case ReportType.custom:
        return Icons.assignment;
    }
  }
}
