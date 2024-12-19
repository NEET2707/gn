import 'package:flutter/material.dart';
import 'my_drawer_header.dart';
import 'database_helper.dart'; // Import the DatabaseHelper class
import 'creditpage.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  var currentPage = DrawerSection.dashboard; // Define currentPage here
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> namesList = []; // List to store both name and id
  final dbHelper = AppDatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  // Load names from the database
  // Load names along with their credit, debit, and balance
  _loadNames() async {
    // Fetch names with balances from the database
    namesList = await dbHelper.loadNamesWithBalances();

    // Print fetched data for debugging
    print("Fetched names with balances: $namesList");

    // Update the UI by setting the state
    setState(() {});
  }

  // Save name to the database
  // Save name to the database, ensuring no duplicates
  _saveName() async {
    if (_nameController.text.isNotEmpty) {
      // Check if the name already exists in the namesList
      bool isDuplicate = namesList.any((item) => item['name'] == _nameController.text);

      if (isDuplicate) {
        // Show a message if the name already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('This name already exists!'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Insert the name into the database
        final int result = await dbHelper.insertName(_nameController.text);
        if (result != -1) {
          print("Name saved successfully.");
          _loadNames(); // Reload the names list after inserting
          _nameController.clear();
        } else {
          print("Failed to save the name.");
        }
      }
    } else {
      print("Name input is empty.");
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFECF0F1),

      // AppBar Section
      appBar: AppBar(
        iconTheme: IconThemeData(color: Color(0xFFECECEC)),
        title: Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF5C9EAD),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {
              print("Search icon pressed!");
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              print("More options pressed!");
            },
          ),
        ],
      ),

      // Drawer Section
      drawer: Drawer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              MyHeaderDrawer(),
              MyDrawerList(),
            ],
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButton: Material(
        color: Color(0xFF5C9EAD), // Button color
        shape: CircleBorder(), // Circular shape
        elevation: 6.0, // Shadow/elevation
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Wrap content vertically
                      children: [
                        // Dialog Title
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(0xFF5C9EAD),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Add new account',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // Input Field
                        TextField(
                          controller: _nameController, // Connect this controller
                          decoration: InputDecoration(
                            labelText: 'Account name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Buttons Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Cancel Button
                            TextButton(
                              style: TextButton.styleFrom(
                                side: BorderSide(color: Color(0xFF5C9EAD)),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                'CANCEL',
                                style: TextStyle(
                                  color: Color(0xFF5C9EAD),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // Save Button
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF5C9EAD),
                              ),
                              onPressed: () {
                                _saveName();
                                Navigator.of(context).pop();
                              },
                              child: Text(
                                'SAVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Adjust size
            child: Icon(Icons.library_add, color: Colors.white),
          ),
        ),
      ),

      // Displaying the List of Names
      body: ListView.builder(
        itemCount: namesList.length,
        itemBuilder: (context, index) {
          final nameData = namesList[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            elevation: 5,
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreditPage(name: nameData['name']),
                  ),
                );

                // Reload the data after returning from CreditPage
                _loadNames();
              },
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      nameData['name'], // Display name
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_note, size: 20),
                          onPressed: () async {
                          },

                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 20),
                          onPressed: () async {
                            int idToDelete = nameData['id'];
                            await dbHelper.deleteName(idToDelete);
                            _loadNames(); // Reload data after deletion
                          },
                        ),
                      ],
                    ),
                  ),

                  // Credit, Debit, and Balance Data Section
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoBox('Credit (+)', nameData['credit'].toString()),
                        _buildInfoBox('Debit (-)', nameData['debit'].toString()),
                        _buildInfoBox('Balance', nameData['balance'].toString()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),


    );
  }

  // Drawer List
  Widget MyDrawerList() {
    return Container(
      padding: EdgeInsets.only(
        top: 15,
      ),
      child: Column(
        children: [
          menuItem(1, "Home", Icons.home,
              currentPage == DrawerSection.home ? true : false),
          menuItem(2, "Backup", Icons.backup,
              currentPage == DrawerSection.backup ? true : false),
          menuItem(3, "Restore", Icons.restore,
              currentPage == DrawerSection.restore ? true : false),
          menuItem(4, "Change currency", Icons.settings,
              currentPage == DrawerSection.changeCurrency ? true : false),
          menuItem(5, "Change password", Icons.settings,
              currentPage == DrawerSection.changePassword ? true : false),
          menuItem(6, "Change security question", Icons.security,
              currentPage == DrawerSection.securityQuestion ? true : false),
          menuItem(7, "Setting ", Icons.settings,
              currentPage == DrawerSection.settings ? true : false),
          menuItem(8, "FAQs", Icons.question_answer,
              currentPage == DrawerSection.faqs ? true : false),
          menuItem(9, "Share the app", Icons.share,
              currentPage == DrawerSection.shareApp ? true : false),
          menuItem(10, "Rate the app", Icons.rate_review,
              currentPage == DrawerSection.rateApp ? true : false),
          menuItem(11, "Privacy policy", Icons.privacy_tip,
              currentPage == DrawerSection.privacyPolicy ? true : false),
          menuItem(12, "More apps", Icons.more,
              currentPage == DrawerSection.moreApps ? true : false),
          menuItem(13, "Ads Free", Icons.block,
              currentPage == DrawerSection.adsFree ? true : false),
        ],
      ),
    );
  }

  // Drawer menu item
  Widget menuItem(int id, String title, IconData icon, bool selected) {
    return Material(
      color: selected ? Colors.grey[200] : Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          setState(() {
            switch (id) {
              case 1:
                currentPage = DrawerSection.home;
                break;
              case 2:
                currentPage = DrawerSection.backup;
                break;
              case 3:
                currentPage = DrawerSection.restore;
                break;
              case 4:
                currentPage = DrawerSection.changeCurrency;
                break;
              case 5:
                currentPage = DrawerSection.changePassword;
                break;
              case 6:
                currentPage = DrawerSection.securityQuestion;
                break;
              case 7:
                currentPage = DrawerSection.settings;
                break;
              case 8:
                currentPage = DrawerSection.faqs;
                break;
              case 9:
                currentPage = DrawerSection.shareApp;
                break;
              case 10:
                currentPage = DrawerSection.rateApp;
                break;
              case 11:
                currentPage = DrawerSection.privacyPolicy;
                break;
              case 12:
                currentPage = DrawerSection.moreApps;
                break;
              case 13:
                currentPage = DrawerSection.adsFree;
                break;
            }
          });
        },
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Colors.black,
              ),
              SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



Widget _buildInfoBox(String title, String value) {
  return Container(
    height: 90,
    width: 90,
    color: Color(0xFF5C9EAD),
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}


// Enum for Drawer Section
enum DrawerSection {
  dashboard, // Add this line
  home,
  backup,
  restore,
  changeCurrency,
  changePassword,
  securityQuestion,
  settings,
  faqs,
  shareApp,
  rateApp,
  privacyPolicy,
  moreApps,
  adsFree,
}
