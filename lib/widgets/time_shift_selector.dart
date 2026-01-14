import 'package:asnan_hub/models/case.dart';
import 'package:flutter/material.dart';

class TimeShiftSelector extends StatelessWidget {
  final TimeShift? selectedShift;
  final Function(TimeShift) onShiftSelected;
  final String label;

   TimeShiftSelector({
    super.key,
    required this.selectedShift,
    required this.onShiftSelected,
    required this.label,

  });

  String _getShiftLabel(TimeShift shift) {
    switch (shift) {
      case TimeShift.morning:
        return 'Morning (8 AM - 12 PM)';
      case TimeShift.afternoon:
        return 'Afternoon (12 PM - 4 PM)';
      case TimeShift.evening:
        return 'Evening (4 PM - 8 PM)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 12),
        ...TimeShift.values.map((shift) {
          final isSelected = selectedShift == shift;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => onShiftSelected(shift),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          width: 2,
                        ),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _getShiftLabel(shift),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}







