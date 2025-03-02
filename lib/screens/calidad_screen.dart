import 'package:flutter/material.dart';
import 'package:renagro1/services/calidad_service.dart';
import 'package:renagro1/widgets/widgets.dart';

class CalidadScreen extends StatefulWidget {
  final String userRole;
  final String userName;

  const CalidadScreen({super.key, required this.userRole, required this.userName});

  @override
  CalidadScreenState createState() => CalidadScreenState();
}

class CalidadScreenState extends State<CalidadScreen> {
  final CalidadService _calidadService = CalidadService();
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
      selectedFilters['llave_entrevista'] = [llave];
    } else {
      selectedFilters['llave_entrevista'] = [];
    }

    // Add username to filters based on role
    if (widget.userRole == 'Interviewer') {
      selectedFilters['registrador'] = [widget.userName];
    } else if (widget.userRole == 'Supervisor') {
      selectedFilters['supervisor'] = [widget.userName];
    }

    var result = await _calidadService.fetchFilteredData(selectedFilters, itemsPerPage, page);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTopBar(title: 'Control de Calidad'),
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
                    hintText: 'Buscar por Entrevista',
                    onSubmitted: (value) {
                      fetchData(value, currentPage);
                    },
                  ),
                  const SizedBox(width: 30),
                  CalidadFilterDropdownMenu(
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
                          child: CalidadTable(
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
                  SizedBox(width: 150,child: Text('$totalDocuments resultados encontrados'),),
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
                          onPageSelected: _selectPage,  // Add this line to handle page selection
                        ),
                      ],
                    ),
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
