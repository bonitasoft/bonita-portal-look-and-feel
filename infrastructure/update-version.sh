#!/bin/bash

usage() {
    echo "*************************************************************************************************************"
    echo "usage: "
    echo "  $0 new_version"
    echo "*************************************************************************************************************"
}

# $1 new version
# $2 file
replace_first_version() {
    sed -i "0,/<version>.*<\/version>/s//<version>${1}<\/version>/" $2
}

# $1 pom file
get_current_version() {
    grep -Po -m1 '(?<=<version>).*(?=</version>)' $1
}

if [ $# -lt 1 ]
then
usage
exit 1
fi

BASEDIR=$(dirname $(readlink -f "$0"))/..
        cd $BASEDIR

CUR_VERSION=$(get_current_version pom.xml)
NEXT_VERSION=$1
NEXT_VERSION_CUT=$(echo $1| cut -f1 -d'_')

echo "Changing version from $CUR_VERSION to $NEXT_VERSION"
# replace first <version> value in poms
# TODO: replace with maven plugin : mvn versions:set -DnewVersion="$NEXT_VERSION" versions:commit
find . -name "pom.xml" | while read pom; do replace_first_version $NEXT_VERSION "$pom"; done

