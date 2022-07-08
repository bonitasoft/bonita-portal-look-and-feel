node {
    stage('Checkout') {
        sh "git config --global credential.helper 'cache'"
        checkout scm
    }

    stage('Update version') {
        branch = params.BASE_BRANCH
        newVersion = params.newVersion
        newBrandingVersion = params.NEW_BRANDING_VERSION
        sh """
git branch --force $branch origin/$branch
git checkout $branch
curr_version=\$(grep -Po -m1 '(?<=<version>).*(?=</version>)' pom.xml)
find . -name pom.xml | xargs -n10 sed -i "s@<version>\${curr_version}</version>@<version>${newVersion}</version>@"
git commit -a -m "chore(release): prepare next version ${newVersion}"
git push origin $branch
"""
    }
}