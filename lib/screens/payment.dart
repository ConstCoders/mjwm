import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mjworkmanagement/screens/payment_status.dart';

import 'completed.dart';

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
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Buyer Name'),
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
            TextFormField(
              decoration: InputDecoration(labelText: 'Amount'),
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
            TextFormField(
              decoration: InputDecoration(labelText: 'Phone'),
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
            TextFormField(
              decoration: InputDecoration(labelText: 'Promise Date'),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _promiseDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null && pickedDate != _promiseDate)
                  setState(() {
                    _promiseDate = pickedDate;
                  });
              },
              controller: TextEditingController(
                text: "${_promiseDate.toLocal()}".split(' ')[0],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createReminder,
              child: Text('Create Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}

