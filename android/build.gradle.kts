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

// Workaround for older Flutter plugins (like flutter_bluetooth_serial) that don't specify a namespace,
// which is required by Android Gradle Plugin (AGP) 8.0+.
subprojects {
    afterEvaluate {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val namespaceStr = android.javaClass.getMethod("getNamespace").invoke(android)
                if (namespaceStr == null) {
                    android.javaClass.getMethod("setNamespace", String::class.java).invoke(android, project.group.toString())
                }
            } catch (e: Exception) {
                // Ignore reflection errors if the plugin doesn't support namespace
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
