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
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Plugins don't always pin their own Java/Kotlin JVM target, so they fall
// back to whatever the Gradle daemon's JDK or AGP's own default is (which
// varies per plugin: photo_manager's Kotlin task defaulted to 21, while
// receive_sharing_intent's Java task defaulted to 1.8). Setting
// sourceCompatibility/jvmTarget properties after the fact (even from
// afterEvaluate) is too late — Kotlin's own build-wide consistency check
// reads the values at task-creation time. A JVM *toolchain*, set the moment
// the Kotlin plugin is applied, drives both javac and kotlinc from the same
// JDK for that module, so they can't disagree. Applied to every subproject
// so it always agrees with the app module too.
subprojects {
    // ":app" already sets its own jvmTarget in android/app/build.gradle.kts,
    // and it's forced to evaluate earlier than other subprojects (see
    // evaluationDependsOn above) — its toolchain is already locked in by the
    // time this fires, so calling jvmToolchain() on it again would error.
    if (name != "app") {
        plugins.withId("kotlin-android") {
            extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
                jvmToolchain(17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
