import 'package:flutter/material.dart';
import 'package:renagro1/services/fincas_service.dart';
import 'package:renagro1/widgets/widgets.dart';


class FincasScreen extends StatefulWidget {
  final String userRole;
  final String userName;

  const FincasScreen({super.key, required this.userRole, required this.userName});

  @override
  FincasScreenState createState() => FincasScreenState();
}

class FincasScreenState extends State<FincasScreen> {
  final FincasService _fincasService = FincasService();
  final TextEditingController _llaveController = TextEditingController();
  final TextEditingController _productorController = TextEditingController();
  final TextEditingController _parcelaController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();
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
    fetchData(page: currentPage);
  }

  @override
  void dispose() {
    _llaveController.dispose();
    _productorController.dispose();
    _parcelaController.dispose();
    _codigoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchData({required int page}) async {
    setState(() {
      isLoading = true; // Start loading
    });

    // Collect current values from controllers
    String llave = _llaveController.text;
    String productor = _productorController.text;
    String parcela = _parcelaController.text;
    String codigo = _codigoController.text;

    // Ensure parameters are not null before dereferencing
    if (llave.isNotEmpty) {
      selectedFilters['llave_entrevista'] = [llave];
    } else {
      selectedFilters['llave_entrevista'] = [];
    }

    if (productor.isNotEmpty) {
      selectedFilters['nombre_productor'] = [productor];
    } else {
      selectedFilters['nombre_productor'] = [];
    }

    if (parcela.isNotEmpty) {
      selectedFilters['nombre_parcela'] = [parcela];
    } else {
      selectedFilters['nombre_parcela'] = [];
    }

    if (codigo.isNotEmpty) {
      selectedFilters['codigo_parcela'] = [codigo];
    } else {
      selectedFilters['codigo_parcela'] = [];
    }

    // Add username to filters based on role
    if (widget.userRole == 'Interviewer') {
      selectedFilters['registrador'] = [widget.userName];
    } else if (widget.userRole == 'Supervisor') {
      selectedFilters['supervisor'] = [widget.userName];
    }

    var result = await _fincasService.fetchFilteredData(selectedFilters, itemsPerPage, page);
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
      fetchData(page: currentPage);
    } else if (!forward && currentPage > 1) {
      setState(() {
        currentPage--;
      });
      fetchData(page: currentPage);
    }
  }

  void _selectPage(int? page) {
    if (page != null && page != currentPage) {
      setState(() {
        currentPage = page;
      });
      fetchData(page: currentPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomTopBar(title: 'Inventario de Fincas/Parcelas'),
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SearchBarFilter(
                        controller: _llaveController,
                        hintText: 'Buscar por Entrevista',
                        onSubmitted: (value) {
                          fetchData(page: currentPage);
                        },
                      ),
                      const SizedBox(height: 15),
                      SearchBarFilter(
                        controller: _productorController,
                        hintText: 'Buscar por Productor',
                        onSubmitted: (value) {
                          fetchData(page: currentPage);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SearchBarFilter(
                        controller: _parcelaController,
                        hintText: 'Buscar por Finca/Parcela',
                        onSubmitted: (value) {
                          fetchData(page: currentPage);
                        },
                      ),
                      const SizedBox(height: 15),
                      SearchBarFilter(
                        controller: _codigoController,
                        hintText: 'Buscar por Codigo Parcela',
                        onSubmitted: (value) {
                          fetchData(page: currentPage);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 30),
                  FincasFilterDropdownMenu(
                    onFilterChanged: (filters) {
                      setState(() {
                        selectedFilters = filters;
                        currentPage = 1;
                      });
                      fetchData(page: currentPage);
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
                          child: FincasTable(
                            data: _filteredData,
                            llaveQuery: _llaveController.text,
                            productorQuery: _productorController.text,
                            parcelaQuery: _parcelaController.text,
                            codigoQuery: _codigoController.text,
                            onEstadoUpdated: () => fetchData(page: currentPage),
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
                            fetchData(page: currentPage);
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
