import '../route_planning/amap_gateway.dart';
import 'native_amap_gateway.dart';

AmapGateway createRouteGateway() => const NativeAmapGateway();
