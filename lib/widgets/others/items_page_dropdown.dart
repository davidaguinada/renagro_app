import 'package:flutter/material.dart';

class ItemsPerPageDropdown extends StatefulWidget {
  final int selectedValue;
  final Function(int) onChanged;

  const ItemsPerPageDropdown({
    super.key,
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  ItemsPerPageDropdownState createState() => ItemsPerPageDropdownState();
}

class ItemsPerPageDropdownState extends State<ItemsPerPageDropdown> {
  late int _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DropdownButton<int>(
          focusColor: Colors.transparent,
          value: _selectedValue,
          onChanged: (int? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedValue = newValue;
              });
              widget.onChanged(newValue);
            }
          },
          items: <int>[10, 15, 20, 25, 50, 100].map<DropdownMenuItem<int>>((int value) {
            return DropdownMenuItem<int>(
              value: value,
              child: Text(value.toString()),
            );
          }).toList(),
        ),
        const SizedBox(width: 10,),
        const Text('resultados por página'),
      ],
    );
  }
}
