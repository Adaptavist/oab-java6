#!/bin/bash

# Exit on error
set -e

# Treat using unset variables as an error
set -u

function usage () {
  echo  "$( basename $0 )  [--snapshot] --version <version> [--file <file>|--all-files]"
}


# Basic option handling
while (( $# > 0 ))
do
  opt="$1"

  case $opt in
    --help)
        usage
        exit 0
        ;;
    --snapshot)
        SNAPSHOT="-snapshots"
        ;;
    --version)
        VERSION="$2"
        shift
        ;;
    --deb-file)
        FILELIST_DEB="$2"
        shift
        ;;
    --rpm-file)
        FILELIST_RPM="$2"
        shift
        ;;
    --all-files)
        FILELIST_DEB=`echo /tmp/oab/*.deb`
        FILELIST_RPM=`echo /tmp/oab/pkg/*.rpm`
        ;;
    --*)
        echo "Invalid option: '$opt'"
        usage
        exit 1
        ;;
    *)
       # end of long options
       break
       ;;
  esac
  shift # do this after the case statements, so the first param is not lost!
done

MVN_URL=${MVN_URL:-"https://nexus.adaptavist.com/content/repositories/"}
MVN_REPOID=${MVN_REPOID:-"nexus"}
MVN_GROUPID=${MVN_GROUPID:-"com.adaptavist.mama.avst-app"}
MVN_REPO=${MVN_REPO:-"adaptavist"}
if [[ ! -z "${SNAPSHOT:-}" ]]; then
MVN_REPO="adaptavist${SNAPSHOT:-}"
fi

for FILE in ${FILELIST_DEB}; do
    #TODO: Only does .debs for now
    echo "Publishing \"${FILE}\" now"
    MVN_DESC=$( dpkg --info ${FILE} | fgrep Description | sed -e's/[^:]*: //' )
    MVN_ARTIFACT=$( echo ${FILE} | sed -e's/_.*//' )
    CMD="mvn org.apache.maven.plugins:maven-deploy-plugin:2.8.1:deploy-file \
                         -Durl=${MVN_URL}/${MVN_REPO} \
                         -DrepositoryId=${MVN_REPOID} \
                         -Dfile=${FILE} \
                         -DgroupId=${MVN_GROUPID} \
                         -DartifactId=${MVN_ARTIFACT} \
                         -Dclassifier=all \
                         -Dpackaging=deb \
                         -DgeneratePom=true \
                         -DgeneratePom.description=\"${MVN_DESC}\""
    echo "Running: >>>>${CMD}<<<<<"
    eval ${CMD}
  done

for FILE in ${FILELIST_RPM}; do
    echo "Publishing \"${FILE}\" now"
    MVN_DESC=$( rpm -q -i -p ${FILE} | fgrep Summary | sed -e's/[^:]*: //' )
    MVN_ARTIFACT=$( echo ${FILE} | sed -e's/_.*//' )
    CMD="mvn org.apache.maven.plugins:maven-deploy-plugin:2.8.1:deploy-file \
                         -Durl=${MVN_URL}/${MVN_REPO} \
                         -DrepositoryId=${MVN_REPOID} \
                         -Dfile=${FILE} \
                         -DgroupId=${MVN_GROUPID} \
                         -DartifactId=${MVN_ARTIFACT} \
                         -Dclassifier=all \
                         -Dpackaging=rpm \
                         -DgeneratePom=true \
                         -DgeneratePom.description=\"${MVN_DESC}\""
    echo "Running: >>>>${CMD}<<<<<"
    eval ${CMD}
done

exit 0

