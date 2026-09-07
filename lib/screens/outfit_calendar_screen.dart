import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/app_theme.dart';
import '../providers/outfit_provider.dart';
import '../providers/wardrobe_provider.dart';
import '../models/outfit.dart';
import '../services/notification_service.dart';
import '../widgets/item_image.dart';
import 'outfit_result_screen.dart';

class OutfitCalendarScreen extends StatefulWidget {
  const OutfitCalendarScreen({super.key});

  @override
  State<OutfitCalendarScreen> createState() => _OutfitCalendarScreenState();
}

class _OutfitCalendarScreenState extends State<OutfitCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final outfitProvider = context.watch<OutfitProvider>();
    final selected = _selectedDay ?? DateTime.now();
    final outfitsForDay = outfitProvider.outfitsForDate(selected);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Outfit Calendar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  eventLoader: (day) => outfitProvider.outfitsForDate(day),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: AppColors.gold,
                      shape: BoxShape.circle,
                    ),
                    outsideDaysVisible: false,
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSameDay(selected, DateTime.now())
                  ? 'TODAY'
                  : _formatDate(selected),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            if (outfitsForDay.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Text(
                      'No outfit planned for this day.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => _planOutfit(context, selected),
                      child: const Text('PLAN AN OUTFIT'),
                    ),
                  ],
                ),
              )
            else
              ...outfitsForDay.map((o) => _plannedOutfitCard(context, o)),
          ],
        ),
      ),
    );
  }

  Future<void> _planOutfit(BuildContext context, DateTime date) async {
    final outfitProvider = context.read<OutfitProvider>();
    final available = outfitProvider.savedOutfits;
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save an outfit first, then plan it on the calendar.'),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<Outfit>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: available
              .map(
                (o) => ListTile(
                  title: Text(o.name.isNotEmpty ? o.name : '${o.style} Fit'),
                  subtitle: Text('${o.scoreBreakdown.overall.round()}% match'),
                  onTap: () => Navigator.pop(ctx, o),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected != null) {
      await outfitProvider.planOutfit(selected.id, date);
      await NotificationService.scheduleOutfitReminder(
        outfit: selected,
        plannedDate: date,
      );
    }
  }

  Widget _plannedOutfitCard(BuildContext context, Outfit outfit) {
    final wardrobe = context.watch<WardrobeProvider>();
    final items = wardrobe.byIds(outfit.itemIds);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OutfitResultScreen(outfits: [outfit]),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Wrap(
              spacing: 4,
              children: items
                  .take(3)
                  .map((i) => ItemImage(item: i, size: 44))
                  .toList(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🔥 ${outfit.style} Fit',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${outfit.scoreBreakdown.overall.round()}% match',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
