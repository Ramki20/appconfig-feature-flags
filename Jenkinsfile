pipeline {
    agent any
    
    environment {
        AWS_REGION = 'us-east-1'
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
                    // Extract the branch name to use as environment name
                    env.BRANCH_NAME = sh(script: 'git rev-parse --abbrev-ref HEAD', returnStdout: true).trim()
                    
                    // Extract configuration file name without extension
                    env.CONFIG_FILE_NAME = params.CONFIG_FILE.replaceAll('\\.json$', '')
                    
                    // Read the config file content
                    env.CONFIG_CONTENT = sh(script: "cat ${CONFIG_DIR}/${params.CONFIG_FILE}", returnStdout: true).trim()
                    
                    // Extract version from the config file
                    env.CONFIG_VERSION = sh(script: "jq -r '.version' ${CONFIG_DIR}/${params.CONFIG_FILE}", returnStdout: true).trim()
                }
            }
        }
        
        stage('Validate Config') {
            steps {
                sh './scripts/validate_config.sh ${CONFIG_DIR}/${params.CONFIG_FILE}'
            }
        }
        
        stage('Initialize Terraform') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    sh """
                    terraform plan \
                      -var="environment=${env.BRANCH_NAME}" \
                      -var="config_file_name=${env.CONFIG_FILE_NAME}" \
                      -var="config_content=${env.CONFIG_CONTENT}" \
                      -var="config_version=${env.CONFIG_VERSION}" \
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
        
        stage('Verify Deployment') {
            steps {
                script {
                    // Get deployment ID from Terraform outputs
                    def deploymentId = sh(
                        script: 'cd terraform && terraform output -raw deployment_id',
                        returnStdout: true
                    ).trim()
                    
                    // Get application ID from Terraform outputs
                    def applicationId = sh(
                        script: 'cd terraform && terraform output -raw application_id',
                        returnStdout: true
                    ).trim()
                    
                    // Get environment ID from Terraform outputs
                    def environmentId = sh(
                        script: 'cd terraform && terraform output -raw environment_id',
                        returnStdout: true
                    ).trim()
                    
                    // Wait and check deployment status
                    sh """
                    for i in {1..10}; do
                        status=\$(aws appconfig get-deployment \
                            --application-id ${applicationId} \
                            --environment-id ${environmentId} \
                            --deployment-number ${deploymentId} \
                            --region ${AWS_REGION} \
                            --query "DeploymentState" \
                            --output text)
                        
                        echo "Deployment status: \$status"
                        
                        if [ "\$status" == "COMPLETE" ]; then
                            echo "Deployment completed successfully!"
                            break
                        elif [ "\$status" == "FAILED" ]; then
                            echo "Deployment failed!"
                            exit 1
                        fi
                        
                        if [ \$i -eq 10 ]; then
                            echo "Deployment timed out!"
                            exit 1
                        fi
                        
                        sleep 5
                    done
                    """
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