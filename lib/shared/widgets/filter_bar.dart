import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      );
}

class FilterRow extends StatelessWidget {
  final String label;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  const FilterRow(
      {super.key,
      required this.label,
      required this.options,
      required this.selected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final o in options)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(o),
                    selected: o == selected,
                    onSelected: (_) => onSelected(o),
                    selectedColor: AppColors.navy,
                    labelStyle: TextStyle(
                        color: o == selected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontSize: 13),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
