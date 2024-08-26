import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'completed.dart';
import 'payment_status.dart';

class PaymentsPages extends StatefulWidget {
  @override
  _PaymentsPageState createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPages> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    PaymentReminderForm(),
    PendingPaymentsPage(),
    CompletedPaymentsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payments'),
        backgroundColor: Colors.grey[200],
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[200],
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Reminder Generator',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pending),
            label: 'Pending Payments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.done),
            label: 'Completed Payments',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

class PaymentReminderForm extends StatefulWidget {
  @override
  _PaymentReminderFormState createState() => _PaymentReminderFormState();
}

class _PaymentReminderFormState extends State<PaymentReminderForm> {
  final _formKey = GlobalKey<FormState>();
  String _buyerName = '';
  double _amount = 0;
  String _phone = '';
  DateTime _promiseDate = DateTime.now();

  Future<void> _createReminder() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      await FirebaseFirestore.instance.collection('payments').add({
        'buyerName': _buyerName,
        'amount': _amount,
        'phone': _phone,
        'status': 'pending',
        'promiseDate': _promiseDate,
        'timestamp': DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment reminder created')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildNeumorphicTextFormField(
                labelText: 'Buyer Name',
                onSaved: (value) {
                  _buyerName = value!;
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a buyer name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildNeumorphicTextFormField(
                labelText: 'Amount',
                keyboardType: TextInputType.number,
                onSaved: (value) {
                  _amount = double.parse(value!);
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter an amount';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              _buildNeumorphicTextFormField(
                labelText: 'Phone',
                keyboardType: TextInputType.phone,
                onSaved: (value) {
                  _phone = value!;
                },
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Container(
                height: 50,
                child: _buildNeumorphicDateField(
                  labelText: 'Promise Date',
                  selectedDate: _promiseDate,
                  onDateSelected: (pickedDate) {
                    setState(() {
                      _promiseDate = pickedDate;
                    });
                  },
                ),
              ),
              SizedBox(height: 20),
              _buildNeumorphicButton(
                onPressed: _createReminder,
                label: 'Create Reminder',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Neumorphic TextFormField
  Widget _buildNeumorphicTextFormField({
    required String labelText,
    required FormFieldSetter<String> onSaved,
    FormFieldValidator<String>? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade500,
            offset: Offset(4, 4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white,
            offset: Offset(-4, -4),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
        ),
        keyboardType: keyboardType,
        onSaved: onSaved,
        validator: validator,
      ),
    );
  }

  // Neumorphic DatePicker
  Widget _buildNeumorphicDateField({
    required String labelText,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime(2101),
        );
        if (pickedDate != null && pickedDate != selectedDate) {
          onDateSelected(pickedDate);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade500,
              offset: Offset(4, 4),
              blurRadius: 15,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white,
              offset: Offset(-4, -4),
              blurRadius: 15,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              labelText,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            Text(
              "${selectedDate.toLocal()}".split(' ')[0],
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }

  // Neumorphic Button
  Widget _buildNeumorphicButton({
    required VoidCallback onPressed,
    required String label,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15),
        backgroundColor: Colors.grey[200],
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        shadowColor: Colors.grey.shade500,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(color: Colors.black),
      ),
    );
  }
}