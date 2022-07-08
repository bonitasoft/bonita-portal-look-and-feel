#!/usr/bin/env bash
set -e

usage() {
    name=$(basename $0)
    echo ""
    echo -e "\e[1mSYNOPSIS\e[0m"
    echo -e "    \e[4m$name\e[0m <version>"
    echo -e "    \e[4m$name\e[0m --help"
    echo ""
    echo -e "\e[1mDESCRIPTION\e[0m"
    echo "    Perform a bonita-portal-look-and-feel release based on current branch."
    echo "      - Change versions to <version> where needed (mostly in pom.xml)"
    echo "      - Create and push tag <version>"
    echo "      - Push tag <version> to bonita-web subtree"
    echo ""
    echo -e "\e[1mARGUMENTS\e[0m"
    echo "    <version>             the version of the release to be done"
    echo "    <branding version>    the branding version of the release to be done"
    echo ""
    echo -e "\e[1mOPTIONS\e[0m"
    echo "    --help           display this help"
    echo ""
    echo -e "\e[1mEXEMPLE\e[0m"
    echo "    Let's say you are on master branch and you want to create a 7.3.2 release based on this branch"
    echo ""
    echo "  Note: if env variable 'NO_PUSH_TO_COMMUNITY' is set, no subtree push will be performed."
    echo ""
    echo "    $ $name 7.3.2 2021.2-XXXX"
    echo "      where XXXX stands for the month and date (ex: 0101 for first of January)"
    echo ""
    echo "    will create release 7.3.2 with master's HEAD as starting point"
    echo ""
}

if [ $# -lt 1 ] || [ $1 = "--help" ]
then
    usage
    exit 1
fi

BASEDIR=$(dirname $(readlink -f "$0"))/..
pushd $BASEDIR

RELEASE_VERSION=$1
BRANDING_VERSION=$2

###################################################################################################
#  Create release
###################################################################################################
# create release branch
git checkout -B release/$RELEASE_VERSION

# Change version
./infrastructure/change_version.sh "$RELEASE_VERSION" "${BRANDING_VERSION}"

# Commit and tag
echo "--- Creating commit and tag"
git commit -a -m "release(${RELEASE_VERSION}): create release $RELEASE_VERSION"
git tag -a $RELEASE_VERSION -m "Release $RELEASE_VERSION"
git push origin $RELEASE_VERSION:$RELEASE_VERSION

###################################################################################################
#  Pushing to subtree repo
###################################################################################################

echo "PUSH_TO_COMMUNITY: $PUSH_TO_COMMUNITY"

if [ -z ${PUSH_TO_COMMUNITY+x} ] || [ "${PUSH_TO_COMMUNITY}" = "true" ]; then
    SUBTREE_REPO=git@github.com:bonitasoft/bonita-web.git
    # splitting subtree, create a branch containing only subtree code
    echo "--- Creating tag to be pushed to subtree $SUBTREE_REPO"
    git subtree split --ignore-joins --prefix=community -b community/release/$RELEASE_VERSION
    git checkout community/release/$RELEASE_VERSION

    # tag and push tag to subtree
    echo "--- Pushing to $SUBTREE_REPO"
    git tag -a community/$RELEASE_VERSION -m 'Release $RELEASE_VERSION'
    git push $SUBTREE_REPO community/$RELEASE_VERSION:$RELEASE_VERSION
else
    echo "NOT pushing tag to community subtree."
fi

popd
