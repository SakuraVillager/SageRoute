import 'package:flutter/material.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../models/location_record.dart';
import 'heritage_site_details.dart';

Future<void> showPlanningPlaceDetails(
  BuildContext context,
  LocationRecord site,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => PointerInterceptor(
    child: FractionallySizedBox(
      heightFactor: 0.88,
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: '关闭地点详情',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              child: HeritageSiteDetails(site: site),
            ),
          ),
        ],
      ),
    ),
  ),
);
