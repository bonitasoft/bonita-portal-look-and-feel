node {
    stage('Checkout') {
        sh "git config --global credential.helper 'cache'"
        checkout scm
    }

    stage('Tag') {
        branch = params.BASE_BRANCH
        tag = params.TAG_NAME
        newBrandingVersion = params.NEW_BRANDING_VERSION
        sh """
git checkout -B release/$tag

curr_version=\$(grep -Po -m1 '(?<=<version>).*(?=</version>)' pom.xml)
find . -name pom.xml | xargs -n10 sed -i "s@<version>\${curr_version}</version>@<version>${tag}</version>@"

git commit -a -m "chore(release): release $tag"
git tag $tag
git push origin $tag:$tag
"""
        if (params.pushTagToCommunity) {
            sh """set -eu
git checkout ${tag}
git subtree split --prefix=community -b community_branch
git checkout community_branch
git tag -a community_tag -m "${tag}"
git push git@github.com:bonitasoft/bonita-web.git community_tag:${tag}
"""
        }
    }
}
