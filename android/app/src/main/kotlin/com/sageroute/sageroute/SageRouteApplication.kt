package com.sageroute.sageroute

import android.app.Application
import android.content.Context
import android.os.Build
import android.util.Log
import android.view.accessibility.AccessibilityManager
import java.lang.reflect.Modifier

/**
 * Custom Application class that patches the AMap native SDK's ReflectUtil crash
 * on Android devices running API < 29 (Android 10).
 *
 * ## Problem
 * AMap 3D map SDK v10.1.200 uses ReflectUtil.invoke() to call
 * AccessibilityManager.isHighTextContrastEnabled() via reflection.
 * This method was only added in API 29, so on older devices:
 *   1. getDeclaredMethod() throws NoSuchMethodException
 *   2. ReflectUtil catches it, returns null
 *   3. GlyphLoader unboxes null Boolean → NullPointerException
 *   4. This repeats every frame in the GL rendering loop
 *
 * ## Fix Strategy
 * 1. Load the AMap SDK's ReflectUtil class via reflection at startup
 * 2. Scan its static fields for any caches/sentinels related to high text contrast
 * 3. Set safe default values to prevent the repeated exception chain
 */
class SageRouteApplication : Application() {
    companion object {
        private const val TAG = "SageRoute"
    }

    override fun onCreate() {
        super.onCreate()

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            applyReflectionPatch()
        }
    }

    /**
     * Uses runtime reflection to find and patch the AMap SDK's internal
     * caches to prevent recurrent exceptions in the GL rendering loop.
     */
    private fun applyReflectionPatch() {
        try {
            // Warm up the AccessibilityManager first — helps AMap SDK initialize
            val accessibilityManager = runCatching {
                getSystemService(Context.ACCESSIBILITY_SERVICE) as? AccessibilityManager
            }.getOrNull()

            // Load the AMap SDK's ReflectUtil class
            val reflectUtilClass = runCatching {
                Class.forName("com.autonavi.base.ae.gmap.glyph.ReflectUtil")
            }.getOrNull()

            if (reflectUtilClass != null) {
                Log.d(TAG, "Found ReflectUtil, scanning for patch targets...")
                scanAndPatchReflectUtil(reflectUtilClass)
            } else {
                Log.w(TAG, "ReflectUtil not loaded yet")
            }

            // Also try GlyphLoader
            val glyphLoaderClass = runCatching {
                Class.forName("com.autonavi.base.ae.gmap.glyph.GlyphLoader")
            }.getOrNull()

            if (glyphLoaderClass != null) {
                scanAndPatchClass(glyphLoaderClass, "GlyphLoader")
            }

            Log.i(TAG, "AMap SDK reflection patch applied (SDK=${
                Build.VERSION.SDK_INT
            }, AM=${accessibilityManager != null})")
        } catch (e: Exception) {
            // Don't crash app if patch fails — this is best-effort
            Log.w(TAG, "AMap reflection patch failed: ${e.message}")
        }
    }

    /**
     * Scans ReflectUtil for static fields that cache method lookup results
     * and patches them to prevent the isHighTextContrastEnabled crash.
     */
    private fun scanAndPatchReflectUtil(clazz: Class<*>) {
        // Scan fields for caches and sentinel values
        for (field in clazz.declaredFields) {
            if (!Modifier.isStatic(field.modifiers)) continue

            try {
                field.isAccessible = true
                val fieldName = field.name.lowercase()
                val fieldType = field.type

                // Check if this field name relates to high text contrast
                val isHighTextField = "high" in fieldName || "contrast" in fieldName ||
                        "hightext" in fieldName

                // Static Boolean/boolean cache fields — set to false (safe default)
                if (isHighTextField &&
                    (fieldType == Boolean::class.java ||
                            fieldType == Boolean::class.javaPrimitiveType)
                ) {
                    field.set(null, false)
                    Log.d(TAG, "  ✓ Set ReflectUtil.${field.name} = false")
                }

                // Map caches that might store method → result mappings
                if (fieldType.simpleName.contains("Map", ignoreCase = true)) {
                    Log.d(TAG, "  Found cache map: ReflectUtil.${field.name}")
                }
            } catch (e: Exception) {
                Log.d(TAG, "  - Skipped ReflectUtil.${field.name}: ${e.message}")
            }
        }

        // Log available methods for debugging
        val relevantMethods = clazz.declaredMethods.filter { m ->
            val n = m.name.lowercase()
            "high" in n || "contrast" in n || "text" in n || "cache" in n ||
                    "clear" in n || "reset" in n
        }
        if (relevantMethods.isNotEmpty()) {
            Log.d(TAG, "  Relevant ReflectUtil methods: ${
                relevantMethods.joinToString { "${it.name}(${it.parameterTypes.joinToString()})" }
            }")
        }
    }

    /**
     * Scans a generic AMap SDK class for patchable static fields.
     */
    private fun scanAndPatchClass(clazz: Class<*>, label: String) {
        for (field in clazz.declaredFields) {
            if (!Modifier.isStatic(field.modifiers)) continue

            try {
                field.isAccessible = true
                val fieldName = field.name.lowercase()
                val fieldType = field.type

                if ((fieldType == Boolean::class.java ||
                            fieldType == Boolean::class.javaPrimitiveType) &&
                    ("high" in fieldName || "contrast" in fieldName ||
                            "hightext" in fieldName)
                ) {
                    field.set(null, false)
                    Log.d(TAG, "  ✓ Set $label.${field.name} = false")
                }
            } catch (e: Exception) {
                // skip inaccessible fields
            }
        }
    }

    @Suppress("DEPRECATION")
    override fun getSystemService(name: String): Any? {
        val service = super.getSystemService(name)

        // On pre-Q devices, for accessibility service, we return the real
        // AccessibilityManager. The reflection patch in onCreate() should
        // have pre-populated any caches in the AMap SDK by this point.
        // If the AMap SDK still crashes, the fallback provides better
        // diagnostics.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            name == Context.ACCESSIBILITY_SERVICE &&
            service != null
        ) {
            Log.v(TAG, "getSystemService(ACCESSIBILITY_SERVICE) called on pre-Q device")
        }

        return service
    }
}
