import 'package:flutter/material.dart';
import 'creditpage.dart';
import 'database_helper.dart'; // Import your database helper

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredNamesList = []; // List to store filtered names
  final dbHelper = AppDatabaseHelper(); // Database helper instance

  @override
  void initState() {
    super.initState();
    _loadNames(); // Load names initially
  }

  // Load names from the database
  _loadNames() async {
    filteredNamesList = await dbHelper.loadNamesWithBalances();
    setState(() {});
  }

  // Filter names based on the search query
  _filterNames() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      filteredNamesList = filteredNamesList
          .where((nameData) =>
          nameData['name'].toLowerCase().contains(searchQuery))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECF0F1),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color(0xFFECECEC)),
        title: Text('Search Records', style: TextStyle(color: Colors.white),),
        backgroundColor: Color(0xFF5C9EAD),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _filterNames, // Trigger search
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search for a name',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadNames();
                  },
                ),
              ),
              onChanged: (value) => _filterNames(), // Update search results
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredNamesList.length,
                itemBuilder: (context, index) {
                  final nameData = filteredNamesList[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    elevation: 5,
                    child: ListTile(
                      title: Text(nameData['name'], style: TextStyle(fontSize: 18)),
                      trailing: IconButton(
                        icon: Icon(Icons.arrow_forward),
                        onPressed: () {
                          // Navigate to credit page or desired action
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CreditPage(name: nameData['name'])),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
