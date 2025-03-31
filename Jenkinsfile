pipeline {
    agent any
    
    tools {
        terraform 'Terraform' // Use the name configured in Global Tool Configuration
    }
    
    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
        CONFIG_DIR = 'config'
    }
    
    parameters {
        string(name: 'CONFIG_FILE', defaultValue: 'test_feature_flags.json', description: 'Name of the feature flags JSON file')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Setup') {
            steps {
                script {
                    env.BRANCH_NAME = 'dev'
                    
                    // Extract configuration file name without extension
                    env.CONFIG_FILE_NAME = params.CONFIG_FILE.replaceAll('\\.json$', '')
                    
                    // Make scripts executable
                    sh 'chmod +x ./scripts/*.sh'
                    
                    // Prepare the configuration file for Terraform
                    //sh "./scripts/prepare_config.sh ${CONFIG_DIR}/${params.CONFIG_FILE} /tmp/prepared_config.json"
                    
                    // Read the prepared config file content
                    //env.CONFIG_CONTENT = sh(script: "cat /tmp/prepared_config.json", returnStdout: true).trim()
                    
                    // Extract version from the config file
                    //env.CONFIG_VERSION = sh(script: "jq -r '.version' ${CONFIG_DIR}/${params.CONFIG_FILE}", returnStdout: true).trim()
                    env.CONFIG_VERSION = 1
                    
                    echo "Configuration file: ${env.CONFIG_FILE_NAME}"
                    echo "Environment (branch): ${env.BRANCH_NAME}"
                    echo "Configuration version: ${env.CONFIG_VERSION}"
                }
            }
        }
        
        //stage('Validate Config') {
        //    steps {
        //        script {
        //            // First make the script executable
        //            sh 'chmod +x ./scripts/validate_config.sh'
                    
                    // Then run it
        //            sh './scripts/validate_config.sh ${CONFIG_DIR}/${params.CONFIG_FILE}'
        //        }
        //    }
        // }
        
        stage('Initialize Terraform') {
            steps {
                dir('terraform') {
                    sh 'terraform init -reconfigure'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh """
                    terraform plan \\
                      -var="environment=${env.BRANCH_NAME}" \\
                      -var="config_file_name=${env.CONFIG_FILE_NAME}" \\
                      -var="config_content=${env.CONFIG_CONTENT}" \\
                      -var="config_version=${env.CONFIG_VERSION}" \\
                      -out=tfplan
                    """
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }
        
    }
    
    post {
        success {
            echo "AWS AppConfig deployment completed successfully!"
        }
        failure {
            echo "AWS AppConfig deployment failed!"
        }
        always {
            // Clean up workspace
            cleanWs()
        }
    }
}