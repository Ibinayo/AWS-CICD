#!/bin/bash
name: Build and Deploy

on:
  workflow_dispatch: {}

env:
  applicationfolder: spring-boot-hello-world-example
  AWS_REGION: us-east-1
  S3BUCKET: codedeploystack-webappdeploymentbucket-rv32pf4p6le3

jobs:
  build:
    name: Build and Package
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: arn:aws:iam::851725449366:role/CodeDeployRoleforGitHub
          role-session-name: GitHub-Action-Role
          aws-region: us-east-1

      - name: Set up JDK 1.8
        uses: actions/setup-java@v1
        with:
          java-version: 1.8

      - name: Debug - Check if build.sh Exists
        run: ls -l $GITHUB_WORKSPACE/.github/scripts/

      - name: Ensure build.sh is Executable
        run: chmod +x $GITHUB_WORKSPACE/.github/scripts/build.sh

      - name: Convert Line Endings (Fix CRLF Issues)
        run: sudo apt-get install dos2unix && dos2unix $GITHUB_WORKSPACE/.github/scripts/build.sh

      - name: Build and Package Maven
        id: package
        run: $GITHUB_WORKSPACE/.github/scripts/build.sh

      - name: Upload Artifact to S3
        working-directory: ${{ env.applicationfolder }}/target
        run: aws s3 cp *.war s3://${{ env.S3BUCKET }}/

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: Dev
    permissions:
      id-token: write
      contents: read
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v2

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          role-to-assume: ${{ secrets.IAMROLE_GITHUB }}
          role-session-name: GitHub-Action-Role
          aws-region: ${{ env.AWS_REGION }}

      - name: Deploy to AWS CodeDeploy
        run: |
          echo "Deploying branch ${{ github.ref }} to ${{ github.event.inputs.environment }}"
          commit_hash=`git rev-parse HEAD`
          aws deploy create-deployment \
            --application-name CodeDeployAppNameWithASG \
            --deployment-group-name CodeDeployGroupName \
            --github-location repository=$GITHUB_REPOSITORY,commitId=$commit_hash \
            --ignore-application-stop-failures


