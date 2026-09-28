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

// Keep the build configuration explicit and compatible with AGP 8 without registering
// an afterEvaluate callback after Gradle has already finished evaluating the project.
subprojects {
    if (project.plugins.hasPlugin("com.android.library")) {
        project.extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            if (namespace.isNullOrBlank()) {
                namespace = "com.example.${project.name.replace(Regex("[^A-Za-z0-9_]"), "_")}"
            }
            compileSdk = 35
            defaultConfig.targetSdk = 35
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
