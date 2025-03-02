import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:renagro1/services/actividad_service.dart';
import 'package:renagro1/widgets/widgets.dart';
import 'package:renagro1/utils/pdf_builder.dart';
import 'package:renagro1/utils/spreadsheet_builder.dart'; // Import the new csv helper

class ActividadScreen extends StatefulWidget {
  final String userRole;
  final String userName;

  const ActividadScreen({super.key, required this.userRole, required this.userName});

  @override
  ActividadScreenState createState() => ActividadScreenState();
}

class ActividadScreenState extends State<ActividadScreen> {
  final ActividadService _actividadService = ActividadService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _filteredData = [];
  int currentPage = 1;
  int totalPages = 1;
  int itemsPerPage = 10;
  int totalDocuments = 0;
  Map<String, List<String>> selectedFilters = {};
  bool isLoading = false; // Added loading state

  @override
  void initState() {
    super.initState();
    fetchData("", currentPage);
  }

  Future<void> fetchData(String llave, int page) async {
    setState(() {
      isLoading = true; // Start loading
    });

    if (llave.isNotEmpty) {
      selectedFilters['registrador_cedula'] = [llave];
    } else {
      selectedFilters['registrador_cedula'] = [];
    }

    // Add username to filters based on role
    if (widget.userRole == 'Interviewer') {
      selectedFilters['registrador'] = [widget.userName];
    } else if (widget.userRole == 'Supervisor') {
      selectedFilters['supervisor'] = [widget.userName];
    }

    var result = await _actividadService.fetchFilteredData(selectedFilters, itemsPerPage, page);
    setState(() {
      _filteredData = result['data'];
      currentPage = result['currentPage'];
      totalPages = result['totalPages'];
      totalDocuments = result['totalDocuments'];
      isLoading = false; // End loading
    });
  }

  void _changePage(bool forward) {
    if (forward && currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
    } else if (!forward && currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
    fetchData(_searchController.text, currentPage);
  }

  void _selectPage(int? page) {
    if (page != null) {
      setState(() {
        currentPage = page;
      });
      fetchData(_searchController.text, currentPage);
    }
  }

  Future<void> printTable() async {
    setState(() {
      isLoading = true; // Start loading
    });

    var resultReport = await _actividadService.fetchFilteredData(selectedFilters, 10000, 1);
    setState(() {
      _filteredData = resultReport['data'];
      isLoading = false; // End loading
    });

    // Convert date format from "dd-MM-yyyy" to DateTime
    List<DateTime?> datePeriod = [];
    if (selectedFilters.containsKey('fecha_entrevista') && selectedFilters['fecha_entrevista'] != null) {
      for (String date in selectedFilters['fecha_entrevista']!) {
        datePeriod.add(DateFormat('dd-MM-yyyy').parse(date));
      }
    }

    await printDocument(
      _filteredData,
      widget.userName,
      widget.userRole,
      datePeriod,
    );
    var result = await _actividadService.fetchFilteredData(selectedFilters, itemsPerPage, 1);
    setState(() {
      _filteredData = result['data'];
      currentPage = result['currentPage'];
      totalPages = result['totalPages'];
      totalDocuments = result['totalDocuments'];
      isLoading = false; // End loading
    });
  }

  Future<void> exportToCsv() async {
    setState(() {
      isLoading = true; // Start loading
    });

    var resultReport = await _actividadService.fetchFilteredData(selectedFilters, 10000, 1);
    setState(() {
      _filteredData = resultReport['data'];
      isLoading = false; // End loading
    });

    // Convert date format from "dd-MM-yyyy" to DateTime
    List<DateTime?> datePeriod = [];
    if (selectedFilters.containsKey('fecha_entrevista') && selectedFilters['fecha_entrevista'] != null) {
      for (String date in selectedFilters['fecha_entrevista']!) {
        datePeriod.add(DateFormat('dd-MM-yyyy').parse(date));
      }
    }

    await generateSpreadsheetReport(
      _filteredData,
      widget.userName,
      widget.userRole,
      datePeriod,
    );
    var result = await _actividadService.fetchFilteredData(selectedFilters, itemsPerPage, 1);
    setState(() {
      _filteredData = result['data'];
      currentPage = result['currentPage'];
      totalPages = result['totalPages'];
      totalDocuments = result['totalDocuments'];
      isLoading = false; // End loading
    });
  }

  bool get areFiltersPresent {
    return selectedFilters.values.any((list) => list.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTopBar(title: 'Monitoreo de Actividad'),
      body: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        child: Column(
          children: <Widget>[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SearchBarFilter(
                    controller: _searchController,
                    hintText: 'Buscar por Cedula',
                    onSubmitted: (value) {
                      fetchData(value, currentPage);
                    },
                  ),
                  const SizedBox(width: 30),
                  ActividadFilterDropdownMenu(
                    onFilterChanged: (filters) {
                      setState(() {
                        selectedFilters = filters;
                        currentPage = 1;
                      });
                      fetchData(_searchController.text, currentPage);
                    },
                    userRole: widget.userRole,
                    userName: widget.userName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading // Check loading state
                  ? const Center(child: CircularProgressIndicator()) // Show loading indicator
                  : Scrollbar(
                      thumbVisibility: true,
                      trackVisibility: true,
                      controller: _scrollController,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _scrollController,
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                          child: ActividadTable(
                            data: _filteredData,
                            searchQuery: _searchController.text,
                            onEstadoUpdated: () => fetchData(_searchController.text, currentPage),
                            userRole: widget.userRole,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  SizedBox(width: 150, child: Text('$totalDocuments resultados encontrados')),
                  SizedBox(
                    width: 800,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ItemsPerPageDropdown(
                          selectedValue: itemsPerPage,
                          onChanged: (value) {
                            setState(() {
                              itemsPerPage = value;
                              currentPage = 1;
                            });
                            fetchData(_searchController.text, currentPage);
                          },
                        ),
                        const SizedBox(width: 30),
                        PagingControls(
                          currentPage: currentPage,
                          totalPages: totalPages,
                          onPrevious: () {
                            _changePage(false);
                          },
                          onNext: () {
                            _changePage(true);
                          },
                          onPageSelected: _selectPage,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: areFiltersPresent ? printTable : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: areFiltersPresent ? const Color(0xff1d3b6f) : Colors.grey,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Crear PDF Reporte', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: areFiltersPresent ? exportToCsv : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: areFiltersPresent ? const Color(0xff1d3b6f) : Colors.grey,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text('Exportar a CSV', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      drawer: CustomMenuBar(userRole: widget.userRole, userName: widget.userName),
    );
  }
}
