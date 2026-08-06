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

        stage('Build & SonarCloud Analysis') {
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

        stage('Deploy to Nexus') {
            steps {
                sh 'mvn deploy -DskipTests'
            }
        }
    }

    post {
        success {
            echo 'Build, SonarCloud analysis, and Nexus deployment completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Deployment to Nexus was skipped.'
        }

        always {
            cleanWs()
        }
    }
}
