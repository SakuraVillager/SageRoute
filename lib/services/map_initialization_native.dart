import 'package:amap_map/amap_map.dart';
import 'package:flutter/widgets.dart';
import 'package:x_amap_base/x_amap_base.dart';

void prepareMapPrivacy() {
  AMapInitializer.updatePrivacyAgree(
    const AMapPrivacyStatement(
      hasContains: true,
      hasShow: true,
      hasAgree: true,
    ),
  );
}

void initializeNativeMap(BuildContext context, String key) {
  AMapInitializer.init(
    context,
    apiKey: key.isEmpty ? null : AMapApiKey(androidKey: key),
  );
}
