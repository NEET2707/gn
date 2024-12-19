import 'package:flutter/material.dart';
import 'database_helper.dart';

class CreditPage extends StatefulWidget {
  final String name;

  const CreditPage({super.key, required this.name});

  @override
  _CreditPageState createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  double totalbal = 0.0;
  String? _transactionType = 'credit';
  TextEditingController _dateController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  TextEditingController _particularController = TextEditingController();

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _particularController.dispose();
    super.dispose();
  }

  // Select Date
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
      });
    }
  }

  // Save the transaction into the database
  Future<void> _saveTransaction() async {
    if (_dateController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _particularController.text.isNotEmpty) {
      final transaction = {
        'date': _dateController.text,
        'type': _transactionType,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'particular': widget.name, // Save the name dynamically
      };
      await AppDatabaseHelper().insertTransaction(transaction);

      // Clear fields after saving
      _dateController.clear();
      _amountController.clear();
      _particularController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction saved successfully!')),
      );
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    return await AppDatabaseHelper().getTransactionsByName(widget.name);
  }




  // Calculate total credit
  double _calculateTotalCredit(List<Map<String, dynamic>> transactions) {
    double totalCredit = 0.0;
    for (var tx in transactions) {
      if (tx['type'] == 'credit') {
        totalCredit += tx['amount'] ?? 0.0;
      }
    }
    return totalCredit;
  }

// Calculate total debit
  double _calculateTotalDebit(List<Map<String, dynamic>> transactions) {
    double totalDebit = 0.0;
    for (var tx in transactions) {
      if (tx['type'] == 'debit') {
        totalDebit += tx['amount'] ?? 0.0;
      }
    }
    return totalDebit;
  }

// Calculate balance
  double _calculateBalance(double totalCredit, double totalDebit) {
    return totalCredit - totalDebit;
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color(0xFFECECEC)),
        title: Text(
          widget.name, // Display the name passed to the widget
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Color(0xFF5C9EAD),
        actions: [
          // Add Transaction Button
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Date Input
                              TextField(
                                controller: _dateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Transaction Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                onTap: () => _selectDate(context),
                              ),
                              SizedBox(height: 16),

                              // Transaction Type (Radio buttons)
                              Row(
                                children: [
                                  Radio<String>(
                                    value: 'credit',
                                    groupValue: _transactionType,
                                    onChanged: (String? value) {
                                      setState(() {
                                        _transactionType = value!;
                                      });
                                    },
                                  ),
                                  Text('Credit'),
                                  Radio<String>(
                                    value: 'debit',
                                    groupValue: _transactionType,
                                    onChanged: (String? value) {
                                      setState(() {
                                        _transactionType = value!;
                                      });
                                    },
                                  ),
                                  Text('Debit'),
                                ],
                              ),
                              SizedBox(height: 16),

                              // Amount Input
                              TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'Amount',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 16),

                              // Particular Input
                              TextField(
                                controller: _particularController,
                                decoration: InputDecoration(
                                  labelText: 'Particular',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 16),

                              // Save Button
                              ElevatedButton(
                                onPressed: () async {
                                  await _saveTransaction(); // Call the save method
                                  Navigator.pop(context);  // Close the dialog
                                  setState(() {});         // Refresh the UI
                                },
                                child: Text('Save Transaction'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          IconButton(onPressed: (){

          },
              icon: Icon(
                  Icons.search
              )
          ),
          IconButton(onPressed: (){

          },
              icon: Icon(
                  Icons.more_vert
              )
          ),
        ],
      ),
      body: Column(
        children: [
          // Transaction Table Header
          Container(
            color: Colors.blueGrey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text('Date',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      child: Text('Particular',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      child: Text('Credit',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(
                      child: Text('Debit',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          ),

          // Transaction List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No transactions available.'));
                } else {
                  var transactions = snapshot.data!;
                  double totalCredit = _calculateTotalCredit(transactions);
                  double totalDebit = _calculateTotalDebit(transactions);
                  double balance = _calculateBalance(totalCredit, totalDebit);

                  return Column(
                    children: [
                      // List of transactions
                      Expanded(
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            var transaction = transactions[index];
                            return Container(
                              color: index % 2 == 0
                                  ? Colors.white
                                  : Colors.grey[200], // Alternate row colors
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                        child: Text('${transaction['date']}')),
                                    Expanded(
                                        child: Text(
                                            '${transaction['particular']}')),
                                    Expanded(
                                        child: Text(
                                          transaction['type'] == 'credit'
                                              ? '\$${transaction['amount']}'
                                              : '0.00',
                                          style: TextStyle(color: Colors.green),
                                        )),
                                    Expanded(
                                        child: Text(
                                          transaction['type'] == 'debit'
                                              ? '\$${transaction['amount']}'
                                              : '0.00',
                                          style: TextStyle(color: Colors.red),
                                        )),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      Container(
                        // height: 150,
                        width: double.infinity,
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Total Credit',
                                    style: TextStyle(
                                        color: Colors.green,
                                        backgroundColor: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),Text(
                                    '${totalCredit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: Colors.green,
                                        backgroundColor: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Total Debit:',
                                    style: TextStyle(
                                        color: Colors.red,
                                        backgroundColor: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Text(
                                    '${totalDebit.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        color: Colors.red,
                                        backgroundColor: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              color: Color(0xFF5C9EAD),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: [
                                    Text(
                                      'Total Balance:',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),Text(
                                      ' ${balance.toStringAsFixed(2)}',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            )

                          ],
                        ),
                      )
                      // Totals Display at Bottom

                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),


    );
  }
}