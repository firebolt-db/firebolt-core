# JDBC Example

This directory contains a minimal Java application which demonstrates how to use the [Firebolt JDBC driver](https://github.com/firebolt-db/jdbc) to send queries to Firebolt Core. The sample application reads queries from standard input and can be built and run through the included [Gradle wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html) as follows:

```bash
./gradlew --console=plain --quiet run <<< "select 42"
```

Similarly, the sample queries in the parent directory can also be used with the application.

```bash
./gradlew --console=plain --quiet run < ../read_iceberg.sql
```
