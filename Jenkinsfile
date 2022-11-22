pipeline {
  agent {
    label 'docker_in_docker'
  }

  options {
    buildDiscarder(logRotator(numToKeepStr: '1', artifactNumToKeepStr: '1'))
  }

  stages {
    stage('Build') {
      steps {
        sh '''
          export DOCKER_BUILDKIT=1
          docker build --progress=plain --tag tkleiber/jenkins:docker .
        '''
      }
    }

    stage('Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'docker_hub_id', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USER')]) {
          sh '''
            docker login -u $DOCKER_USER -p $DOCKER_PASSWORD
            docker image push tkleiber/jenkins:docker
          '''
        }
      }
    }

  }

}