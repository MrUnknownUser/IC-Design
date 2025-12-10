ThisBuild / version := "1.0"
ThisBuild / scalaVersion := "2.13.14"
ThisBuild / organization := "org.example"

val spinalVersion = "1.12.3"
val spinalCore = "com.github.spinalhdl" %% "spinalhdl-core" % spinalVersion
val spinalLib  = "com.github.spinalhdl" %% "spinalhdl-lib"  % spinalVersion
val spinalIdsl = compilerPlugin("com.github.spinalhdl" %% "spinalhdl-idsl-plugin" % spinalVersion)

lazy val root = (project in file("."))
  .settings(
    name := "aes-spinal",
    libraryDependencies ++= Seq(spinalCore, spinalLib, spinalIdsl),
    fork := true
  )
