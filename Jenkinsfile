pipeline {
    agent any

    tools {
        jdk 'jdk17'
        maven 'maven3'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Unit Tests') {
            steps {
                sh 'mvn clean test'
            }
        }

        stage('Integration Tests') {
            steps {
                sh 'mvn verify'
            }
        }

        stage('Package') {
            steps {
                sh 'mvn -DskipTests package'
                archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
            }
        }
    }

    post {
        always {
            junit 'target/surefire-reports/*.xml,target/failsafe-reports/*.xml'
        }
    }
}
