import 'dart:convert';

import 'package:prototype_po_scanner/services/database_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  final _supabase = Supabase.instance.client;

  Future<void> syncReports() async {
    final db = await DatabaseHelper.instance.database;
    final List<Map<String, dynamic>> unsynced = await db.query(
      'local_reports',
      where: 'is_synced = ?',
      whereArgs: [0],
    );

    for (var row in unsynced) {
      final reportData = jsonDecode(row['payload']);

      // 1. Insert the master Daily Report
      final mainReport = await _supabase
          .from('daily_reports')
          .insert({
            'project_id': row['project_id'],
            'report_date': row['report_date'],
            'weather': reportData['climate'],
          })
          .select()
          .single();

      final String reportId = mainReport['id'];

      // 2. Map Unified laborEntries to 'labor_logs' table
      // Internal workers will have a staff_id; External workers will not.
      final List labor = reportData['labor_entries'];
      if (labor.isNotEmpty) {
        await _supabase
            .from('labor_logs')
            .insert(
              labor
                  .map(
                    (l) => {
                      'report_id': reportId,
                      'staff_id':
                          l['staff_id'], // UUID for internal, null for external
                      'hours_worked': l['hours_worked'],
                      'is_overtime': l['is_overtime'] ?? false,
                    },
                  )
                  .toList(),
            );
      }

      // 3. Mark as synced in SQLite
      await db.update(
        'local_reports',
        {'is_synced': 1},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
  }
}
