import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Redirect global build output to "../../build"
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

// Apply custom build directories for each subproject
subprojects {
    layout.buildDirectory.set(newBuildDir.dir(name))
}

// Ensure :app project is evaluated before others if needed
subprojects {
    evaluationDependsOn(":app")
}

// Define a clean task that deletes the custom build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
