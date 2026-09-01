package genericarch.convention

import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.VersionCatalogsExtension
import org.gradle.api.tasks.testing.Test
import org.gradle.api.tasks.testing.logging.TestExceptionFormat
import org.gradle.kotlin.dsl.dependencies
import org.gradle.kotlin.dsl.getByType
import org.gradle.kotlin.dsl.withType

/**
 * Applied by every module that has tests — which is every module.
 *
 * Wires the three device-free tiers (unit, screenshot, Robolectric) and the shared fakes. The
 * instrumented tier is deliberately absent: it belongs to CI on merge, not to every module on
 * every push.
 */
class AndroidTestConventionPlugin : Plugin<Project> {

    override fun apply(target: Project) = with(target) {
        pluginManager.apply("app.cash.paparazzi")

        val libs = extensions.getByType<VersionCatalogsExtension>().named("libs")

        dependencies {
            add("testImplementation", libs.findLibrary("junit").get())
            add("testImplementation", libs.findLibrary("coroutines-test").get())
            add("testImplementation", libs.findLibrary("turbine").get())
            add("testImplementation", libs.findLibrary("robolectric").get())
            add("testImplementation", libs.findLibrary("truth").get())

            // No network in tests. Every binding needs a double, and the doubles live in one module
            // so a feature cannot quietly hand-roll one that talks to the wire.
            if (path != ":testing") {
                add("testImplementation", project(":testing"))
            }
        }

        tasks.withType<Test>().configureEach {
            // Determinism, not preference: a UTC runner and a tr-TR laptop must agree.
            systemProperty("user.timezone", "UTC")
            systemProperty("user.language", "en")
            systemProperty("user.country", "US")

            testLogging {
                exceptionFormat = TestExceptionFormat.FULL
                showStandardStreams = false
                events("failed", "skipped")
            }

            maxParallelForks = (Runtime.getRuntime().availableProcessors() / 2).coerceAtLeast(1)
        }
    }
}
