#!/usr/bin/env groovy
def minorVersion = params.bonitaDocVersion
def branchDocName = params.docBranchName

ansiColor('xterm') {
    node {
        withEnv(["PATH=${env.JAVA_HOME_11}/bin:${env.PATH}", "JAVA_HOME=${env.JAVA_HOME_11}"]) {
            stage('Checkout 🌍') {
                configGitCredentialHelper()
                checkout([$class           : 'GitSCM',
                          branches         : [[name: "*/${params.branchOrTagName}"]],
                          extensions       : [[$class: 'CloneOption', noTags: true, shallow: true, depth: 1, timeout: 10]],
                          userRemoteConfigs: [[url: 'https://github.com/bonitasoft/bonita-web-sp.git', credentialsId: 'github', refspec: "+refs/${params.gitRefs}/${params.branchOrTagName}:refs/remotes/origin/${params.branchOrTagName}"]]]
                )
            }

            stage('Generate ⚙️') {
                configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS')]) {
                sh './mvnw -s ${MAVEN_SETTINGS} --no-transfer-progress -B project-info-reports:dependencies -Ddependency.details.enabled=false -Ddependency.locations.enabled=false -pl :console-common,:console-common-sp,:console-server,:console-server-sp'
                sh './mvnw -s ${MAVEN_SETTINGS} --no-transfer-progress -B -P dependencies initialize '
            }
                stash name: 'bonita-web-dependencies', includes: 'target/bonita-web-dependencies.adoc'
            }

            if (params.createPR) {
                stage('Update documentation ✏️') {
                    unstash "bonita-web-dependencies"
                    withCredentials([
                            usernamePassword(
                                    credentialsId: 'github',
                                    usernameVariable: 'GITHUB_USERNAME',
                                    passwordVariable: 'GITHUB_API_TOKEN')
                    ]) {

                        println "Start generation file"
                        sh "./infrastructure/dependencies/dependencies.sh \\" +
                                "--github-username=${GITHUB_USERNAME} \\" +
                                "--github-api-token=${GITHUB_API_TOKEN} \\" +
                                "--version=${minorVersion} --source-folder=target \\" +
                                "--file-name=bonita-web-dependencies.adoc \\" +
                                "--branch=${branchDocName}"
                        println "File generated"

                        println "Start pull request creation"
                        sh "./infrastructure/dependencies/create_pull_request.sh \\" +
                                "--repository='bonita-doc' \\" +
                                "--github-username=${GITHUB_USERNAME} \\" +
                                "--github-api-token=${GITHUB_API_TOKEN} \\" +
                                "--pr-title='doc(web): list dependencies for version ${minorVersion}'  \\" +
                                "--pr-base-branch-name=${minorVersion} \\" +
                                "--pr-head-branch-name=${branchDocName}"
                        println "Pull request created"
                    }
                }
            }
        }
    }
}

def configGitCredentialHelper() {
    sh """#!/bin/bash +x
        set -e
        echo "Using the git cache credential helper to be able to perform native git commands without passing authentication parameters"
        # Timeout in seconds, ensure we have enough time to perform the whole process between the initial clone and the final branch push
        git config --global credential.helper 'cache --timeout=18000'
    """
}
