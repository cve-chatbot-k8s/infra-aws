pipeline {
    agent any
    environment {
        GH_TOKEN = credentials('github-credentials')
    }
    tools {
        terraform 'Terraform' // Referencing the tool name configured in JCasC
    }
    stages {
        stage('Checkout Repository') {
            steps {
                checkout scm
            }
        }
        stage('Initialize Terraform') {
            steps {
                sh 'terraform init'
            }
        }
        stage('Terraform Format') {
            steps {
                sh 'terraform fmt -check'
            }
        }
        stage('Validate Terraform') {
            steps {
                sh 'terraform validate'
            }
        }
    }
    post {
        always {
            echo 'Pipeline complete'
        }
        success {
            echo 'Pipeline succeeded'
        }
        failure {
            echo 'Pipeline failed'
        }
    }
}
