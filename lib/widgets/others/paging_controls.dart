import 'package:flutter/material.dart';

class PagingControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int?> onPageSelected;

  const PagingControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    TextEditingController controller = TextEditingController(text: currentPage.toString());

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: currentPage > 1 ? onPrevious : null,
        ),
        const Text('Página'),
        const SizedBox(width: 10,),
        SizedBox(
          width: 50,
          height: 40,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (value) {
              int? page = int.tryParse(value);
              if (page != null) {
                if (page < 1) {
                  page = 1;
                } else if (page > totalPages) {
                  page = totalPages;
                }
                controller.text = page.toString();
                onPageSelected(page);
              } else {
                // Reset the text field to the current valid page number
                controller.text = currentPage.toString();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Por favor ingrese un número válido.')),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 10,),
        Text('de $totalPages'),
        IconButton(
          icon: const Icon(Icons.arrow_forward),
          onPressed: currentPage < totalPages ? onNext : null,
        ),
      ],
    );
  }
}