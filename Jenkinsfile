
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
          sh '''
            terrascan scan \
              -i terraform \
              -d . \
              --non-recursive
         '''
       }
     }
    }

    // -------------------------
    // TERRAFORM INIT
    // -------------------------
  
    stage('Terraform Init') {
      steps {
        dir("${TF_WORKDIR}") {
          sh """
            rm -rf .terraform .terraform.lock.hcl
            terraform init -reconfigure -backend-config=backend.config
          """
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
    // APPLY
    // -------------------------
    stage("Terraform Apply") {
      steps {
        dir("${TF_WORKDIR}") {
          script {

           if (env.GIT_BRANCH.contains("prod")) {
             if (fileExists('tfplan')) {

                sh "terraform apply tfplan"

              } else {
                echo "No tfplan found"
             }

           } else {
             echo "Skipping apply - not dev branch"
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