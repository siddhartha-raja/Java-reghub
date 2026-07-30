pipeline {
    agent any

    environment {
        MAVEN_HOME = '/opt/maven'
        PATH = "${env.PATH}:${MAVEN_HOME}/bin"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & SonarQube Cloud Analysis') {
            steps {
                withSonarQubeEnv('SonarCloud') {
                    sh '''
                        mvn clean verify sonar:sonar \
                          -Dsonar.projectKey=siddhartha-raja_Java-reghub \
                          -Dsonar.organization=siddhartha-raja \
                          -Dsonar.host.url=https://sonarcloud.io
                    '''
                }
            }
        }
    }
}
