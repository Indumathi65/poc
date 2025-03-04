pipeline {
    agent any

    environment {
        ACR_NAME = "your-acr-name.azurecr.io"
        IMAGE_NAME = "sample-app"
        IMAGE_TAG = "latest"
        KANIKO_EXEC = "/kaniko/executor"
    }

    stages {
        stage('Checkout Code') {
            steps {
                git 'https://github.com/your-repo/sample-app.git'
            }
        }

        stage('Build and Push Image with Kaniko') {
            steps {
                script {
                    sh '''
                    kubectl run kaniko-runner --rm -i --restart=Never --namespace=jenkins \
                        --image=gcr.io/kaniko-project/executor:latest \
                        --serviceaccount=kaniko \
                        --overrides='{
                            "apiVersion": "v1",
                            "spec": {
                                "containers": [{
                                    "name": "kaniko",
                                    "image": "gcr.io/kaniko-project/executor:latest",
                                    "args": [
                                        "--dockerfile=Dockerfile",
                                        "--context=git://github.com/your-repo/sample-app.git",
                                        "--destination=${ACR_NAME}/${IMAGE_NAME}:${IMAGE_TAG}",
                                        "--cache=true"
                                    ],
                                    "volumeMounts": [{
                                        "name": "kaniko-secret",
                                        "mountPath": "/kaniko/.docker/"
                                    }]
                                }],
                                "volumes": [{
                                    "name": "kaniko-secret",
                                    "secret": {
                                        "secretName": "kaniko-secret"
                                    }
                                }]
                            }
                        }'
                    '''
                }
            }
        }

        stage('Deploy to AKS') {
            steps {
                script {
                    sh '''
                    kubectl apply -f k8s/deployment.yaml
                    '''
                }
            }
        }
    }
}
