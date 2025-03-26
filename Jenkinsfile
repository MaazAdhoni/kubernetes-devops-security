pipeline {
    agent any

    stages {
        stage('Build Artifact - Maven') {
            steps {
                sh "mvn clean package -DskipTests=true"
                archiveArtifacts 'target/*.jar' 
            }
        }

        stage('Unit Tests - JUnit and Jacoco') {
            steps {
                sh "mvn test"
            }
            post {
                always {
                    junit 'target/surefire-reports/*.xml'
                    jacoco execPattern: 'target/jacoco.exec'
                }
            }
        }

        stage('Docker Build and Push') {
            steps {
                withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
                    sh 'printenv'
                    sh 'docker build -t maazadhoni/numeric-app:$GIT_COMMIT .'  // Fixed build command
                    sh 'docker push maazadhoni/numeric-app:$GIT_COMMIT'  // Fixed push command
                }
            }
        }

        stage('Kubernetes Deployment DEV') {  // Fixed syntax error: changed "age" to "stage"
            steps {
                withKubeConfig([credentialsId: 'kubeconfig']) {  // Fixed syntax
                    sh "sed -i 's#replace#maazadhoni/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
                    sh "kubectl apply -f k8s_deployment_service.yaml"
                }
            }
        }
    }
}
