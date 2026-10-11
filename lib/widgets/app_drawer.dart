import 'package:flutter/material.dart';
import '../screens/staff_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.store, size: 50, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Loan Tracker',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),

          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StaffPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
