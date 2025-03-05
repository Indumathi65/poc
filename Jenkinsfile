pipeline {
    agent any

    environment {
        REGISTRY = "appdemo.azureecr.io"
        IMAGE_NAME = "test"
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Clone Repository') {
            steps {
                checkout scm
            }
        }

        stage('Build and Push Image with Kaniko') {
            steps {
                script {
                    sh """
                    /kaniko/executor \
                    --context . \
                    --dockerfile Dockerfile \
                    --destination=$REGISTRY/$IMAGE_NAME:$IMAGE_TAG
                    """
                }
            }
        }
    }
}
