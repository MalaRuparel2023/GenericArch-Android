package genericarch.convention

import com.android.build.api.dsl.ApplicationExtension
import org.gradle.api.JavaVersion
import org.gradle.api.Plugin
import org.gradle.api.Project
import org.gradle.api.artifacts.VersionCatalogsExtension
import org.gradle.kotlin.dsl.configure
import org.gradle.kotlin.dsl.dependencies
import org.gradle.kotlin.dsl.getByType

/**
 * Applied by `:app` and by nothing else.
 *
 * Owns every setting a composition root needs, so `app/build.gradle.kts` declares only what is
 * genuinely unique to this product: its application id, its flavours, and its feature modules.
 *
 * Every version comes from `libs.versions.toml`. No version is written in this file.
 */
class AndroidApplicationConventionPlugin : Plugin<Project> {

    override fun apply(target: Project) = with(target) {
        pluginManager.apply("com.android.application")
        pluginManager.apply("org.jetbrains.kotlin.android")
        pluginManager.apply("com.google.dagger.hilt.android")
        pluginManager.apply("com.google.devtools.ksp")

        val libs = extensions.getByType<VersionCatalogsExtension>().named("libs")
        fun version(alias: String) = libs.findVersion(alias).get().requiredVersion

        extensions.configure<ApplicationExtension> {
            compileSdk = version("compileSdk").toInt()

            defaultConfig {
                // minSdk is a product decision, never a framework default — see
                // android/rules/module-rules.yaml and the project's DECISIONS.md.
                minSdk = version("minSdk").toInt()
                targetSdk = version("targetSdk").toInt()
                testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
            }

            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }

            buildTypes {
                // Declared explicitly: a build type left to defaults is one nobody can reason about.
                getByName("debug") {
                    isMinifyEnabled = false
                    applicationIdSuffix = ".debug"
                    isPseudoLocalesEnabled = true
                }
                getByName("release") {
                    isMinifyEnabled = true
                    isShrinkResources = true
                    proguardFiles(
                        getDefaultProguardFile("proguard-android-optimize.txt"),
                        file("proguard-rules.pro"),
                    )
                }
            }

            lint {
                warningsAsErrors = true
                // NewApi at error is what makes the compileSdk/minSdk asymmetry safe without
                // raising the floor; HardcodedText and MissingTranslation enforce the string rule.
                error += setOf("NewApi", "HardcodedText", "MissingTranslation")
                checkReleaseBuilds = true
                abortOnError = true
            }

            packaging.resources.excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }

        dependencies {
            add("implementation", libs.findLibrary("hilt-android").get())
            add("ksp", libs.findLibrary("hilt-compiler").get())
        }
    }
}
