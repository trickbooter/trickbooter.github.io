+++
date        = "2016-11-12T15:40:31+11:00"
title       = "A Spark Gradle Project"
tags        = [ "Development", "Spark", "Gradle" ]
categories  = [ "Development", "Spark" ]
+++

## An Empty Spark Project with Gradle Goodies

When I started working with Spark, I was new to many technologies, and one of the most time consuming aspects for me was putting together a set of build tools.

### Objectives

Over the course of this project, I found myself wanting a handful of features from the build.

* Build the code
* Run the tests
* Run Spark integration tests
* Bundle my project into an uberjar for easy use with Spark
* Build a tar file that contains my jar and other files I might want (such as configuration templates)
* Add the git commit hash to the jar manifest

### Using the code

Grab the code from [Github](https://github.com/trickbooter/spark-gradle). Although I have included the Gradle idea and eclipse plugins, I have only tested this on my usual Development tool of IntelliJ (idea). This

1. Open IntelliJ
2. Select Import Project
3. Select the cloned repo
4. Select Gradle as the external model
5. Select 'Auto-Import', 'Create separate module per source set', 'Use gradle wrapper task configuration'
6. Finish

### Layout

_settings.gradle_

Contains the project name, which forms part of the jar name and artifact name.

_build.gradle_

Where the main Gradle action happens.

The [shadow](https://github.com/johnrengelman/shadow) plugin is used create an uber jar. It is the Gradle version of Maven's [shade](https://maven.apache.org/plugins/maven-shade-plugin/) plugin.

```
plugins {
  id 'com.github.johnrengelman.shadow' version '1.2.3'
}
```

I split out aspects of Gradle functions into their own scripts for neatness. To access them we import them in build.gradle

```
apply from: "$rootDir/gradle/dependencies.gradle"
apply from: "$rootDir/gradle/artifacts.gradle"
apply from: "$rootDir/gradle/tests.gradle"
```

_gradle/dependencies.gradle_

A convenient location to maintain our dependencies. Keeping things in arrays makes the nice and easy to use.

```
versions += [
        scala     : "2.11",
        scalaPatch: "1",
        spark     : "2.0.1"
]

libs += [
        commonsIO        : "commons-io:commons-io:2.4",
        commonsLang      : "org.apache.commons:commons-lang3:3.4",
        guava            : "com.google.guava:guava:18.0"
        jodaTime         : "joda-time:joda-time:2.4",
        scala            : "org.scala-lang:scala-library:$versions.scala.$versions.scalaPatch"

dependencies {
    compile libs.commonsIO,
            libs.commonsLang,
            libs.guava,
            libs.jodaTime,
            libs.scala
```

Using Gradle 2.14 also lets us take advantage of the compileOnly feature, which allows dependencies to be used during compile, but are then expected to be provided whilst the code is running. This is the perfect place to put our spark libraries. Until recently Gradle didn't have an equivalent of Maven's providedCompile. For those of us building uber-jar's, that meant we had to jump through hoops to exclude dependencies from the jar. The Spark dependencies are pretty huge, and entirely unnecessary for runtime since the Spark runtime provides them. Thankfully since [Gradle 2.12](https://gradle.org/blog/compile-only-dependencies/), we can now use compileOnly. This makes the dependencies available during coding and buidling, but excludes them from the final artifact dependencies.

```
compileOnly libs.spark,
        libs.sparkSql,
        libs.sparkStreaming
```

_gradle/tests.gradle_

Defines our test tasks. All I have done here is customised the default Gradle test task to ensure Gradle doesn't swallow JUnit's standard out and standard error.

I define maxParallelForks as 1 to prevent JUnit from running parallel tests. We need fine control over creation and destruction of Spark Sessions.
```
test {
    maxParallelForks = 1
}
```

_gradle/artifacts.gradle_

Defines our packaging tasks.

The shadowJar task is our uber-jaring task. The classifier sets the jar filename suffix. When I worked on a Spark Cassandra project I had to relocate com.google within the uber-jar to avoid a conflict with the [Spark Cassandra Connector](https://github.com/datastax/spark-cassandra-connector). The issue is documented [here](http://stackoverflow.com/questions/34209329/guava-version-while-using-spark-shell). I have left the code here for posterity, but isn't necessary if you aren't using the connector. I was also using various JDBC connectors, merging these into a single jar requires use to merge the manifest service files. For me it was sufficient to call mergeServiceFiles(), but you might need to manually relocated or write service files in your case.

```
shadowJar {
    classifier "shadow"
    relocate 'com.google', 'shadow.com.google'
    mergeServiceFiles()
}
```

This code I grabbed from this [gist](https://gist.github.com/JonasGroeger/7620911) with a few modifications. It grabs the commit hash code from the git repo (I assuming you are using git). We can use this to write into our jar manifest later.
```
def getCheckedOutGitCommitHash() {
    def gitFolder = "$projectDir/.git/"
    /*
     * '.git/HEAD' contains either
     *      in case of detached head: the currently checked out commit hash
     *      otherwise: a reference to a file containing the current commit hash
     */
    def head = new File(gitFolder + "HEAD").text.split(":") // .git/HEAD
    def isCommit = head.length == 1 // e5a7c79edabbf7dd39888442df081b1c9d8e88fd

    if (isCommit) return head[0].trim()

    def refHead = new File(gitFolder + head[1].trim()) // .git/refs/heads/master
    refHead.text.trim()
}
```

We can now build the jar manifest and incorporate that git has code we jsut grabbed. This is awesome if you have to integrate or test on a shared platform and need to know exactly what jar is running.
```
jar {
    manifest {
        attributes(
                "Implementation-Title": "Spark-Gradle",
                "Implementation-Descritpion": "A Spark template project built using Gradle",
                "Implementation-Version": getCheckedOutGitCommitHash(),
                "Build-Timestamp": (int) (new Date().getTime() / 1000)
        )
    }
}
```

Lastly we have the tar task that grabs whatever files we want, in addition to the uber jar, and bundles them into a tar for easy distribution.

```
task distribution(type: Tar, dependsOn: shadowJar){
    from shadowJar.outputs.files
    from('src/conf') { into('conf') }
}
```
