import 'package:flutter/material.dart';

class SimpleCheckboxFilter extends StatefulWidget {
  final String filterName;
  final List<String> filterOptions;
  final Set<String> initialSelectedValues;
  final Function(Set<String>) onSelectedValuesChanged;

  const SimpleCheckboxFilter({
    super.key,
    required this.filterName,
    required this.filterOptions,
    required this.initialSelectedValues,
    required this.onSelectedValuesChanged,
  });

  @override
  SimpleCheckboxFilterState createState() => SimpleCheckboxFilterState();
}

class SimpleCheckboxFilterState extends State<SimpleCheckboxFilter> {
  late Set<String> selectedValues;

  @override
  void initState() {
    super.initState();
    selectedValues = Set.from(widget.initialSelectedValues);
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
        child: SingleChildScrollView(
          child: ListBody(
            children: widget.filterOptions.map((String value) {
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
