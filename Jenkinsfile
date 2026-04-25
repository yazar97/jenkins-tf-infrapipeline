
pipeline {
  agent any

  // -------------------------
  // ENVIRONMENT
  // -------------------------
  environment {
    ENV = "${env.BRANCH_NAME}"
    TF_WORKDIR = "env/${env.BRANCH_NAME}"
    TF_IN_AUTOMATION = "true"
  }

  // -------------------------
  // TRIGGERS
  // -------------------------
  triggers {
    githubPush()
  }

  // -------------------------
  // OPTIONS
  // -------------------------
  options {
    buildDiscarder(logRotator(numToKeepStr:'30'))
    timeout(time: 1, unit: 'HOURS')
    ansiColor('xterm')
    disableConcurrentBuilds()
  }

  // -------------------------
  // PARAMETERS
  // -------------------------
  parameters {
    string(name: 'force_unlock_id', defaultValue: '', description: 'Terraform lock ID')
    string(name: 'tf_target', defaultValue: '', description: 'Target specific resource')

    choice(name: 'tf_destroy', choices: ['false','true'], description: 'Destroy resources')

    string(name: 'resource_name', defaultValue: '', description: 'Resource name')
  }

  // -------------------------
  // STAGES
  // -------------------------
  stages {

    // -------------------------
    // CHECKOUT
    // -------------------------
    stage('Checkout') {
      steps {
        git branch: "${env.BRANCH_NAME}",
            url: 'https://github.com/yazar97/jenkins-tf-infrapipeline.git'
      }
    }

    // -------------------------
    // SECURITY SCAN
    // -------------------------
    stage('Gitleaks') {
      steps {
        sh 'gitleaks detect --source . --exit-code 1'
      }
    }

    // -------------------------
    // LINTING
    // -------------------------
    stage('TFLint') {
      steps {
        dir("${TF_WORKDIR}") {
          sh 'tflint --init'
          sh 'tflint'
        }
      }
    }

    // -------------------------
    // SECURITY SCAN
    // -------------------------
    stage('Terrascan') {
      steps {
        dir("${TF_WORKDIR}") {
          sh 'terrascan scan -t terraform'
        }
      }
    }

    // -------------------------
    // TERRAFORM INIT
    // -------------------------
    stage('Terraform Init') {
      steps {
        dir("${TF_WORKDIR}") {
          sh 'terraform init'
        }
      }
    }

    // -------------------------
    // FORCE UNLOCK
    // -------------------------
    stage('Force Unlock') {
      when {
        expression { params.force_unlock_id?.trim() }
      }
      steps {
        dir("${TF_WORKDIR}") {
          sh "terraform force-unlock -force ${params.force_unlock_id}"
        }
      }
    }

    // -------------------------
    // TERRAFORM PLAN
    // -------------------------
    stage('Terraform Plan') {
      steps {
        dir("${TF_WORKDIR}") {
          script {
            def cmd = "terraform plan -out=tfplan"

            if (params.tf_target != '') {
              cmd += " -target=${params.tf_target}"
            }

            sh cmd
            sh 'terraform show -no-color tfplan > tfplan.txt'
            sh 'cat tfplan.txt'
          }
        }
      }
    }

    // -------------------------
    // PROD APPROVAL
    // -------------------------
    stage('Approval') {
      when {
        expression { env.BRANCH_NAME == 'prod' }
      }
      steps {
        input message: "Approve production deployment?"
      }
    }

    // -------------------------
    // APPLY
    // -------------------------
    stage("Terraform Apply") {
      steps {
        dir("${TF_WORKDIR}") {
          script {

            if (env.GIT_BRANCH == "origin/dev") {

              catchError(buildResult: 'SUCCESS', stageResult: 'FAILURE') {

                if (fileExists('tfplan')) {
                  input "Apply Terraform?"
                  sh "terraform apply tfplan"
                } else {
                  echo "No tfplan found"
                }

              }

            } else {
              echo "No Master - cicd running on ${env.GIT_BRANCH}"
            }

          }
        }
      }
    }

    // -------------------------
    // DESTROY
    // -------------------------
    stage('Terraform Destroy') {
      when {
        expression { params.tf_destroy == 'true' }
      }
      steps {
        dir("${TF_WORKDIR}") {
          script {

            if (env.GIT_BRANCH == "origin/master") {
              input "Confirm destroy?"
              sh "terraform destroy -auto-approve"
            } else {
              echo "Destroy skipped - not on master"
            }

          }
        }
      }
    }
  }

  // -------------------------
  // POST ACTIONS
  // -------------------------
  post {
    success {
      echo "Pipeline Success ✅"
    }
    failure {
      echo "Pipeline Failed ❌"
    }
  }
}