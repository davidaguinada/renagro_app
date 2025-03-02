import 'package:flutter/material.dart';
import 'package:renagro1/services/fincas_service.dart';

class RegionDropdownFilter extends StatefulWidget {
  final Function(Map<String, String?>) onFilterChanged;
  final String userName;
  final Map<String, String?> initialSelectedValues;

  const RegionDropdownFilter({
    super.key,
    required this.onFilterChanged,
    required this.userName,
    required this.initialSelectedValues,
  });

  @override
  RegionDropdownFilterState createState() => RegionDropdownFilterState();
}

class RegionDropdownFilterState extends State<RegionDropdownFilter> {
  final FincasService _fincasService = FincasService();
  List<String> regionOptions = [];
  List<String> zonaOptions = [];
  List<String> subzonaOptions = [];
  List<String> areaOptions = [];

  String? selectedRegion;
  String? selectedZona;
  String? selectedSubzona;
  String? selectedArea;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedRegion = widget.initialSelectedValues['regionalizacion_region'];
    selectedZona = widget.initialSelectedValues['regionalizacion_zona'];
    selectedSubzona = widget.initialSelectedValues['regionalizacion_subzona'];
    selectedArea = widget.initialSelectedValues['regionalizacion_area'];

    // Fetch initial options based on current selections
    _fetchInitialOptions();
  }

  Future<void> _fetchInitialOptions() async {
    await _fetchOptionsForLevel(1);
    if (selectedRegion != null && selectedRegion!.isNotEmpty) await _fetchOptionsForLevel(2);
    if (selectedZona != null && selectedZona!.isNotEmpty) await _fetchOptionsForLevel(3);
    if (selectedSubzona != null && selectedSubzona!.isNotEmpty) await _fetchOptionsForLevel(4);
  }

  Future<void> _fetchOptionsForLevel(int level) async {
    setState(() {
      isLoading = true;
    });

    Map<String, String> payload = {
      "region": level > 1 ? selectedRegion ?? '' : '',
      "zona": level > 2 ? selectedZona ?? '' : '',
      "subzona": level > 3 ? selectedSubzona ?? '' : '',
      "area": level > 4 ? selectedArea ?? '' : '',
    };

    final options = await _fincasService.fetchRegionalizacionOptions(payload);

    setState(() {
      isLoading = false;
      if (level == 1) {
        regionOptions = options.toSet().toList();
      } else if (level == 2) {
        zonaOptions = options.toSet().toList();
      } else if (level == 3) {
        subzonaOptions = options.toSet().toList();
      } else if (level == 4) {
        areaOptions = options.toSet().toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      actionsAlignment: MainAxisAlignment.center,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      title: const Text('Filtrar por Región'),
      content: SizedBox(
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDropdownMenu("Region", regionOptions, selectedRegion, (value) {
              setState(() {
                selectedRegion = value;
                selectedZona = null;
                selectedSubzona = null;
                selectedArea = null;
                zonaOptions = [];
                subzonaOptions = [];
                areaOptions = [];
              });
              _fetchOptionsForLevel(2);
            }),
            _buildDropdownMenu("Zona", zonaOptions, selectedZona, (value) {
              setState(() {
                selectedZona = value;
                selectedSubzona = null;
                selectedArea = null;
                subzonaOptions = [];
                areaOptions = [];
              });
              _fetchOptionsForLevel(3);
            }),
            _buildDropdownMenu("Subzona", subzonaOptions, selectedSubzona, (value) {
              setState(() {
                selectedSubzona = value;
                selectedArea = null;
                areaOptions = [];
              });
              _fetchOptionsForLevel(4);
            }),
            _buildDropdownMenu("Area", areaOptions, selectedArea, (value) {
              setState(() {
                selectedArea = value;
              });
            }),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Limpiar'),
          onPressed: () {
            setState(() {
              selectedRegion = null;
              selectedZona = null;
              selectedSubzona = null;
              selectedArea = null;
              regionOptions = [];
              zonaOptions = [];
              subzonaOptions = [];
              areaOptions = [];
            });
            widget.onFilterChanged({
              "regionalizacion_region": null,
              "regionalizacion_zona": null,
              "regionalizacion_subzona": null,
              "regionalizacion_area": null,
            });
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Aplicar'),
          onPressed: () {
            Map<String, String?> filters = {
              "regionalizacion_region": selectedRegion,
              "regionalizacion_zona": selectedZona,
              "regionalizacion_subzona": selectedSubzona,
              "regionalizacion_area": selectedArea,
            };
            widget.onFilterChanged(filters);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Widget _buildDropdownMenu(String label, List<String> options, String? selectedValue, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButton<String>(
        value: options.contains(selectedValue) ? selectedValue : null,
        isExpanded: true,
        hint: Text(label),
        items: options.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
