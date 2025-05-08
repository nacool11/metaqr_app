import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class CustomDropDown extends StatelessWidget {
  const CustomDropDown({
    super.key,
    required this.onChanged,
    required this.itemsList,
    this.selectedValue,
  });
  final void Function({required String? value}) onChanged;
  final List<String> itemsList;
  final String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton2<String>(
        isExpanded: true,
        hint: const Text(
          "Select",
          overflow: TextOverflow.ellipsis,
        ),
        isDense: true,
        // style: TextStyles.poppineRegular.const14.blackColor,
        items: itemsList.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              // style: TextStyles.poppineRegular.const14.blackColor,
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        value: selectedValue,
        onChanged: (value) => onChanged(value: value),
        buttonStyleData: ButtonStyleData(
          padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.blue.shade200),
          ),
        ),
        iconStyleData: IconStyleData(
          iconSize: 30,
          icon: Icon(
            Icons.arrow_drop_down,
            color: Colors.blue.shade300,
            // color: ColorsConstants.blackColor,
          ),
        ),
        dropdownStyleData: DropdownStyleData(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Colors.white,
          ),
          offset: const Offset(0, 0),
          scrollbarTheme: ScrollbarThemeData(
            radius: const Radius.circular(40),
            thickness: WidgetStateProperty.all(6),
            thumbVisibility: WidgetStateProperty.all(true),
          ),
        ),
        menuItemStyleData: const MenuItemStyleData(
          height: 36,
        ),
      ),
    );
  }
}
