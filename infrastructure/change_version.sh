#!/usr/bin/env bash
set -e

usage() {
    echo "*************************************************************************************************************"
    echo "usage: "
    echo "  $0 release_version new_branding_version"
    echo ""
    echo " Change all pom versions to given release_version"
    echo ""
    echo "*************************************************************************************************************"
}

if [ $# -lt 1 ]
then
    usage
    exit 1
fi

# $1 new version
# $2 file
replace_first_version() {
  sed -i "0,/<version>.*<\/version>/s//<version>${1}<\/version>/" $3
}

# $1 pom file
get_current_version() {
    grep -Po -m1 '(?<=<version>).*(?=</version>)' $1
}

BASEDIR=$(dirname $(readlink -f "$0"))/..
pushd $BASEDIR

RELEASE_VERSION=$1
BRANDING_VERSION=$2
CUR_VERSION=$(get_current_version pom.xml)

echo "--- Changing version from $CUR_VERSION to $RELEASE_VERSION"
# replace first <version> value in poms
find . -name "pom.xml" | while read pom; do replace_first_version "${RELEASE_VERSION}" "${BRANDING_VERSION}" "$pom"; done\

popd