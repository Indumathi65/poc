pipeline {
    agent any
    
    environment {
        REGISTRY = "appdemo.azureecr.io"  // Docker Hub, ECR, or GCP Artifact Registry
        IMAGE_NAME = "test"
        IMAGE_TAG = "latest" // Change as needed, e.g., use BUILD_NUMBER
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh "docker build -t $REGISTRY/$IMAGE_NAME:$IMAGE_TAG ."
                }
            }
        }
    }
}
