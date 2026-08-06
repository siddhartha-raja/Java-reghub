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

        stage('Generate Version') {
            steps {
                script {

                    def branch = env.BRANCH_NAME ?: sh(
                        script: "git rev-parse --abbrev-ref HEAD",
                        returnStdout: true
                    ).trim()

                    branch = branch.replaceAll('/', '-')

                    def repo = sh(
                        script: "basename -s .git \$(git config --get remote.origin.url)",
                        returnStdout: true
                    ).trim()

                    def sha = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    env.APP_VERSION = "${branch}-${repo}-${env.BUILD_NUMBER}-${sha}"

                    echo "Application Version: ${env.APP_VERSION}"
                }
            }
        }

        stage('Build & SonarCloud Analysis') {
            steps {
                withSonarQubeEnv('SonarCloud') {
                    sh """
                        mvn clean verify sonar:sonar \
                          -Drevision=${env.APP_VERSION} \
                          -Dsonar.projectKey=siddhartha-raja_Java-reghub \
                          -Dsonar.organization=siddhartha-raja \
                          -Dsonar.host.url=https://sonarcloud.io
                    """
                }
            }
        }

        stage('Deploy to Nexus') {
            steps {
                sh """
                    mvn deploy \
                      -DskipTests \
                      -Drevision=${env.APP_VERSION}
                """
            }
        }
    }

    post {
        success {
            echo "Successfully deployed version ${env.APP_VERSION}"
        }

        failure {
            echo "Pipeline failed. Deployment skipped."
        }

        always {
            cleanWs()
        }
    }
}
