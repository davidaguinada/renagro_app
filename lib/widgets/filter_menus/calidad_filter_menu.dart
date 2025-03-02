import 'package:flutter/material.dart';
import 'package:renagro1/services/calidad_service.dart';
import 'package:renagro1/widgets/widgets.dart';
import 'package:intl/intl.dart';

class CalidadFilterDropdownMenu extends StatefulWidget {
  final Function(Map<String, List<String>>) onFilterChanged;
  final String userRole;
  final String userName;

  const CalidadFilterDropdownMenu({
    super.key,
    required this.onFilterChanged,
    required this.userRole,
    required this.userName,
  });

  @override
  CalidadFilterDropdownMenuState createState() => CalidadFilterDropdownMenuState();
}

class CalidadFilterDropdownMenuState extends State<CalidadFilterDropdownMenu> {
  final CalidadService _calidadService = CalidadService();
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
        'estado_entrevista': [],
      };
      selectedFilters = {
        for (var key in filterOptions.keys) key: {},
        'estado_entrevista': {'Completed', 'RejectedBySupervisor', 'InterviewerAssigned'} // Pre-select Estado options
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

  void _showRegistradorFilter(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CheckboxFilter(
          filterName: 'registrador',
          fetchFilterOptions: _calidadService.fetchFilterOptions,
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
          fetchFilterOptions: _calidadService.fetchFilterOptions,
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

  void _showEstadoFilter(BuildContext context) async {
    List<String> options = await _calidadService.fetchFilterOptions('estado_entrevista', '', '');

    if (!mounted) return; // Ensure the widget is still mounted
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleCheckboxFilter(
          filterName: 'estado_entrevista',
          filterOptions: options,
          initialSelectedValues: selectedFilters['estado_entrevista'] ?? {},
          onSelectedValuesChanged: (values) {
            setState(() {
              selectedFilters['estado_entrevista'] = values;
              widget.onFilterChanged({for (var k in selectedFilters.keys) k: selectedFilters[k]!.toList()});
            });
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
                child: Text('Fecha${_countSelectedFilters('fecha_entrevista')}', style: const TextStyle(color: Colors.white)),
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
                  child: Text('Registrador${_countSelectedFilters('registrador')}', style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
            Visibility(
              visible: widget.userRole != 'Interviewer' && widget.userRole != 'Supervisor',
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
                  child: Text('Supervisor${_countSelectedFilters('supervisor')}', style: const TextStyle(color: Colors.white)),
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
                child: Text('Estado${_countSelectedFilters('estado_entrevista')}', style: const TextStyle(color: Colors.white)),
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
