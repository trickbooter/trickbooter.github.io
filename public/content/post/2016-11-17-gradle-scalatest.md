+++
date        = "2016-11-17T14:00:31+11:00"
title       = "Ignoring Scalatest Tests By Tag When Using JUnit Runner and Gradle"
tags        = [ "Development", "Gradle" ]
categories  = [ "Development", "Tooling" ]
+++

I use [Drone](https://github.com/drone/drone) for CI for some projects, a fully awesome Docker based build pipeline tool. On one of my projects that uses [Gradle](https://gradle.org/) and [scalatest](http://www.scalatest.org/) I was experience a hang at the end of the build & test phase, prevent further Drone tasks from running. After a lengthly chunk of work and diagnosis I found this [issue](https://github.com/drone/drone/issues/1817) to [Docker](https://www.docker.com/) v1.12, which matched our Docker version on Drone. However, I learnt some things along the way which I'll blog about piece by piece, and first up is ignoring scalatest tests by tag when using JUnit Runner.

### How Did I Get Here

Before finding this [issue](https://github.com/drone/drone/issues/1817), I had determined that it was something to do with the test cleanup. Tests included [Spark](http://spark.apache.org/) integration tests, and I suspected that the hang had something to do with Docker's handling of standard out / standard error.

I was using a pretty typical scalatest setup that included a tag for identifying tasks with database dependencies:

```scala
import org.scalatest._
import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner

@RunWith(classOf[JUnitRunner])
abstract class UnitSpec extends FlatSpec with Matchers with OptionValues with Inside with Inspectors

/* Manage before/after events to manage db setup and teardown */
trait ResetDB extends BeforeAndAfterEach  {
  this: Suite =>

  override def beforeEach() {
    setupDB
    super.beforeEach() // To be stackable, must call super.beforeEach
  }

  override def afterEach() {
    try {
      teardownDB
    } finally {
      super.afterEach() // To be stackable, must call super.afterEach
    }
  }

  def setupDB() {
    // code to run a bunch of scripts against a db
  }

  def teardownDB() {
    code to destroy the db
  }
}

/* Tag tasks that require external resources */
object IntegrationTest extends Tag("integration")

/* Basic test class that forces the db setup to run to ensure basic scripting is ok */
class BuildDBSpec extends UnitSpec with ResetDB {

  "DB Scripts"  should "Deploy Without Error" taggedAs IntegrationTest in {
    assert(true)
  }
}
```

and I called my Scala tests as follows:

```groovy
plugins {
    id 'java'
}

task scalaTest(dependsOn: testClasses, type: JavaExec, group: 'verification') {
    main = 'org.scalatest.tools.Runner'
    classpath = sourceSets.test.runtimeClasspath
    args = ['-R', 'build/classes/test', '-o', '-l', 'integration'] // exclude integration tests
}

task scalaIntegrationTest(dependsOn: testClasses, type: JavaExec, group: 'verification') {
    main = 'org.scalatest.tools.Runner'
    classpath = sourceSets.test.runtimeClasspath
    args = ['-R', 'build/classes/test', '-o']
}
```

I found that making the simple switch to JUnit Runner which could be called natively by Gradle resolved the Drone hang issue. Converting from scalatest Runner to JUnit running is dead easy.

Firstly, add the JUnit library to our Gradle dependencies:

```groovy
// In Gradle, we need to add JUnit as a dependency to testCompile
testCompile "junit:junit:4.12"
```

Now tag your test classes (or base class) with the RunWith attribute:

```scala
// In Scala, to identify our tests as tests to be run with JUnit Runner, I tagged m base class with the RunWith attribute
import org.scalatest._
import org.junit.runner.RunWith
import org.scalatest.junit.JUnitRunner

@RunWith(classOf[JUnitRunner])
abstract class UnitSpec extends FlatSpec with Matchers with OptionValues with Inside with Inspectors
```

Automagically, running Gradle test now calls the default test task, which runs our JUnit tests
```bash
gradle test
```

### Ok, so what did we lose?

Well JUnit Runner doesn't have a native way of interpretting scalatest tags, so in solving my Drone hang problem, I'd also made it difficult to separate unit tests from integration tests. That is, until I found this useful [plugin](https://github.com/maiflai/gradle-scalatest). This plugin adds some language constructs that allow us to filter tests by tag with:

```groovy
test {
    tags {
        exclude 'org.scalatest.tags.Slow' // whatever tags you want to exclude.
    }
}
```

So let's get that working. First we add our plugin, and the dependencies we are told to add in [Getting Started](https://github.com/maiflai/gradle-scalatest#getting-started)

```groovy
plugins {
    id "com.github.maiflai.scalatest" version '0.14'
}

dependencies {
  testCompile 'org.scalatest:scalatest_2.10:3.0.0' // use the correct version of Scala here
  testRuntime 'org.pegdown:pegdown:1.6.0'
}
```

I rubbed my hands together with excitement and fired up my Gradle build:

```bash
gradle test
```

and received this disappointing output:

```bash
:compileJava UP-TO-DATE
:compileGroovy UP-TO-DATE
:compileScala UP-TO-DATE
:processResources UP-TO-DATE
:classes UP-TO-DATE
:jar
:assemble
:compileTestJava UP-TO-DATE
:compileTestGroovy UP-TO-DATE
:compileTestScala UP-TO-DATE
:processTestResources
:testClasses
An exception or error caused a run to abort. This may have been caused by a problematic custom reporter.
java.lang.IncompatibleClassChangeError: class org.objectweb.asm.tree.ClassNode has interface org.objectweb.asm.ClassVisitor as super class
	at java.lang.ClassLoader.defineClass1(Native Method)
	at java.lang.ClassLoader.defineClass(ClassLoader.java:800)
  // rest of stack trace
```

going digging, I can see that the [pegdown](https://github.com/sirthias/pegdown) 0.12 onwards has a specific dependency on [asm](http://asm.ow2.org/) as noted in this [issue](https://github.com/sirthias/pegdown/issues/66).

Adding this to our testRuntime dependencies:

```groovy
plugins {
    id "com.github.maiflai.scalatest" version '0.14'
}

dependencies {
  testCompile 'org.scalatest:scalatest_2.10:3.0.0' // use the correct version of Scala here
  testRuntime 'org.ow2.asm:asm-all:4.2',
              'org.pegdown:pegdown:1.6.0'
}
```

now:

```bash
gradle test
```

yields successful testing:

```bash
:compileJava UP-TO-DATE
:compileGroovy UP-TO-DATE
:compileScala UP-TO-DATE
:processResources UP-TO-DATE
:classes UP-TO-DATE
:compileTestJava UP-TO-DATE
:compileTestGroovy UP-TO-DATE
:compileTestScala
:processTestResources
:testClasses
:test
Discovery starting.

// test output here

Run completed in 10 seconds, 793 milliseconds.
Total number of tests run: 131
Suites: completed 22, aborted 0
Tests: succeeded 131, failed 0, canceled 0, ignored 0, pending 0
All tests passed.

BUILD SUCCESSFUL

Total time: 21.9 secs
```

whoop, we can now add our test filter by tag thanks to the maiflai plugin by adding this to our Gradle build definition:

```groovy
// modify the default test to exclude integration tests, to allow a quick test run with no external dependencies
tasks.withType(Test) {
    tags {
        exclude "integration"
    }
}

// create a new test task that doesn't exclude anything
task integrationTest(dependsOn: testClasses, type: Test, group: 'verification') {
    // don't exclude anything
}
```

Although this is another post entirely, my Drone build script looks like this:
```yaml
compose:
  database:
    image: cassandra:3.0

build:
  image: java:8
  commands:
    - ./gradlew assemble
    - ./gradlew integrationTest

// other stuff
```
