import 'package:flutter/material.dart';
import '../models/site_model.dart';

class SiteCard extends StatelessWidget {
  final ConstructionSite site;
  const SiteCard({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: Column(
        children: [
          // 75% Photo Area
          AspectRatio(
            aspectRatio: 16 / 9, // Standard wide-screen photo ratio
            child: Image.network(
              site.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image),
              ),
            ),
          ),
          // 25% Text Area
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(site.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: ${site.date}",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    Text(
                      "By: ${site.filledBy}",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
