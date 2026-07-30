pipeline {
    agent any

    tools {
        sonarQubeScanner 'SonarScanner'
    }

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

        stage('Verify') {
            steps {
                sh '''
                    java -version
                    mvn -version
                    sonar-scanner --version
                '''
            }
        }

        stage('Build') {
            steps {
                sh 'mvn clean verify'
            }
        }

        stage('Sonar Analysis') {
            steps {
                withSonarQubeEnv('SonarCloud') {
                    sh 'sonar-scanner'
                }
            }
        }
    }
}
