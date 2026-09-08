import 'package:flutter/cupertino.dart';
import '../theme.dart';

class CustomNumericDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onDateTimeChanged;
  final int minYear;
  final DateTime maxDate;

  const CustomNumericDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateTimeChanged,
    required this.minYear,
    required this.maxDate,
  });

  @override
  State<CustomNumericDatePicker> createState() => _CustomNumericDatePickerState();
}

class _CustomNumericDatePickerState extends State<CustomNumericDatePicker> {
  late int day;
  late int month;
  late int year;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    day = widget.initialDate.day;
    month = widget.initialDate.month;
    year = widget.initialDate.year;

    _dayController = FixedExtentScrollController(initialItem: day - 1);
    _monthController = FixedExtentScrollController(initialItem: month - 1);
    _yearController = FixedExtentScrollController(initialItem: year - widget.minYear);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  int _getDaysInMonth(int y, int m) {
    if (m == 2) {
      bool isLeap = (y % 4 == 0) && ((y % 100 != 0) || (y % 400 == 0));
      return isLeap ? 29 : 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[m - 1];
  }

  void _updateDate() {
    int maxDays = _getDaysInMonth(year, month);
    if (day > maxDays) {
      day = maxDays;
      _dayController.jumpToItem(day - 1);
    }
    
    DateTime newDate = DateTime(year, month, day);
    if (newDate.isAfter(widget.maxDate)) {
      newDate = widget.maxDate;
      year = newDate.year;
      month = newDate.month;
      day = newDate.day;
      _yearController.jumpToItem(year - widget.minYear);
      _monthController.jumpToItem(month - 1);
      _dayController.jumpToItem(day - 1);
    }

    widget.onDateTimeChanged(newDate);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    int maxDays = _getDaysInMonth(year, month);

    return Row(
      children: [
        // Day Column
        Expanded(
          child: CupertinoPicker.builder(
            scrollController: _dayController,
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              day = index + 1;
              _updateDate();
            },
            childCount: maxDays,
            itemBuilder: (context, index) {
              return Center(
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 20, color: AppTheme.textPrimary),
                ),
              );
            },
          ),
        ),
        // Month Column
        Expanded(
          child: CupertinoPicker.builder(
            scrollController: _monthController,
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              month = index + 1;
              _updateDate();
            },
            childCount: 12,
            itemBuilder: (context, index) {
              return Center(
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: const TextStyle(fontSize: 20, color: AppTheme.textPrimary),
                ),
              );
            },
          ),
        ),
        // Year Column
        Expanded(
          child: CupertinoPicker.builder(
            scrollController: _yearController,
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              year = widget.minYear + index;
              _updateDate();
            },
            childCount: widget.maxDate.year - widget.minYear + 1,
            itemBuilder: (context, index) {
              return Center(
                child: Text(
                  (widget.minYear + index).toString(),
                  style: const TextStyle(fontSize: 20, color: AppTheme.textPrimary),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
