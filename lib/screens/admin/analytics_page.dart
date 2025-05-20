import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import 'widgets/statistics_card.dart';
import 'package:fl_chart/fl_chart.dart';

class AnalyticsPage extends StatefulWidget {
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;

  const AnalyticsPage({
    super.key,
    this.refreshIndicatorKey,
  });

  @override
  State<AnalyticsPage> createState() => AnalyticsPageState();
}

class AnalyticsPageState extends State<AnalyticsPage> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  List<UserModel> _users = [];
  Map<UserRole, int> _roleDistribution = {};
  List<MapEntry<DateTime, int>> _registrationTrend = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> refreshData() async {
    if (mounted) {
      await _loadAnalytics();
    }
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all users
      final users = await _userService.getAllUsers();
      if (!mounted) return;
      
      setState(() {
        _users = users;
      });

      // Calculate role distribution
      _roleDistribution = {
        for (var role in UserRole.values) role: 0,
      };
      for (var user in _users) {
        _roleDistribution[user.role] = (_roleDistribution[user.role] ?? 0) + 1;
      }

      // Calculate registration trend (last 7 days)
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      Map<DateTime, int> dailyRegistrations = {};
      for (var i = 0; i < 7; i++) {
        final date = weekAgo.add(Duration(days: i));
        dailyRegistrations[date] = 0;
      }

      for (var user in _users) {
        if (user.createdAt.isAfter(weekAgo)) {
          final date = DateTime(
            user.createdAt.year,
            user.createdAt.month,
            user.createdAt.day,
          );
          dailyRegistrations[date] = (dailyRegistrations[date] ?? 0) + 1;
        }
      }

      _registrationTrend = dailyRegistrations.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      key: widget.refreshIndicatorKey,
      onRefresh: refreshData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildStatisticsCards(),
            const SizedBox(height: 32),
            _buildRoleDistributionChart(),
            const SizedBox(height: 32),
            _buildRegistrationTrendChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        StatisticsCard(
          title: 'Total Users',
          value: _users.length.toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        StatisticsCard(
          title: 'Event Organizers',
          value: (_roleDistribution[UserRole.organizer] ?? 0).toString(),
          icon: Icons.event,
          color: Colors.green,
        ),
        StatisticsCard(
          title: 'New Users (7 days)',
          value: _registrationTrend
              .map((e) => e.value)
              .reduce((a, b) => a + b)
              .toString(),
          icon: Icons.trending_up,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildRoleDistributionChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Role Distribution',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: _roleDistribution.entries.map((entry) {
                final color = _getRoleColor(entry.key);
                return PieChartSectionData(
                  color: color,
                  value: entry.value.toDouble(),
                  title: '${entry.key.toString().split('.').last}\n${entry.value}',
                  radius: 100,
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
              sectionsSpace: 2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationTrendChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Registration Trend (Last 7 Days)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= _registrationTrend.length) {
                        return const Text('');
                      }
                      final date = _registrationTrend[value.toInt()].key;
                      return Text(
                        '${date.day}/${date.month}',
                        style: const TextStyle(fontSize: 12),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: _registrationTrend
                      .asMap()
                      .entries
                      .map((entry) => FlSpot(
                            entry.key.toDouble(),
                            entry.value.value.toDouble(),
                          ))
                      .toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blue.withOpacity(0.2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.organizer:
        return Colors.green;
      case UserRole.attendee:
        return Colors.blue;
    }
  }
}
