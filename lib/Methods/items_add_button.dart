import 'package:flutter/material.dart';

class ItemsAddButton extends StatelessWidget {
  int counter;

  Widget addOrCounter() {
    //int localCounter = counter;
    if (counter == 0) {
      return TextButton(
          onPressed: () {
            counter++;
          },
          child: Text('Add'));
    } else {
      return Row(
        children: [
          IconButton(
              onPressed: () {
                counter--;
              },
              icon: const Icon(Icons.remove)),
          Text(counter.toString()),
          IconButton(
              onPressed: () {
                counter++;
              },
              icon: const Icon(Icons.add))
        ],
      );
    }
  }

  ItemsAddButton({required this.counter});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
