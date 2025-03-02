import 'package:flutter/material.dart';
import 'package:renagro1/services/fincas_service.dart';

class TerritorioDropdownFilter extends StatefulWidget {
  final Function(Map<String, String?>) onFilterChanged;
  final String userName;
  final Map<String, String?> initialSelectedValues;

  const TerritorioDropdownFilter({
    super.key,
    required this.onFilterChanged,
    required this.userName,
    required this.initialSelectedValues,
  });

  @override
  TerritorioDropdownFilterState createState() => TerritorioDropdownFilterState();
}

class TerritorioDropdownFilterState extends State<TerritorioDropdownFilter> {
  final FincasService _fincasService = FincasService();
  List<String> regionOptions = [];
  List<String> provinciaOptions = [];
  List<String> municipioOptions = [];
  List<String> distritoOptions = [];
  List<String> seccionOptions = [];
  List<String> parajeOptions = [];

  String? selectedRegion;
  String? selectedProvincia;
  String? selectedMunicipio;
  String? selectedDistrito;
  String? selectedSeccion;
  String? selectedParaje;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedRegion = widget.initialSelectedValues['territorial_region'];
    selectedProvincia = widget.initialSelectedValues['territorial_provincia'];
    selectedMunicipio = widget.initialSelectedValues['territorial_municipio'];
    selectedDistrito = widget.initialSelectedValues['territorial_distrito'];
    selectedSeccion = widget.initialSelectedValues['territorial_seccion'];
    selectedParaje = widget.initialSelectedValues['territorial_paraje'];

    // Fetch initial options based on current selections
    _fetchInitialOptions();
  }

  Future<void> _fetchInitialOptions() async {
    await _fetchOptionsForLevel(1);
    if (selectedRegion != null && selectedRegion!.isNotEmpty) await _fetchOptionsForLevel(2);
    if (selectedProvincia != null && selectedProvincia!.isNotEmpty) await _fetchOptionsForLevel(3);
    if (selectedMunicipio != null && selectedMunicipio!.isNotEmpty) await _fetchOptionsForLevel(4);
    if (selectedDistrito != null && selectedDistrito!.isNotEmpty) await _fetchOptionsForLevel(5);
    if (selectedSeccion != null && selectedSeccion!.isNotEmpty) await _fetchOptionsForLevel(6);
  }

  Future<void> _fetchOptionsForLevel(int level) async {
    setState(() {
      isLoading = true;
    });

    Map<String, String> payload = {
      "region": level > 1 ? selectedRegion ?? '' : '',
      "provincia": level > 2 ? selectedProvincia ?? '' : '',
      "municipio": level > 3 ? selectedMunicipio ?? '' : '',
      "distrito": level > 4 ? selectedDistrito ?? '' : '',
      "seccion": level > 5 ? selectedSeccion ?? '' : '',
      "paraje": level > 6 ? selectedParaje ?? '' : '',
    };

    final options = await _fincasService.fetchTerritorioOptions(payload);

    setState(() {
      isLoading = false;
      if (level == 1) {
        regionOptions = options.toSet().toList();
      } else if (level == 2) {
        provinciaOptions = options.toSet().toList();
      } else if (level == 3) {
        municipioOptions = options.toSet().toList();
      } else if (level == 4) {
        distritoOptions = options.toSet().toList();
      } else if (level == 5) {
        seccionOptions = options.toSet().toList();
      } else if (level == 6) {
        parajeOptions = options.toSet().toList();
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
      title: const Text('Filtrar por Territorio'),
      content: SizedBox(
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDropdownMenu("Region", regionOptions, selectedRegion, (value) {
              setState(() {
                selectedRegion = value;
                selectedProvincia = null;
                selectedMunicipio = null;
                selectedDistrito = null;
                selectedSeccion = null;
                selectedParaje = null;
                provinciaOptions = [];
                municipioOptions = [];
                distritoOptions = [];
                seccionOptions = [];
                parajeOptions = [];
              });
              _fetchOptionsForLevel(2);
            }),
            _buildDropdownMenu("Provincia", provinciaOptions, selectedProvincia, (value) {
              setState(() {
                selectedProvincia = value;
                selectedMunicipio = null;
                selectedDistrito = null;
                selectedSeccion = null;
                selectedParaje = null;
                municipioOptions = [];
                distritoOptions = [];
                seccionOptions = [];
                parajeOptions = [];
              });
              _fetchOptionsForLevel(3);
            }),
            _buildDropdownMenu("Municipio", municipioOptions, selectedMunicipio, (value) {
              setState(() {
                selectedMunicipio = value;
                selectedDistrito = null;
                selectedSeccion = null;
                selectedParaje = null;
                distritoOptions = [];
                seccionOptions = [];
                parajeOptions = [];
              });
              _fetchOptionsForLevel(4);
            }),
            _buildDropdownMenu("Distrito", distritoOptions, selectedDistrito, (value) {
              setState(() {
                selectedDistrito = value;
                selectedSeccion = null;
                selectedParaje = null;
                seccionOptions = [];
                parajeOptions = [];
              });
              _fetchOptionsForLevel(5);
            }),
            _buildDropdownMenu("Sección", seccionOptions, selectedSeccion, (value) {
              setState(() {
                selectedSeccion = value;
                selectedParaje = null;
                parajeOptions = [];
              });
              _fetchOptionsForLevel(6);
            }),
            _buildDropdownMenu("Paraje", parajeOptions, selectedParaje, (value) {
              setState(() {
                selectedParaje = value;
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
              selectedProvincia = null;
              selectedMunicipio = null;
              selectedDistrito = null;
              selectedSeccion = null;
              selectedParaje = null;
              regionOptions = [];
              provinciaOptions = [];
              municipioOptions = [];
              distritoOptions = [];
              seccionOptions = [];
              parajeOptions = [];
            });
            widget.onFilterChanged({
              "territorial_region": null,
              "territorial_provincia": null,
              "territorial_municipio": null,
              "territorial_distrito": null,
              "territorial_seccion": null,
              "territorial_paraje": null,
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
              "territorial_region": selectedRegion,
              "territorial_provincia": selectedProvincia,
              "territorial_municipio": selectedMunicipio,
              "territorial_distrito": selectedDistrito,
              "territorial_seccion": selectedSeccion,
              "territorial_paraje": selectedParaje,
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
