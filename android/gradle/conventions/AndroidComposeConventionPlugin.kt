package genericarch.convention

import com.android.build.api.dsl.CommonExtension
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.VersionCatalogsExtension
import org.gradle.kotlin.dsl.dependencies
import org.gradle.kotlin.dsl.getByType
import org.gradle.kotlin.dsl.withType
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

/**
 * Applied on top of the application or library convention by any module that renders UI.
 *
 * Compose is a choice, not a detection: a module that does not draw gets neither the compiler nor
 * the runtime, which keeps `:core:model` and `:core:common` honest.
 */
class AndroidComposeConventionPlugin : Plugin<Project> {

    override fun apply(target: Project) = with(target) {
        pluginManager.apply("org.jetbrains.kotlin.plugin.compose")

        val android = extensions.findByType(CommonExtension::class.java)
            ?: error(
                "Apply AndroidApplicationConventionPlugin or AndroidLibraryConventionPlugin " +
                    "before AndroidComposeConventionPlugin.",
            )
        android.buildFeatures.compose = true

        val libs = extensions.getByType<VersionCatalogsExtension>().named("libs")

        dependencies {
            val bom = platform(libs.findLibrary("compose-bom").get())
            add("implementation", bom)
            add("androidTestImplementation", bom)
            add("implementation", "androidx.compose.ui:ui")
            add("implementation", "androidx.compose.ui:ui-tooling-preview")
            add("implementation", "androidx.compose.material3:material3")
            add("implementation", libs.findLibrary("lifecycle-runtime-compose").get())
            add("debugImplementation", "androidx.compose.ui:ui-tooling")
        }

        // Stability and recomposition metrics: the only way "why does this recompose" stops being
        // a guess. Written under build/compose-metrics; read when a screen janks.
        val metricsDir = layout.buildDirectory.dir("compose-metrics").get().asFile.path
        tasks.withType<KotlinCompile>().configureEach {
            compilerOptions.freeCompilerArgs.addAll(
                "-P",
                "plugin:androidx.compose.compiler.plugins.kotlin:metricsDestination=$metricsDir",
                "-P",
                "plugin:androidx.compose.compiler.plugins.kotlin:reportsDestination=$metricsDir",
            )
        }
    }
}
