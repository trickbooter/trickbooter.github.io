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

Contains the project name (part of the jar name)

_build.gradle_

Where the main Gradle action happens. I have import various language support plugins, and '[shadow](https://github.com/johnrengelman/shadow)' to allow us to build the uber jar.

_gradle/dependencies.gradle_

A convenient location to maintain our dependencies. Using Gradle 2.14 also lets us take advantage of the compileOnly feature, which allows dependencies to be used during compile, but are then expected to be provided whilst the code is running. This is the perfect place to put our spark libraries.

_gradle/tests.gradle_

Defines our test tasks. All I have done here is customised the default Gradle test task to ensure Gradle doesn't swallow JUnit's standard out and standard error.

_gradle/artifacts.gradle_

Defines our packaging tasks.

### What's next

I'll extend the code in the coming weeks to include some test code.
