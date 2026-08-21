package com.sageroute.sageroute

import android.content.Context
import android.util.Log
import com.amap.api.services.core.LatLonPoint
import com.amap.api.services.core.ServiceSettings
import com.amap.api.services.route.DriveRouteResult
import com.amap.api.services.route.RouteSearch
import com.amap.api.services.route.WalkRouteResult
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * 通过高德 Android SDK 的 RouteSearch 做驾车/步行路径规划。
 *
 * 与 Flutter 端 lib/services/native_amap_gateway.dart 通过 MethodChannel
 * "com.sageroute/route_planning" 通信。
 */
class RoutePlanningHandler(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, CHANNEL)

    companion object {
        const val CHANNEL = "com.sageroute/route_planning"
        private var privacyAgreed = false
    }

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
    }

    private fun ensurePrivacy() {
        if (privacyAgreed) return
        // 高德 SDK 合规要求：使用任何服务前必须声明隐私政策已展示并同意。
        ServiceSettings.updatePrivacyShow(context, true, true)
        ServiceSettings.updatePrivacyAgree(context, true)
        privacyAgreed = true
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        Log.wtf("SageRoute", "[ROUTE] onMethodCall FIRED method=${call.method}")  // wtf 级别永远不会被过滤
        try {
            when (call.method) {
                "calculateDriveRoute" -> calculateDriveRoute(call, result)
                "calculateWalkRoute" -> calculateWalkRoute(call, result)
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            Log.e("SageRoute", "[ROUTE] 未捕获异常: ${e.message}", e)
            result.error("UNCAUGHT", e.message, null)
        }
    }

    private fun calculateDriveRoute(call: MethodCall, result: MethodChannel.Result) {
        ensurePrivacy()

        val originLat = call.argument<Double>("originLat")
        val originLon = call.argument<Double>("originLon")
        val destLat = call.argument<Double>("destLat")
        val destLon = call.argument<Double>("destLon")

        if (originLat == null || originLon == null || destLat == null || destLon == null) {
            Log.e("SageRoute", "[ROUTE] 坐标参数缺失: lat=$originLat lon=$originLon dLat=$destLat dLon=$destLon")
            result.error("BAD_ARGS", "坐标参数缺失", null)
            return
        }

        val rawWaypoints = call.argument<List<Map<String, Double>>>("waypoints") ?: emptyList()

        val from = LatLonPoint(originLat, originLon)
        val to = LatLonPoint(destLat, destLon)
        val passedBy = rawWaypoints.mapNotNull { wp ->
            val lat = wp["lat"]
            val lon = wp["lon"]
            if (lat != null && lon != null) LatLonPoint(lat, lon) else null
        }

        Log.d("SageRoute", "[ROUTE] 驾车: from=($originLat,$originLon) to=($destLat,$destLon) waypoints=${passedBy.size}")

        val routeSearch = RouteSearch(context)
        routeSearch.setRouteSearchListener(object : RouteSearch.OnRouteSearchListener {
            override fun onDriveRouteSearched(data: DriveRouteResult?, errorCode: Int) {
                Log.d("SageRoute", "[ROUTE] onDriveRouteSearched errorCode=$errorCode")
                if (errorCode != 1000) {
                    Log.e("SageRoute", "[ROUTE] 高德路径规划失败，错误码=$errorCode")
                    result.error("ROUTE_ERROR", "高德路径规划失败，错误码=$errorCode", null)
                    return
                }
                val path = data?.paths?.firstOrNull()
                Log.d("SageRoute", "[ROUTE] data=${data != null}, pathsCount=${data?.paths?.size ?: 0}, firstPath=${path != null}")
                if (path == null) {
                    Log.e("SageRoute", "[ROUTE] 未返回任何路径")
                    result.error("NO_PATH", "未返回任何路径", null)
                    return
                }

                Log.d("SageRoute", "[ROUTE] distance=${path.distance}, duration=${path.duration}, stepsCount=${path.steps.size}")

                // 收集所有 step 的 polyline 点，输出为 [[lat, lon], ...]
                val polyline = ArrayList<List<Double>>()
                for ((i, step) in path.steps.withIndex()) {
                    val stepPolyCount = step.polyline.size
                    Log.d("SageRoute", "[ROUTE] step[$i] polylineSize=$stepPolyCount")
                    for (point in step.polyline) {
                        polyline.add(listOf(point.latitude, point.longitude))
                    }
                }
                Log.d("SageRoute", "[ROUTE] totalPolylinePoints=${polyline.size}")

                result.success(
                    mapOf(
                        "distance" to path.distance.toInt(),
                        "duration" to path.duration.toInt(),
                        "polyline" to polyline,
                    )
                )
            }

            override fun onWalkRouteSearched(data: WalkRouteResult?, errorCode: Int) {
                // 驾车查询不会触发此回调
            }

            override fun onBusRouteSearched(p0: com.amap.api.services.route.BusRouteResult?, p1: Int) {}
            override fun onRideRouteSearched(p0: com.amap.api.services.route.RideRouteResult?, p1: Int) {}
        })

        val fromAndTo = RouteSearch.FromAndTo(from, to)
        val query = RouteSearch.DriveRouteQuery(
            fromAndTo,
            RouteSearch.DRIVING_SINGLE_DEFAULT,
            passedBy,
            null,
            "",
        )
        routeSearch.calculateDriveRouteAsyn(query)
    }

    private fun calculateWalkRoute(call: MethodCall, result: MethodChannel.Result) {
        ensurePrivacy()

        val originLat = call.argument<Double>("originLat")
        val originLon = call.argument<Double>("originLon")
        val destLat = call.argument<Double>("destLat")
        val destLon = call.argument<Double>("destLon")

        if (originLat == null || originLon == null || destLat == null || destLon == null) {
            Log.e("SageRoute", "[ROUTE] 步行坐标参数缺失")
            result.error("BAD_ARGS", "步行坐标参数缺失", null)
            return
        }

        Log.d("SageRoute", "[ROUTE] 步行: from=($originLat,$originLon) to=($destLat,$destLon)")

        val routeSearch = RouteSearch(context)
        routeSearch.setRouteSearchListener(object : RouteSearch.OnRouteSearchListener {
            override fun onWalkRouteSearched(data: WalkRouteResult?, errorCode: Int) {
                Log.d("SageRoute", "[ROUTE] onWalkRouteSearched errorCode=$errorCode")
                if (errorCode != 1000) {
                    Log.e("SageRoute", "[ROUTE] 高德步行路径规划失败，错误码=$errorCode")
                    result.error("ROUTE_ERROR", "高德步行路径规划失败，错误码=$errorCode", null)
                    return
                }
                val path = data?.paths?.firstOrNull()
                Log.d("SageRoute", "[ROUTE] walk data=${data != null}, pathsCount=${data?.paths?.size ?: 0}")
                if (path == null) {
                    Log.e("SageRoute", "[ROUTE] 步行未返回任何路径")
                    result.error("NO_PATH", "步行未返回任何路径", null)
                    return
                }

                Log.d("SageRoute", "[ROUTE] walk distance=${path.distance}, duration=${path.duration}, stepsCount=${path.steps.size}")

                val polyline = ArrayList<List<Double>>()
                for ((i, step) in path.steps.withIndex()) {
                    for (point in step.polyline) {
                        polyline.add(listOf(point.latitude, point.longitude))
                    }
                }
                Log.d("SageRoute", "[ROUTE] walk totalPolylinePoints=${polyline.size}")

                result.success(
                    mapOf(
                        "distance" to path.distance.toInt(),
                        "duration" to path.duration.toInt(),
                        "polyline" to polyline,
                    )
                )
            }

            override fun onDriveRouteSearched(p0: DriveRouteResult?, p1: Int) {}
            override fun onBusRouteSearched(p0: com.amap.api.services.route.BusRouteResult?, p1: Int) {}
            override fun onRideRouteSearched(p0: com.amap.api.services.route.RideRouteResult?, p1: Int) {}
        })

        val fromAndTo = RouteSearch.FromAndTo(
            LatLonPoint(originLat, originLon),
            LatLonPoint(destLat, destLon),
        )
        val query = RouteSearch.WalkRouteQuery(fromAndTo)
        routeSearch.calculateWalkRouteAsyn(query)
    }
}
