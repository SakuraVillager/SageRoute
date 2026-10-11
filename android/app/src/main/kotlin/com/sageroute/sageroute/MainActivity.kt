package com.sageroute.sageroute

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var routePlanningHandler: RoutePlanningHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        routePlanningHandler = RoutePlanningHandler(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        routePlanningHandler?.dispose()
        routePlanningHandler = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
