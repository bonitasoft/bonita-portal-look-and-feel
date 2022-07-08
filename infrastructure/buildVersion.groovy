pipeline {
    agent any
    options {
        timestamps()
    }
    environment {
        JAVA_HOME = "${env.JAVA_HOME_11}"
    }
    stages {
        stage('Build and deploy') {
            steps {

                configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh("./mvnw -s ${MAVEN_SETTINGS} --no-transfer-progress -B deploy -DskipTests -DaltDeploymentRepository=${env.ALT_DEPLOYMENT_REPOSITORY_STAGING}")
                }
            }
        }
    }
}
