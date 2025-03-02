import 'package:flutter/material.dart';
import 'package:renagro1/widgets/widgets.dart';

typedef FetchFilterOptions = Future<List<String>> Function(String filterName, String userName, String query);

class CheckboxFilter extends StatefulWidget {
  final String filterName;
  final FetchFilterOptions fetchFilterOptions;
  final Set<String> initialSelectedValues;
  final Function(Set<String>) onSelectedValuesChanged;
  final String userName;

  const CheckboxFilter({
    super.key,
    required this.filterName,
    required this.fetchFilterOptions,
    required this.initialSelectedValues,
    required this.onSelectedValuesChanged,
    required this.userName,
  });

  @override
  CheckboxFilterState createState() => CheckboxFilterState();
}

class CheckboxFilterState extends State<CheckboxFilter> {
  late TextEditingController searchController;
  late List<String> originalOptions;
  late List<String> filteredOptions;
  late Set<String> selectedValues;
  bool isLoading = false; // Added loading state

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    originalOptions = widget.initialSelectedValues.toList();
    filteredOptions = List.from(originalOptions);
    selectedValues = Set.from(widget.initialSelectedValues);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _updateSearchResults(String query) async {
    if (query.isNotEmpty) {
      setState(() {
        isLoading = true; // Start loading
      });
      List<String> updatedOptions = await widget.fetchFilterOptions(widget.filterName, widget.userName, query);
      setState(() {
        filteredOptions = updatedOptions;
        isLoading = false; // End loading
      });
    } else {
      setState(() {
        filteredOptions = originalOptions;
      });
    }
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
      title: Text('Seleccionar ${widget.filterName}'),
      content: SizedBox(
        height: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomSearchBar(
              controller: searchController,
              onSubmitted: _updateSearchResults,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading // Check loading state
                  ? const Center(child: CircularProgressIndicator()) // Show loading indicator
                  : SingleChildScrollView(
                      child: ListBody(
                        children: filteredOptions.map((String value) {
                          bool isSelected = selectedValues.contains(value);
                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(value),
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? checked) {
                              setState(() {
                                if (checked ?? false) {
                                  selectedValues.add(value);
                                } else {
                                  selectedValues.remove(value);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Limpiar'),
          onPressed: () {
            setState(() {
              selectedValues = {};
            });
            widget.onSelectedValuesChanged(selectedValues);
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
            widget.onSelectedValuesChanged(selectedValues);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
