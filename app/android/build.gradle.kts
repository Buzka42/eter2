allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    // Plugins that assume AGP 9 supplies a Kotlin extension even when
    // Flutter's compatibility mode explicitly disables built-in Kotlin
    // (`android.builtInKotlin=false`). They see AGP 9, skip applying the
    // Kotlin Gradle plugin themselves, and their Kotlin sources are then never
    // compiled — the failure is `cannot find symbol` on the plugin's own
    // registrant class, which does not name Kotlin anywhere.
    //
    // Applying the declared plugin here before the package is evaluated is the
    // fix, and it has to be per-package: turning `builtInKotlin` on globally
    // would collide with every plugin that still applies KGP itself, which is
    // most of them.
    if (name == "jni" || name == "file_picker") {
        pluginManager.apply("org.jetbrains.kotlin.android")
        // And their `kotlinOptions` block is inside the same `if (!isAgp9)`
        // guard, so the Kotlin tasks fall back to the toolchain default while
        // the Java tasks stay on the 17 the plugin does declare. Gradle
        // refuses the pair, and the message names neither the plugin nor AGP.
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>()
            .configureEach {
                compilerOptions.jvmTarget.set(
                    org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17,
                )
            }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
