pipeline {
    agent any
    
    environment {
        REGISTRY = "your-registry"  // Docker Hub, ECR, or GCP Artifact Registry
        IMAGE_NAME = "your-image-name"
        IMAGE_TAG = "latest" // Change as needed, e.g., use BUILD_NUMBER
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }

        stage('Install Docker') {
            steps {
                script {
                    sh '''
                    if ! command -v docker &> /dev/null
                    then
                        echo "Docker not found, installing..."
                        apt-get update && apt-get install -y docker.io
                    fi
                    '''
                }
            }
        }

        stage('Check Docker Version') {
            steps {
                script {
                    sh "docker --version"
                }
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
