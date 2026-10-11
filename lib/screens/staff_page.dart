import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      drawer: const AppDrawer(),
      body: const Center(child: Text('Staff Page')),
    );
  }
}
