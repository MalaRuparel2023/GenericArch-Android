package genericarch.convention

import com.android.build.api.dsl.LibraryExtension
import org.gradle.api.JavaVersion
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.VersionCatalogsExtension
import org.gradle.kotlin.dsl.configure
import org.gradle.kotlin.dsl.getByType

/**
 * Applied by every `:core:*` and `:feature:*` module that needs the Android SDK.
 *
 * A module applying this plugin must still build and test standalone — that property, not the
 * folder layout, is what enforces the module boundaries.
 */
class AndroidLibraryConventionPlugin : Plugin<Project> {

    override fun apply(target: Project) = with(target) {
        pluginManager.apply("com.android.library")
        pluginManager.apply("org.jetbrains.kotlin.android")

        val libs = extensions.getByType<VersionCatalogsExtension>().named("libs")
        fun version(alias: String) = libs.findVersion(alias).get().requiredVersion

        extensions.configure<LibraryExtension> {
            compileSdk = version("compileSdk").toInt()

            defaultConfig {
                minSdk = version("minSdk").toInt()
                testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
                consumerProguardFiles("consumer-rules.pro")
            }

            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }

            // A library never ships BuildConfig: a feature must not branch on build configuration
            // at all, and generating the class is an invitation to do exactly that.
            buildFeatures.buildConfig = false

            lint {
                warningsAsErrors = true
                error += setOf("NewApi", "HardcodedText", "MissingTranslation")
            }

            testOptions.unitTests {
                isIncludeAndroidResources = true
                isReturnDefaultValues = true
            }
        }
    }
}
