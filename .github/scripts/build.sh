#!/bin/bash
set -xe  # Stop on error, print commands

# Change to the correct project directory before running Maven
cd "$(dirname "$0")/../../spring-boot-hello-world-example" || exit 1

# Run Maven build
mvn -Dmaven.test.skip=true clean install
