import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/location_record.dart';
import 'supabase_table_repository.dart';

class DongpoCatalog {
  const DongpoCatalog(this.sites, {this.isLocalCopy = false});
  final List<LocationRecord> sites;
  final bool isLocalCopy;
}

/// Public editorial content lives separately from the multi-figure Location table.
class DongpoSiteRepository {
  const DongpoSiteRepository({
    this.table = const SupabaseTableRepository(tableName: 'dongpo_sites'),
  });

  final SupabaseTableRepository table;

  Future<DongpoCatalog> fetchCatalog() async {
    try {
      final sites = await table
          .fetchAll<LocationRecord>(mapper: LocationRecord.fromMap)
          .timeout(const Duration(seconds: 8));
      if (sites.isEmpty) return fetchLocalCatalog();
      sites.sort((a, b) => a.id.compareTo(b.id));
      return DongpoCatalog(List.unmodifiable(sites));
    } catch (_) {
      return fetchLocalCatalog();
    }
  }

  Future<DongpoCatalog> fetchLocalCatalog() async {
    final raw = await rootBundle.loadString('assets/data/dongpo_sites.json');
    final rows = jsonDecode(raw) as List;
    return DongpoCatalog(
      List.unmodifiable(
        rows.map(
          (row) =>
              LocationRecord.fromMap(Map<String, dynamic>.from(row as Map)),
        ),
      ),
      isLocalCopy: true,
    );
  }
}
