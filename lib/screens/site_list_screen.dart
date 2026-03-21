import 'package:flutter/material.dart';
import 'package:prototype_po_scanner/screens/entry_form_screen.dart';
import '../models/site_model.dart';
import '../widgets/site_card.dart';
import 'package:easy_localization/easy_localization.dart';

class SiteListPage extends StatelessWidget {
  SiteListPage({super.key});
  final List<ConstructionSite> sites = [
    ConstructionSite(
      name: "Skyline Tower - Phase 1",
      date: "2024-05-18",
      filledBy: "Alex Rivera",
      imageUrl:
          "https://images.unsplash.com/photo-1541888946425-d81bb19480c5?auto=format&fit=crop&w=800&q=80",
    ),
    ConstructionSite(
      name: "Bridge Inspection - North",
      date: "2024-05-19",
      filledBy: "Sarah Chen",
      imageUrl:
          "https://images.unsplash.com/photo-1504307651254-35680f356dfd?auto=format&fit=crop&w=800&q=80",
    ),
    ConstructionSite(
      name: "Underground Drainage",
      date: "2024-05-20",
      filledBy: "Mike Johnson",
      imageUrl:
          "https://images.unsplash.com/photo-1581094271901-8022df4466f9?auto=format&fit=crop&w=800&q=80",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("site_list_title".tr()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              if (context.locale.languageCode == 'fr') {
                context.setLocale(const Locale('en', 'US'));
              } else {
                context.setLocale(const Locale('fr', 'FR'));
              }
            },
          ),
        ],
      ),
      body: sites.isEmpty
          ? Center(child: Text("no_sites".tr()))
          : ListView.builder(
              itemCount: sites.length,
              itemBuilder: (context, index) {
                final site = sites[index];
                return SiteCard(site: site);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EntryFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
