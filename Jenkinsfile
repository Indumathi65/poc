pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:latest
    command:
    - "/busybox/cat"
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
  volumes:
  - name: docker-config
    secret:
      secretName: acr-secret
"""
        }
    }
    environment {
        ACR_NAME = "appdemo"
        IMAGE_NAME = "myapp"
        IMAGE_TAG = "latest"
        REPO_URL = "https://github.com/Indumathi65/poc.git"
    }
    stages {
        stage('Checkout Code') {
            steps {
                git branch: 'main', url: "${env.REPO_URL}"
            }
        }
        stage('Build & Push with Kaniko') {
            steps {
                container('kaniko') {
                    sh '''
                    /kaniko/executor --context `pwd` --dockerfile Dockerfile \
                    --destination $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_TAG \
                    --skip-tls-verify
                    '''
                }
            }
        }
    }
}
