import 'package:flutter/material.dart';
import 'package:renagro1/services/fincas_service.dart';
import 'package:renagro1/widgets/widgets.dart';
import 'package:intl/intl.dart';

class FincasFilterDropdownMenu extends StatefulWidget {
  final Function(Map<String, List<String>>) onFilterChanged;
  final String userRole;
  final String userName;

  const FincasFilterDropdownMenu({
    super.key,
    required this.onFilterChanged,
    required this.userRole,
    required this.userName,
  });

  @override
  FincasFilterDropdownMenuState createState() => FincasFilterDropdownMenuState();
}

class FincasFilterDropdownMenuState extends State<FincasFilterDropdownMenu> {
  final FincasService _fincasService = FincasService();
  Map<String, List<String>> filterOptions = {};
  Map<String, Set<String>> selectedFilters = {};
  Map<String, String> searchQueries = {};  // Store search queries for each filter
  bool isLoading = false;  // To track the loading state
  DateFormat dateFormat = DateFormat("dd-MM-yyyy");
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    loadFilters();
  }

  void loadFilters() {
    setState(() {
      filterOptions = {
        'fecha_entrevista': [],
        'registrador': [],
        'supervisor': [],
        'parcela_geolocalizada': [],
      };
      selectedFilters = {
        for (var key in filterOptions.keys) key: {},
      };  // Initialize as empty sets with default values for Estado
      searchQueries = { for (var key in filterOptions.keys) key: '' };
    });
  }

  void _showFechaFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> selectStartDate(BuildContext context) async {
              final DateTime? picked = await showDatePicker(
                confirmText: 'Aplicar',
                cancelText: 'Cancelar',
                context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                locale: const Locale('es', ''), // Set the locale to Spanish
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xff1d3b6f), // Header background color
                        onPrimary: Colors.white, // Header text color
                        onSurface: Colors.black, // Body text color
                      ),
                      dialogBackgroundColor: Colors.white, // Background color of the dialog
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != _startDate) {
                setStateDialog(() {
                  _startDate = picked;
                });
              }
            }

            Future<void> selectEndDate(BuildContext context) async {
              final DateTime? picked = await showDatePicker(
                confirmText: 'Aplicar',
                cancelText: 'Cancelar',
                context: context,
                initialDate: _endDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                locale: const Locale('es', ''), // Set the locale to Spanish
                builder: (BuildContext context, Widget? child) {
                  return Theme(
                    data: ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xff1d3b6f), // Header background color
                        onPrimary: Colors.white, // Header text color
                        onSurface: Colors.black, // Body text color
                      ),
                      dialogBackgroundColor: Colors.white, // Background color of the dialog
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null && picked != _endDate) {
                setStateDialog(() {
                  _endDate = picked;
                });
              }
            }

            return AlertDialog(
              actionsAlignment: MainAxisAlignment.center,
              backgroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              title: const Text('Seleccionar Rango de Fechas'),
              content: SizedBox(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Fecha de inicio:'),
                    TextButton(
                      onPressed: () => selectStartDate(context),
                      child: Text(
                        _startDate == null
                            ? 'Seleccionar fecha'
                            : dateFormat.format(_startDate!),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Fecha de fin:'),
                    TextButton(
                      onPressed: () => selectEndDate(context),
                      child: Text(
                        _endDate == null
                            ? 'Seleccionar fecha'
                            : dateFormat.format(_endDate!),
                      ),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Limpiar'),
                  onPressed: () {
                    setStateDialog(() {
                      _startDate = null;
                      _endDate = null;
                    });
                    setState(() {
                      selectedFilters['fecha_entrevista'] = {};
                      widget.onFilterChanged({for (var k in selectedFilters.keys) k: selectedFilters[k]!.toList()});
                    });
                  },
                ),
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Aplicar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (_startDate != null || _endDate != null) {
                      List<String> dates = [];
                      if (_startDate != null) {
                        dates.add(dateFormat.format(_startDate!));
                      }
                      if (_endDate != null) {
                        dates.add(dateFormat.format(_endDate!));
                      }
                      setState(() {
                        selectedFilters['fecha_entrevista'] = dates.toSet();
                        widget.onFilterChanged({for (var k in selectedFilters.keys) k: selectedFilters[k]!.toList()});
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRegionFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RegionDropdownFilter(
          userName: widget.userName,
          initialSelectedValues: {
            'regionalizacion_region': selectedFilters['regionalizacion_region']?.isNotEmpty ?? false
                ? selectedFilters['regionalizacion_region']!.first
                : null,
            'regionalizacion_zona': selectedFilters['regionalizacion_zona']?.isNotEmpty ?? false
                ? selectedFilters['regionalizacion_zona']!.first
                : null,
            'regionalizacion_subzona': selectedFilters['regionalizacion_subzona']?.isNotEmpty ?? false
                ? selectedFilters['regionalizacion_subzona']!.first
                : null,
            'regionalizacion_area': selectedFilters['regionalizacion_area']?.isNotEmpty ?? false
                ? selectedFilters['regionalizacion_area']!.first
                : null,
          },
          onFilterChanged: (values) {
            setState(() {
              selectedFilters['regionalizacion_region'] = {
                if (values['regionalizacion_region'] != null)
                  values['regionalizacion_region']!
              };
              selectedFilters['regionalizacion_zona'] = {
                if (values['regionalizacion_zona'] != null)
                  values['regionalizacion_zona']!
              };
              selectedFilters['regionalizacion_subzona'] = {
                if (values['regionalizacion_subzona'] != null)
                  values['regionalizacion_subzona']!
              };
              selectedFilters['regionalizacion_area'] = {
                if (values['regionalizacion_area'] != null)
                  values['regionalizacion_area']!
              };

              widget.onFilterChanged({
                'regionalizacion_region':
                    selectedFilters['regionalizacion_region']!.toList(),
                'regionalizacion_zona':
                    selectedFilters['regionalizacion_zona']!.toList(),
                'regionalizacion_subzona':
                    selectedFilters['regionalizacion_subzona']!.toList(),
                'regionalizacion_area':
                    selectedFilters['regionalizacion_area']!.toList(),
              });
            });
          },
        );
      },
    );
  }

  void _showTerritorioFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TerritorioDropdownFilter(
          userName: widget.userName,
          initialSelectedValues: {
            'territorial_region': selectedFilters['territorial_region']?.isNotEmpty ?? false
                ? selectedFilters['territorial_region']!.first
                : null,
            'territorial_provincia': selectedFilters['territorial_provincia']?.isNotEmpty ?? false
                ? selectedFilters['territorial_provincia']!.first
                : null,
            'territorial_municipio': selectedFilters['territorial_municipio']?.isNotEmpty ?? false
                ? selectedFilters['territorial_municipio']!.first
                : null,
            'territorial_distrito': selectedFilters['territorial_distrito']?.isNotEmpty ?? false
                ? selectedFilters['territorial_distrito']!.first
                : null,
            'territorial_seccion': selectedFilters['territorial_seccion']?.isNotEmpty ?? false
                ? selectedFilters['territorial_seccion']!.first
                : null,
            'territorial_paraje': selectedFilters['territorial_paraje']?.isNotEmpty ?? false
                ? selectedFilters['territorial_paraje']!.first
                : null,
          },
          onFilterChanged: (values) {
            setState(() {
              selectedFilters['territorial_region'] = {
                if (values['territorial_region'] != null)
                  values['territorial_region']!
              };
              selectedFilters['territorial_provincia'] = {
                if (values['territorial_provincia'] != null)
                  values['territorial_provincia']!
              };
              selectedFilters['territorial_municipio'] = {
                if (values['territorial_municipio'] != null)
                  values['territorial_municipio']!
              };
              selectedFilters['territorial_distrito'] = {
                if (values['territorial_distrito'] != null)
                  values['territorial_distrito']!
              };
              selectedFilters['territorial_seccion'] = {
                if (values['territorial_seccion'] != null)
                  values['territorial_seccion']!
              };
              selectedFilters['territorial_paraje'] = {
                if (values['territorial_paraje'] != null)
                  values['territorial_paraje']!
              };

              widget.onFilterChanged({
                'territorial_region':
                    selectedFilters['territorial_region']!.toList(),
                'territorial_provincia':
                    selectedFilters['territorial_provincia']!.toList(),
                'territorial_municipio':
                    selectedFilters['territorial_municipio']!.toList(),
                'territorial_distrito':
                    selectedFilters['territorial_distrito']!.toList(),
                'territorial_seccion':
                    selectedFilters['territorial_seccion']!.toList(),
                'territorial_paraje':
                    selectedFilters['territorial_paraje']!.toList(),
              });
            });
          },
        );
      },
    );
  }

  void _showRegistradorFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CheckboxFilter(
          filterName: 'registrador',
          fetchFilterOptions: _fincasService.fetchFilterOptions,
          initialSelectedValues: selectedFilters['registrador'] ?? {},
          onSelectedValuesChanged: (values) {
            setState(() {
              selectedFilters['registrador'] = values;
              widget.onFilterChanged({for (var k in selectedFilters.keys) k: selectedFilters[k]!.toList()});
            });
          },
          userName: widget.userName,
        );
      },
    );
  }

  void _showSupervisorFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CheckboxFilter(
          filterName: 'supervisor',
          fetchFilterOptions: _fincasService.fetchFilterOptions,
          initialSelectedValues: selectedFilters['supervisor'] ?? {},
          onSelectedValuesChanged: (values) {
            setState(() {
              selectedFilters['supervisor'] = values;
              widget.onFilterChanged({for (var k in selectedFilters.keys) k: selectedFilters[k]!.toList()});
            });
          },
          userName: widget.userName,
        );
      },
    );
  }

  void _showEstadoFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              actionsAlignment: MainAxisAlignment.center,
              backgroundColor: Colors.white,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
              title: const Text('Seleccionar Estado'),
              content: SizedBox(
                height: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CheckboxListTile(
                      value: selectedFilters['parcela_geolocalizada']?.contains('SI') ?? false,
                      title: const Text('Geolocalizada'),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? checked) {
                        setStateDialog(() {
                          if (checked ?? false) {
                            selectedFilters['parcela_geolocalizada']?.add('SI');
                          } else {
                            selectedFilters['parcela_geolocalizada']?.remove('SI');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      value: selectedFilters['parcela_geolocalizada']?.contains('NO') ?? false,
                      title: const Text('No Geolocalizada'),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? checked) {
                        setStateDialog(() {
                          if (checked ?? false) {
                            selectedFilters['parcela_geolocalizada']?.add('NO');
                          } else {
                            selectedFilters['parcela_geolocalizada']?.remove('NO');
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Limpiar'),
                  onPressed: () {
                    setStateDialog(() {
                      selectedFilters['parcela_geolocalizada'] = {};
                    });
                    setState(() {
                      widget.onFilterChanged({for (var k in selectedFilters.keys) k: selectedFilters[k]!.toList()});
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
                    Navigator.of(context).pop();
                    setState(() {
                      widget.onFilterChanged({for (var k in selectedFilters.keys) k: selectedFilters[k]!.toList()});
                    });
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _countSelectedFilters(String filterName) {
    int filterCount = selectedFilters[filterName]?.length ?? 0;
    if (filterCount != 0) {
      return ' ($filterCount)';
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (filterOptions.isNotEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () => _showFechaFilter(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1d3b6f),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text(
                    'Fecha${_countSelectedFilters('fecha_entrevista')}',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () => _showRegionFilter(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1d3b6f),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text('Región',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () => _showTerritorioFilter(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1d3b6f),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: const Text('Territorio',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
            Visibility(
              visible: widget.userRole != 'Interviewer',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton(
                  onPressed: () => _showRegistradorFilter(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1d3b6f),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                      'Registrador${_countSelectedFilters('registrador')}',
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
            Visibility(
              visible: widget.userRole != 'Interviewer' &&
                  widget.userRole != 'Supervisor',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton(
                  onPressed: () => _showSupervisorFilter(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1d3b6f),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                  child: Text(
                      'Supervisor${_countSelectedFilters('supervisor')}',
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ElevatedButton(
                onPressed: () => _showEstadoFilter(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff1d3b6f),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                ),
                child: Text(
                    'Estado${_countSelectedFilters('parcela_geolocalizada')}',
                    style: const TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } else {
      return const CircularProgressIndicator();
    }
  }
}
