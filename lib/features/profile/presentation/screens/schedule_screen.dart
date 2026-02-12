import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/atom_logo.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  String _frequency = 'daily';
  int _sendHour = 10;
  String _timezone = 'UTC';
  Set<int> _selectedDays = {1, 2, 3, 4, 5};
  bool _emailsSuspended = false;
  bool _isSaving = false;
  bool _hasChanges = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<String> _availableTimezones = ['UTC'];

  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _fullDayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get(AppConfig.schedule);
      final data = response.data as Map<String, dynamic>;
      
      if (!mounted) return;
      
      final schedule = data['schedule'] ?? {};
      setState(() {
        _frequency = schedule['email_frequency'] ?? 'daily';
        if (schedule['email_enabled'] == false) {
          _frequency = 'disabled';
        }
        _sendHour = schedule['preferred_send_hour'] ?? 10;
        _timezone = schedule['timezone'] ?? 'UTC';
        _emailsSuspended = schedule['emails_suspended'] == true;
        final days = schedule['selected_days'] as List? ?? [1, 2, 3, 4, 5];
        _selectedDays = days.map((d) => d as int).toSet();
        _availableTimezones = (data['available_timezones'] as List?)?.cast<String>() ?? ['UTC'];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is DioException ? e.friendlyMessage : 'Failed to load schedule';
        _isLoading = false;
      });
    }
  }

  void _saveSchedule() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);
      
      debugPrint('📱 Saving schedule: frequency=$_frequency, hour=$_sendHour, timezone=$_timezone, days=$_selectedDays');
      
      await dio.put(
        AppConfig.schedule,
        data: {
          'email_frequency': _frequency,
          'preferred_send_hour': _sendHour,
          'timezone': _timezone,
          'selected_days': _selectedDays.toList(),
          'emails_suspended': _emailsSuspended,
        },
      );

      debugPrint('📱 Schedule saved successfully');

      if (!mounted) return;

      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Schedule saved successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      debugPrint('📱 Schedule save error: $e');
      
      if (!mounted) return;
      
      setState(() => _isSaving = false);
      
      final message = e is DioException ? e.friendlyMessage : 'Failed to save schedule';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isSaving) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please wait for save to complete'),
              duration: Duration(seconds: 1),
            ),
          );
          return false;
        }
        // Allow back navigation - just return true, don't do anything else
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AtomIcon(size: 28),
              const SizedBox(width: 10),
              const Text('Email Schedule'),
            ],
          ),
          actions: [
            if (_hasChanges && !_isSaving)
              TextButton(
                onPressed: _saveSchedule,
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildError()
                : _buildScheduleForm(),
      ),
    );
  }

  Widget _buildScheduleForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: AppColors.primary.withValues(alpha:0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.schedule_outlined, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(_getScheduleDescription(), style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Suspend emails toggle
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              secondary: Icon(
                _emailsSuspended ? Icons.mail_lock_outlined : Icons.mail_outlined,
                color: _emailsSuspended ? Colors.orange.shade600 : AppColors.primary,
              ),
              title: const Text('Suspend Emails'),
              subtitle: const Text('Pause email delivery while keeping push and in-app notifications active'),
              value: _emailsSuspended,
              onChanged: (value) {
                setState(() {
                  _emailsSuspended = value;
                  _hasChanges = true;
                });
              },
              activeColor: Colors.orange.shade600,
            ),
          ),
          const SizedBox(height: 16),

          _buildSectionHeader('Delivery Frequency', Icons.repeat_outlined),
          const SizedBox(height: 12),
          _buildFrequencyOptions(),
          const SizedBox(height: 24),
          if (_frequency == 'custom' || _frequency == 'weekly') ...[
            _buildSectionHeader(_frequency == 'weekly' ? 'Delivery Day' : 'Delivery Days', Icons.calendar_today_outlined),
            const SizedBox(height: 12),
            _buildDaySelector(),
            const SizedBox(height: 24),
          ],
          if (_frequency != 'disabled') ...[
            _buildSectionHeader('Delivery Time', Icons.access_time_outlined),
            const SizedBox(height: 12),
            _buildTimeSelector(),
            const SizedBox(height: 24),
            _buildSectionHeader('Timezone', Icons.public_outlined),
            const SizedBox(height: 12),
            _buildTimezoneSelector(),
            const SizedBox(height: 32),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hasChanges && !_isSaving ? _saveSchedule : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
              child: _isSaving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildFrequencyOptions() {
    return Column(
      children: [
        _buildFrequencyTile('daily', 'Daily', 'Receive messages every day', Icons.calendar_view_day_outlined),
        _buildFrequencyTile('weekly', 'Weekly', 'Receive messages once a week', Icons.calendar_view_week_outlined),
        _buildFrequencyTile('custom', 'Custom', 'Choose specific days', Icons.edit_calendar_outlined),
        _buildFrequencyTile('disabled', 'Disabled', 'Pause all email notifications', Icons.notifications_off_outlined),
      ],
    );
  }

  Widget _buildFrequencyTile(String value, String title, String subtitle, IconData icon) {
    final isSelected = _frequency == value;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent, width: 2),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _frequency = value;
            _hasChanges = true;
            if (value == 'custom' && _selectedDays.isEmpty) _selectedDays = {1, 2, 3, 4, 5};
            if (value == 'weekly' && _selectedDays.isEmpty) _selectedDays = {1};
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha:0.1) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : Colors.black87)),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector() {
    final isWeekly = _frequency == 'weekly';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isWeekly ? 'Select the day to receive your weekly message:' : 'Select which days to receive messages:',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (index) {
                final isSelected = _selectedDays.contains(index);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isWeekly) {
                        _selectedDays = {index};
                      } else {
                        if (isSelected) _selectedDays.remove(index); else _selectedDays.add(index);
                      }
                      _hasChanges = true;
                    });
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(_dayNames[index], style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey.shade700)),
                  ),
                );
              }),
            ),
            if (!isWeekly) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  TextButton(onPressed: () { setState(() { _selectedDays = {1, 2, 3, 4, 5}; _hasChanges = true; }); }, child: const Text('Weekdays')),
                  TextButton(onPressed: () { setState(() { _selectedDays = {0, 1, 2, 3, 4, 5, 6}; _hasChanges = true; }); }, child: const Text('Every day')),
                  TextButton(onPressed: () { setState(() { _selectedDays = {}; _hasChanges = true; }); }, child: const Text('Clear')),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose when to receive your daily message:', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: ListWheelScrollView.useDelegate(
                itemExtent: 50,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                controller: FixedExtentScrollController(initialItem: _sendHour),
                onSelectedItemChanged: (index) { setState(() { _sendHour = index; _hasChanges = true; }); },
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: 24,
                  builder: (context, index) {
                    final isSelected = index == _sendHour;
                    final hour = index == 0 ? '12:00 AM' : index < 12 ? '$index:00 AM' : index == 12 ? '12:00 PM' : '${index - 12}:00 PM';
                    return Center(child: Text(hour, style: TextStyle(fontSize: isSelected ? 20 : 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : Colors.grey.shade600)));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimezoneSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DropdownButtonFormField<String>(
          value: _availableTimezones.contains(_timezone) ? _timezone : _availableTimezones.first,
          decoration: InputDecoration(
            labelText: 'Your Timezone',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.public_outlined),
          ),
          items: _availableTimezones.map((tz) => DropdownMenuItem(value: tz, child: Text(_formatTimezone(tz)))).toList(),
          onChanged: (value) { if (value != null) setState(() { _timezone = value; _hasChanges = true; }); },
        ),
      ),
    );
  }

  String _formatTimezone(String tz) {
    final tzNames = {
      'UTC': 'UTC',
      'America/New_York': 'Eastern (US)',
      'America/Chicago': 'Central (US)',
      'America/Denver': 'Mountain (US)',
      'America/Los_Angeles': 'Pacific (US)',
      'America/Toronto': 'Eastern (Canada)',
      'Europe/London': 'London',
      'Europe/Paris': 'Paris',
      'Europe/Berlin': 'Berlin',
      'Asia/Tokyo': 'Tokyo',
      'Asia/Shanghai': 'Shanghai',
      'Australia/Sydney': 'Sydney',
      'Pacific/Auckland': 'Auckland',
    };
    return tzNames[tz] ?? tz;
  }

  String _getScheduleDescription() {
    if (_emailsSuspended) return 'Emails suspended (push and in-app notifications active)';
    if (_frequency == 'disabled') return 'Email notifications are paused';
    final hour = _sendHour == 0 ? '12:00 AM' : _sendHour < 12 ? '$_sendHour:00 AM' : _sendHour == 12 ? '12:00 PM' : '${_sendHour - 12}:00 PM';
    if (_frequency == 'daily') return 'Every day at $hour ($_timezone)';
    if (_frequency == 'weekly') {
      final day = _selectedDays.isNotEmpty ? _fullDayNames[_selectedDays.first] : 'Monday';
      return 'Every $day at $hour ($_timezone)';
    }
    if (_frequency == 'custom') {
      if (_selectedDays.isEmpty) return 'No days selected';
      if (_selectedDays.length == 7) return 'Every day at $hour ($_timezone)';
      final days = _selectedDays.toList()..sort();
      return '${days.map((d) => _dayNames[d]).join(', ')} at $hour ($_timezone)';
    }
    return 'Unknown schedule';
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_errorMessage ?? 'Failed to load schedule', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Go Back')),
          ],
        ),
      ),
    );
  }
}
