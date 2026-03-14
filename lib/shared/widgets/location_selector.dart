import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodbridge/core/constants/app_constants.dart';

/// Data model for a Kerala sub-district (taluk) with its villages.
class _SubDistrict {
  final String name;
  final List<String> villages;
  _SubDistrict({required this.name, required this.villages});
}

/// Data model for a Kerala district with its sub-districts.
class _District {
  final String name;
  final List<_SubDistrict> subDistricts;
  _District({required this.name, required this.subDistricts});
}

/// Loads and parses the kerala.json asset into a list of [_District] objects.
Future<List<_District>> _loadKeralaDistricts() async {
  final jsonStr = await rootBundle.loadString('assets/kerala.json');
  final Map<String, dynamic> raw = json.decode(jsonStr);
  final List districts = raw['districts'] as List;
  return districts.map((d) {
    final subList = (d['subDistricts'] as List).map((s) {
      return _SubDistrict(
        name: s['subDistrict'] as String,
        villages: List<String>.from(s['villages'] as List),
      );
    }).toList();
    return _District(name: d['district'] as String, subDistricts: subList);
  }).toList();
}

/// A reusable widget that shows hierarchical location selection:
/// **State (Kerala) → District → Sub-district (Taluk) → Village**
/// 
/// The `onChanged` callback fires when all three levels (district, 
/// sub-district, village) have been selected.
class LocationSelector extends StatefulWidget {
  final String? initialDistrict;
  final String? initialSubDistrict;
  final String? initialVillage;

  /// Called when all three levels of location have been selected.
  /// Parameters: (district, subDistrict, village)
  final void Function(String district, String subDistrict, String village) onChanged;

  const LocationSelector({
    super.key,
    this.initialDistrict,
    this.initialSubDistrict,
    this.initialVillage,
    required this.onChanged,
  });

  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  late Future<List<_District>> _districtsFuture;

  _District? _selectedDistrict;
  _SubDistrict? _selectedSubDistrict;
  String? _selectedVillage;

  @override
  void initState() {
    super.initState();
    _districtsFuture = _loadKeralaDistricts().then((list) {
      // Restore initial values if provided
      if (widget.initialDistrict != null) {
        _selectedDistrict = list.firstWhere(
          (d) => d.name == widget.initialDistrict,
          orElse: () => list.first,
        );
        if (widget.initialSubDistrict != null && _selectedDistrict != null) {
          _selectedSubDistrict = _selectedDistrict!.subDistricts.firstWhere(
            (s) => s.name == widget.initialSubDistrict,
            orElse: () => _selectedDistrict!.subDistricts.first,
          );
          if (widget.initialVillage != null && _selectedSubDistrict != null) {
            _selectedVillage = widget.initialVillage;
          }
        }
      }
      return list;
    });
  }

  void _notify() {
    if (_selectedDistrict != null &&
        _selectedSubDistrict != null &&
        _selectedVillage != null) {
      widget.onChanged(
        _selectedDistrict!.name,
        _selectedSubDistrict!.name,
        _selectedVillage!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_District>>(
      future: _districtsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text('Failed to load location data', style: TextStyle(color: Colors.red));
        }

        final districts = snapshot.data ?? [];

        final subDistricts = _selectedDistrict?.subDistricts ?? <_SubDistrict>[];
        final villages = _selectedSubDistrict?.villages ?? <String>[];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: AppDesign.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Kerala, India', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // District
              _buildDropdown<_District>(
                label: 'District',
                icon: Icons.map_outlined,
                value: _selectedDistrict,
                items: districts,
                displayText: (d) => d.name,
                hint: 'Select District',
                onChanged: (val) {
                  setState(() {
                    _selectedDistrict = val;
                    _selectedSubDistrict = null;
                    _selectedVillage = null;
                  });
                  _notify();
                },
              ),
              const SizedBox(height: 12),

              // Sub-district (Taluk)
              _buildDropdown<_SubDistrict>(
                label: 'Taluk / Sub-District',
                icon: Icons.location_city_outlined,
                value: _selectedSubDistrict,
                items: subDistricts,
                displayText: (s) => s.name,
                hint: 'Select Taluk',
                onChanged: _selectedDistrict == null
                    ? null
                    : (val) {
                        setState(() {
                          _selectedSubDistrict = val;
                          _selectedVillage = null;
                        });
                        _notify();
                      },
              ),
              const SizedBox(height: 12),

              // Village
              _buildDropdown<String>(
                label: 'Village / Area',
                icon: Icons.home_outlined,
                value: villages.contains(_selectedVillage) ? _selectedVillage : null,
                items: villages,
                displayText: (v) => v,
                hint: 'Select Village / Area',
                onChanged: _selectedSubDistrict == null
                    ? null
                    : (val) {
                        setState(() => _selectedVillage = val);
                        _notify();
                      },
              ),

              // Selected location badge
              if (_selectedDistrict != null &&
                  _selectedSubDistrict != null &&
                  _selectedVillage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondary.withAlpha(40)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.secondary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_selectedVillage, ${_selectedSubDistrict!.name}, ${_selectedDistrict!.name}, Kerala',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<T> items,
    required String Function(T) displayText,
    required String hint,
    required void Function(T?)? onChanged,
  }) {
    final isEnabled = onChanged != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isEnabled ? AppColors.textSecondary : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 6),
        AnimatedOpacity(
          opacity: isEnabled ? 1.0 : 0.5,
          duration: const Duration(milliseconds: 200),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.grey[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEnabled ? Colors.grey[300]! : Colors.grey[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: isEnabled ? AppColors.primary : Colors.grey[400]),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<T>(
                      isExpanded: true,
                      value: value,
                      hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                      icon: Icon(Icons.keyboard_arrow_down, color: isEnabled ? Colors.grey : Colors.grey[400]),
                      items: items.map((item) {
                        return DropdownMenuItem<T>(
                          value: item,
                          child: Text(displayText(item), style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: isEnabled ? onChanged : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
