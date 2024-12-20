import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'my_drawer_header.dart';
import 'database_helper.dart'; // Import the DatabaseHelper class
import 'creditpage.dart';
import 'namesearchdelegate.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  var currentPage = DrawerSection.dashboard; // Define currentPage here
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> namesList = []; // List to store both name and id
  final TextEditingController _searchController = TextEditingController(); // Controller for search
  List<Map<String, dynamic>> filteredNamesList = []; // List for filtered names
  final dbHelper = AppDatabaseHelper();



  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  // Load names from the database
  // Load names along with their credit, debit, and balance
  _loadNames() async {
    namesList = await dbHelper.loadNamesWithBalances();
    print("Names List: $namesList"); // Debug print
    filteredNamesList = namesList; // Set initial filtered list as all names
    setState(() {});
  }


  _filterNames() {
    String searchQuery = _searchController.text.toLowerCase();
    setState(() {
      filteredNamesList = namesList
          .where((nameData) =>
          nameData['name'].toLowerCase().contains(searchQuery))
          .toList();
    });
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


  void _saveAsPdf() {
    print("Saving as PDF...");
    // Add logic to generate and save the PDF
  }



  Future<String?> getDownloadDirectory() async {
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      // Handle the case where the directory is null
      print("External storage directory not found.");
      return null;
    }
    return directory.path; // Safely access the path
  }

  Future<void> requestStoragePermissions() async {
    if (await Permission.storage.request().isGranted) {
      // Permission granted
    } else {
      // Handle the case where permission is denied
      print('Storage permission is denied');
    }
  }



  Future<void> generatePDF() async {
    try {
      // Request permissions
      await requestStoragePermissions();

      final pdf = pw.Document();

      // Add a title to the PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Dashboard Data',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: pw.FlexColumnWidth(2), // Name column
                    1: pw.FlexColumnWidth(1), // Credit column
                    2: pw.FlexColumnWidth(1), // Debit column
                    3: pw.FlexColumnWidth(1), // Balance column
                  },
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Name',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Credit',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Debit',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Balance',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    ...namesList.map((nameData) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(nameData['name']),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(nameData['credit']?.toString() ?? '0'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(nameData['debit']?.toString() ?? '0'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(nameData['balance']?.toString() ?? '0'),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ],
            );
          },
        ),
      );

      // Get download directory path
      final outputDir = await getDownloadDirectory();
      if (outputDir == null) {
        // Handle the case where directory is null
        print("Unable to get download directory.");
        return;
      }

      // Save the PDF file to the Downloads directory
      final outputFile = File("${outputDir}/Dashboard_Data.pdf");

      await outputFile.writeAsBytes(await pdf.save());

      print("PDF saved to: ${outputFile.path}");

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to Downloads folder'),
          backgroundColor: Colors.green,
        ),
      );

      // Open the PDF file
      await OpenFile.open(outputFile.path);
    } catch (e) {
      print("Error generating PDF: $e");

      // Show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchPage(),));
            },
          ),

          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String value) {
              if (value == 'save_as_pdf') {
                generatePDF();
                _saveAsPdf();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(
                value: 'save_as_pdf',
                child: Text('Save as PDF'),
              ),

            ],
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
        color: Color(0xF80CBC4), // Button color
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
        itemCount: filteredNamesList.length,
        itemBuilder: (context, index) {
          final nameData = filteredNamesList[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            elevation: 5,
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreditPage(name: nameData['name'])),
                );
                _loadNames();
              },
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      nameData['name'],
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit_note, size: 20),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CreditPage(name: nameData['name'])),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, size: 20),
                          onPressed: () async {
                            bool? confirmDelete = await showDialog<bool>(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text("Confirm Deletion"),
                                  content: Text("Are you sure you want to delete this item?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false); // User cancelled deletion
                                      },
                                      child: Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true); // User confirmed deletion
                                      },
                                      child: Text("Delete"),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmDelete == true) {
                              int idToDelete = nameData['id'];
                              await dbHelper.deleteName(idToDelete);
                              _loadNames();
                            }
                          },
                        ),

                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoBox('Credit (+)', nameData['credit']?.toString() ?? '0'),
                        _buildInfoBox('Debit (-)', nameData['debit']?.toString() ?? '0'),
                        _buildInfoBox('Balance', nameData['balance']?.toString() ?? '0'),
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
