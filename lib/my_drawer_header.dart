import 'package:flutter/material.dart';
import 'database_helper.dart';

class MyHeaderDrawer extends StatefulWidget {
  const MyHeaderDrawer({super.key});

  @override
  State<MyHeaderDrawer> createState() => _MyHeaderDrawerState();
}

class _MyHeaderDrawerState extends State<MyHeaderDrawer> {
  final dbHelper = AppDatabaseHelper();

  double totalCredit = 0.0;
  double totalDebit = 0.0;
  double totalBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchSummaryData();
  }

  Future<void> _fetchSummaryData() async {
    final totals = await dbHelper.getTotalCreditDebitBalance();
    setState(() {
      totalCredit = totals['totalCredit'] ?? 0.0;
      totalDebit = totals['totalDebit'] ?? 0.0;
      totalBalance = totals['totalBalance'] ?? 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color(0xFF5C9EAD),
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Profile Image (Optional)
          Container(
            margin: EdgeInsets.only(top: 10.0),
            height: 70,
            width: 70, // Make sure the width and height are equal for a perfect circle
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: AssetImage('assets/image/GN.png'),
                fit: BoxFit.cover, // Ensures the image fills the circle while preserving aspect ratio
              ),
            ),
          ),
          // App Title
          Text(
            'Account Manager',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Divider(color: Colors.white70, thickness: 1.0, indent: 30, endIndent: 30),
          SizedBox(height: 10),

          // Credit, Debit, and Balance Display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummaryRow('Credit(+)', totalCredit, Colors.white),
                _buildSummaryRow('Debit(-)', totalDebit, Colors.white),
                Divider(color: Colors.white70),
                _buildSummaryRow('Balance', totalBalance, Colors.white, bold: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build rows for Credit, Debit, Balance
  Widget _buildSummaryRow(String label, double value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₹ ${value.toStringAsFixed(0)}', // No decimals as per the image
            style: TextStyle(
              color: bold ? Colors.white : color,
              fontSize: 18,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
