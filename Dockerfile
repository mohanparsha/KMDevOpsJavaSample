#FROM adoptopenjdk/openjdk11:alpine-slim as build
FROM eclipse-temurin:11.0.20.1_1-jdk-ubi9-minimal as build
#FROM maven:3.8.6-openjdk-11 as build

WORKDIR /workspace/app

COPY mvnw .
COPY pom.xml .
COPY src src
COPY .mvn .mvn
RUN ./mvnw clean package -DskipTests
RUN mkdir -p target/dependency && (cd target/dependency; jar -xf ../*.jar)

#FROM adoptopenjdk/openjdk11:alpine-slim
FROM eclipse-temurin:11.0.20.1_1-jdk-ubi9-minimal
VOLUME /tmp
ARG DEPENDENCY=/workspace/app/target/dependency
COPY --from=build ${DEPENDENCY}/BOOT-INF/lib /app/lib
COPY --from=build ${DEPENDENCY}/META-INF /app/META-INF
COPY --from=build ${DEPENDENCY}/BOOT-INF/classes /app
ENTRYPOINT ["java","-Dserver.port=9090","-cp","app:app/lib/*","com.example.demo.DemoApplication"]

