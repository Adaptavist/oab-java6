#!/usr/bin/env bash
# Copyright (c) Martin Wimpress
# http://flexion.org/
# See the file "LICENSE" for the full license governing this code.

# References
#  - https://github.com/rraptorr/sun-java6
#  - http://ubuntuforums.org/showthread.php?t=1090731
#  - http://irtfweb.ifa.hawaii.edu/~lockhart/gpg/gpg-cs.html

# Version
VER="0.3.1-dev"

# check the --fqdn version, if it's absent fall back to hostname
HOSTNAME=$(hostname --fqdn 2>/dev/null)
if [[ $HOSTNAME == "" ]]; then
  HOSTNAME=$(hostname)
fi

# common ############################################################### START #
if [ ! -v SPINNER ]; then
    SPINNER="/-\|"
fi
log="${PWD}/`basename ${0}`.log"

function error_msg() {
    local MSG="${1}"
    echo "${MSG}"
    exit 1
}

function cecho() {
    echo -e "$1"
    echo -e "$1" >>"$log"
    tput sgr0;
}

function ncecho() {
    echo -ne "$1"
    echo -ne "$1" >>"$log"
    tput sgr0
}

function spinny() {
    if [ -n "$SPINNER" ]; then
        echo -ne "\b${SPINNER:i++%${#SPINNER}:1}"
    fi
}

function progress() {
    ncecho "  ";
    while [ /bin/true ]; do
        kill -0 $pid 2>/dev/null;
        if [[ $? = "0" ]]; then
            spinny
            sleep 0.25
        else
            ncecho "\b\b";
            wait $pid
            retcode=$?
            echo "$pid's retcode: $retcode" >> "$log"
            if [[ $retcode = "0" ]] || [[ $retcode = "255" ]]; then
                cecho success
            else
                cecho failed
                echo -e " [i] Showing the last 5 lines from the logfile ($log)...";
                tail -n5 "$log"
                exit 1;
            fi
            break 2;
        fi
    done
}

function progress_loop() {
    ncecho "  ";
    while [ /bin/true ]; do
        kill -0 $pid 2>/dev/null;
        if [[ $? = "0" ]]; then
            spinny
            sleep 0.25
        else
            ncecho "\b\b";
            wait $pid
            retcode=$?
            echo "$pid's retcode: $retcode" >> "$log"
            if [[ $retcode = "0" ]] || [[ $retcode = "255" ]]; then
                cecho success
            else
                cecho failed
                echo -e " [i] Showing the last 5 lines from the logfile ($log)...";
                tail -n5 "$log"
                exit 1;
            fi
            break 1;
        fi
    done
}

function progress_can_fail() {
    ncecho "  ";
    while [ /bin/true ]; do
        kill -0 $pid 2>/dev/null;
        if [[ $? = "0" ]]; then
            spinny
            sleep 0.25
        else
            ncecho "\b\b";
            wait $pid
            retcode=$?
            echo "$pid's retcode: $retcode" >> "$log"
            cecho success
            break 2;
        fi
    done
}

# function check_root() {
#     if [ "$(id -u)" != "0" ]; then
#         error_msg "ERROR! You must execute the script as the 'root' user."
#     fi
# }

# function check_sudo() {
#     if [ ! -n ${SUDO_USER} ]; then
#         error_msg "ERROR! You must invoke the script using 'sudo'."
#     fi
# }

function check_ubuntu() {
    if [ "${1}" != "" ]; then
        SUPPORTED_CODENAMES="${1}"
    else
        SUPPORTED_CODENAMES="all"
    fi

    # Source the lsb-release file.
    lsb

    # Check if this script is supported on this version of Ubuntu.
    if [ "${SUPPORTED_CODENAMES}" == "all" ]; then
        SUPPORTED=1
    else
        SUPPORTED=0
        for CHECK_CODENAME in `echo ${SUPPORTED_CODENAMES}`
        do
            if [ "${LSB_CODE}" == "${CHECK_CODENAME}" ]; then
                SUPPORTED=1
            fi
        done
    fi

    if [ ${SUPPORTED} -eq 0 ]; then
        error_msg "ERROR! ${0} is not supported on this version of Ubuntu."
    fi
}

function lsb() {
    local CMD_LSB_RELEASE=`which lsb_release`
    if [ "${CMD_LSB_RELEASE}" == "" ]; then
        error_msg "ERROR! 'lsb_release' was not found. I can't identify your distribution."
    fi
    LSB_ID=`lsb_release -i | cut -f2 | sed 's/ //g'`
    LSB_REL=`lsb_release -r | cut -f2 | sed 's/ //g'`
    LSB_CODE=`lsb_release -c | cut -f2 | sed 's/ //g'`
    LSB_DESC=`lsb_release -d | cut -f2`
    LSB_ARCH=`dpkg --print-architecture`
    LSB_MACH=`uname -m`
    LSB_NUM=`echo ${LSB_REL} | sed s'/\.//g'`
}

# function apt_update() {
#     ncecho " [x] Update package list "
#     apt-get -y update >>"$log" 2>&1 &
#     pid=$!;progress $pid
# }
# common ################################################################# END #

function copyright_msg() {
    local MODE=${1}
    if [ "${MODE}" == "build_docs" ]; then
        echo "# OAB-Java"
    fi
    echo `basename ${0}`" v${VER} - Create a local 'apt' repository for Sun Java 6 and/or Oracle Java 7 packages."
    echo
    echo "Copyright (c) Martin Wimpress, http://flexion.org. MIT License"
    echo
    echo "By running this script to download Java you acknowledge that you have"
    echo "read and accepted the terms of the Oracle end user license agreement."
    echo
    echo "* <http://www.oracle.com/technetwork/java/javase/terms/license/>"
    echo
    if [ "${MODE}" == "build_docs" ]; then
        echo "## Donate"
        echo
        echo "If you or your organisation has found `basename ${0}` useful please consider"
        echo "donating to this project. It is nice to have the effort I've put into this"
        echo "script recognised, I don't ask for much, it is at your discretion."
        echo
        echo "[![Donate to OAB-Java](https://www.paypalobjects.com/en_GB/i/btn/btn_donate_SM.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=ESP59ZNJHLBZ8)  [![Flattr OAB-Java](http://api.flattr.com/button/flattr-badge-large.png)](https://flattr.com/submit/auto?user_id=flexiondotorg&url=https://github.com/flexiondotorg/oab-java6&title=oab-java6&language=shell&tags=github&category=software)"
        echo
    fi
    # Adjust the output if we are executing the script.
    # It doesn't make sense to see this message here in the documentation.
    if [ "${MODE}" != "build_docs" ]; then
        echo "If you want to see what this is script is doing while it is running then execute"
        echo "the following from another shell:"
        echo
        echo "    tail -f `pwd`/`basename ${0}`.log"
        echo
    fi
}

function usage() {
    local MODE=${1}
    echo "## Usage"
    echo
    echo "    sudo ${0}"
    echo
    echo "Optional parameters"
    echo
    echo "  * -7              : Build ``oracle-java7`` packages instead of ``sun-java6``"
    echo "  * -8              : Build ``oracle-java8`` packages instead of ``sun-java6``"
    echo "  * -c              : Remove pre-existing packages from ``${WORK_PATH}/deb`` and sources from ``${WORK_PATH}/src``."
    echo "  * -k <gpg-key-id> : Use the specified existing key instead of generating one"
    echo "  * -s              : Skip building if the packages already exist"
    echo "  * -t              : Specify the Java version tag to use from the upstream Debian packaging script."
    echo "  * -h              : This help"
    echo
    echo "## How do I download and run this thing?"
    echo
    echo "Like this."
    echo
    echo "    cd ~/"
    echo "    wget https://github.com/flexiondotorg/oab-java6/raw/${VER}/`basename ${0}` -O `basename ${0}`"
    echo "    chmod +x `basename ${0}`"
    echo "    sudo ./`basename ${0}`"
    echo
    echo "If you are behind a proxy you may need to run using:"
    echo
    echo "    sudo -i ./`basename ${0}`"
    echo
    # Adjust the output if we are building the docs.
    if [ "${MODE}" == "build_docs" ]; then
        echo "If you want to see what this script is doing while it is running then execute"
        echo "the following from another shell:"
        echo
        echo "    tail -f ./`basename ${0}`.log"
        echo
    fi
    echo "## How it works"
    echo
    echo "This script is merely a wrapper for the most excellent Debian packaging"
    echo "scripts prepared by Janusz Dziemidowicz."
    echo
    echo "  * <https://github.com/rraptorr/sun-java6>"
    echo "  * <https://github.com/rraptorr/oracle-java7>"
    echo
    echo "The basic execution steps are:"
    echo
    echo "  * Remove, my now disabled, Java PPA ``ppa:flexiondotorg/java``."
    echo "  * Install the tools required to build the Java packages."
    echo "  * Create download cache in ``${WORK_PATH}/pkg``."
    echo "  * Download the i586 and x64 Java install binaries from Oracle. Yes, both are required (for sun-java6 only)."
    echo "  * Clone the build scripts from <https://github.com/rraptorr/>"
    echo "  * Build the Java packages applicable to your system."
    echo "  * Create local ``apt`` repository in ``${WORK_PATH}/deb`` for the newly built Java Packages."
    echo "  * Create a GnuPG signing key in ``${WORK_PATH}/gpg`` if none exists."
    echo "  * Sign the local ``apt`` repository using the local GnuPG signing key."
    echo
    echo "## What gets installed?"
    echo
    echo "This script will no longer try and directly install or upgrade any Java"
    echo "packages, instead a local ``apt`` repository is created that hosts locally"
    echo "built Java packages applicable to your system. It is up to you to install"
    echo "or upgrade the Java packages you require using ``apt-get``, ``aptitude`` or"
    echo "``synaptic``, etc. For example, once this script has been run you can simply"
    echo "install the JRE by executing the following from a shell."
    echo
    echo "    sudo apt-get install sun-java6-jre"
    echo
    echo "Or if you ran the script with the ``-7`` option."
    echo
    echo "    sudo apt-get install oracle-java7-jre"
    echo
    echo "If you already have the *\"official\"* Ubuntu packages installed then you"
    echo "can upgrade by executing the following from a shell."
    echo
    echo "    sudo apt-get upgrade"
    echo
    echo "The local ``apt`` repository is just that, **local**. It is not accessible"
    echo "remotely and `basename ${0}` will never enable that capability to ensure"
    echo "compliance with Oracle's asinine license requirements."
    echo
    echo "By default, the script creates a temporary GPG keyring in the working"
    echo "directory. In order to use the current user's GPG chain instead, specify"
    echo "the key ID of an existing secret key. Run ``gpg -K`` to list available keys."
    echo
    echo "## Known Issues"
    echo
    echo "  * Building Java 7 on Ubuntu Lucid 10.04 is no longer supported as the upstream scripts"
    echo "  require ``debhelper``>=8 which is not officially available for Lucid."
    echo "  * The Oracle download servers can be horribly slow. My script caches the downloads"
    echo "  so you only need download each file once."
    echo
    echo "## What is 'oab'?"
    echo
    echo "Because, O.A.B! ;-)"
    echo

    # Only exit if we are not build docs.
    if [ "${MODE}" != "build_docs" ]; then
        exit 1
    fi
}

function build_docs() {
    copyright_msg build_docs > README.md

    # Add the usage instructions
    usage build_docs >> README.md

    # Add the CHANGES
    if [ -e CHANGES ]; then
        cat CHANGES >> README.md
    fi

    # Add the AUTHORS
    if [ -e AUTHORS ]; then
        cat AUTHORS >> README.md
    fi

    # Add the TODO
    if [ -e TODO ]; then
        cat TODO >> README.md
    fi

    # Add the LICENSE
    if [ -e LICENSE ]; then
        cat LICENSE >> README.md
    fi

    echo "Documentation built."
    exit 0
}

copyright_msg

# Check we are running on a supported system in the correct way.
# check_root
# check_sudo
check_ubuntu "all"

# Init variables
BUILD_KEY=""
BUILD_CLEAN=0
SKIP_REBUILD=""
# WORK_PATH="/var/local/oab"
WORK_PATH=`pwd`
JAVA_DEV="sun-java"
JAVA_UPSTREAM="sun-java6"

# Remove a pre-existing log file.
if [ -f $log ]; then
    rm -f $log 2>/dev/null
fi

# Parse the options
OPTSTRING=87bchk:st:
while getopts ${OPTSTRING} OPT
do
    case ${OPT} in
        7)
           JAVA_DEV="oracle-java"
           JAVA_UPSTREAM="oracle-java7"
           ;;
        8)
           JAVA_DEV="oracle-java"
           JAVA_UPSTREAM="oracle-java8"
           ;;
        b) build_docs;;
        c) BUILD_CLEAN=1;;
        h) usage;;
        k) BUILD_KEY=${OPTARG};;
        s) SKIP_REBUILD=1;;
        t) TAG=${OPTARG};;
        *) usage;;
    esac
done
shift "$(( $OPTIND - 1 ))"

if [[ ("${JAVA_UPSTREAM}" == "oracle-java7" || "${JAVA_UPSTREAM}" == "oracle-java8") && "${LSB_CODE}" == "lucid" ]]; then
    ncecho " [!] Building Java 7 or 8 on Ubuntu Lucid is no longer supported "
    cecho exitting
    exit 1
fi

# Remove my, now disabled, Java PPA.
if [ -e /etc/apt/sources.list.d/flexiondotorg-java-${LSB_CODE}.list ]; then
    ncecho " [x] Removing ppa:flexiondotorg/java "
    rm -v /etc/apt/sources.list.d/flexiondotorg-java-${LSB_CODE}.list* >> "$log" 2>&1
    cecho success
fi

# Determine the build and runtime requirements.
BUILD_DEPS="build-essential debhelper devscripts dpkg-dev git-core \
gnupg libasound2 libxi6 libxt6 libxtst6 rng-tools unixodbc unzip"

if [ "${LSB_ARCH}" == "amd64" ] && [ "${JAVA_UPSTREAM}" == "sun-java6" ]; then
    BUILD_DEPS="${BUILD_DEPS} lib32asound2 ia32-libs"
    if [ "${LSB_CODE}" == "wheezy" ]; then
        # Wheezy need the i386 arch to enable provide access to the tranisitional ia32-libs.
        # https://github.com/rraptorr/sun-java6/issues/26
        ncecho " [x] Adding i386 architecture "
        dpkg --add-architecture i386
        pid=$!;progress $pid
        apt_update
    fi
fi

if [[ "${JAVA_UPSTREAM}" == "oracle-java7" || "${JAVA_UPSTREAM}" == "oracle-java8" ]]; then
    BUILD_DEPS="${BUILD_DEPS} libxrender1"
fi

# Install the Java build requirements
ncecho " [x] Installing Java build requirements "
#apt-get install -y --no-install-recommends ${BUILD_DEPS} >> "$log" 2>&1 &
pid=$!;progress $pid

# Make sure the required dirs exist.
ncecho " [x] Making build directories "
mkdir -p ${WORK_PATH}/{deb,gpg,pkg,srcs} >> "$log" 2>&1 &
pid=$!;progress $pid

# Set the permissions appropriately for 'gpg'
chown root:root ${WORK_PATH}/gpg 2>/dev/null
chmod 0700 ${WORK_PATH}/gpg 2>/dev/null

if [ -d ${WORK_PATH}/srcs/${JAVA_UPSTREAM}.git ]; then
    # Update the code
    ncecho " [x] Updating from https://github.com/adaptavist/${JAVA_UPSTREAM} "
    cd ${WORK_PATH}/srcs/${JAVA_UPSTREAM}.git/ >> "$log" 2>&1
    git fetch >> "$log" 2>&1 &
    pid=$!;progress $pid
else
    # Mirror the code
    ncecho " [x] Mirroring https://github.com/adaptavist/${JAVA_UPSTREAM} "
    cd ${WORK_PATH}/srcs/ >> "$log" 2>&1
    git clone --mirror https://github.com/adaptavist/${JAVA_UPSTREAM} >> "$log" 2>&1 &
    pid=$!;progress $pid
fi

# Remove the 'src' directory everytime.
ncecho " [x] Removing local clones of ${JAVA_UPSTREAM} "
rm -rfv ${WORK_PATH}/${JAVA_UPSTREAM}* 2>/dev/null >> "$log" 2>&1
rm -rfv ${WORK_PATH}/src 2>/dev/null >> "$log" 2>&1 &
pid=$!;progress $pid

# Get the last commit tag.
cd ${WORK_PATH}/srcs/${JAVA_UPSTREAM}.git/ >> "$log" 2>&1
TAG=${TAG:-`git describe --abbrev=0 --tags`}

# Clone from mirror, pointing to the tagged, stable, version.
ncecho " [x] Cloning ${JAVA_UPSTREAM} with ${TAG} "
cd ${WORK_PATH}/ >> "$log" 2>&1
git clone -b ${TAG} ${WORK_PATH}/srcs/${JAVA_UPSTREAM}.git src >> "$log" 2>&1 &
pid=$!;progress $pid

# Cet the current Debian package version and package urgency
DEB_VERSION=`head -n1 ${WORK_PATH}/src/debian/changelog | cut -d'(' -f2 | cut -d')' -f1 | cut -d'~' -f1`
DEB_URGENCY=`head -n1 ${WORK_PATH}/src/debian/changelog | cut -d'=' -f2`

# Determine the currently supported Java version and update
JAVA_VER=`echo ${DEB_VERSION} | cut -d'.' -f1`
JAVA_UPD=`echo ${DEB_VERSION} | cut -d'.' -f2 | cut -d'-' -f1`

ncecho " [x] Getting releases download page "
if [ "${JAVA_UPSTREAM}" == "sun-java6" ]; then
    wget http://www.oracle.com/technetwork/java/javasebusiness/downloads/java-archive-downloads-javase6-419409.html -O "${WORK_PATH}/oab-download.html" >> "$log" 2>&1 &
elif [ "${JAVA_UPSTREAM}" == "oracle-java7" ]; then
    wget http://www.oracle.com/technetwork/java/javase/downloads/jdk7-downloads-1880260.html -O "${WORK_PATH}/oab-download.html" >> "$log" 2>&1 &
else
    wget http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html -O "${WORK_PATH}/oab-download.html" >> "$log" 2>&1 &
fi
pid=$!;progress $pid

# Set the files we're downloading since sun-java6 and oracle-java7 differ.
if [ "${JAVA_UPSTREAM}" == "sun-java6" ]; then
    JAVA_EXT=.bin
    JAVA_RMP_EXT=-rpm.bin
else
    JAVA_EXT=.tar.gz
    JAVA_RMP_EXT=.rpm
fi
if grep -q 'srcdir.*:=.*$(arch)' ${WORK_PATH}/src/debian/rules; then
    # Upstream requires binary files for both architectures
    JAVA_BINS="jdk-${JAVA_VER}u${JAVA_UPD}-linux-i586${JAVA_EXT} jdk-${JAVA_VER}u${JAVA_UPD}-linux-x64${JAVA_EXT} jdk-${JAVA_VER}u${JAVA_UPD}-linux-x64${JAVA_RMP_EXT} jdk-${JAVA_VER}u${JAVA_UPD}-linux-i586${JAVA_RMP_EXT}"
else
    # Upstream requires binary file of the machine's architecture only
    if [ "${LSB_ARCH}" == "amd64" ]; then
        JAVA_BINS="jdk-${JAVA_VER}u${JAVA_UPD}-linux-x64${JAVA_EXT}"
    else
        JAVA_BINS="jdk-${JAVA_VER}u${JAVA_UPD}-linux-i586${JAVA_EXT}"
    fi
fi

for JAVA_BIN in ${JAVA_BINS}
do
    # Get the download URL and size
    if [ "${JAVA_UPSTREAM}" == "sun-java6" ]; then
        DOWNLOAD_URL=`grep ${JAVA_BIN} "${WORK_PATH}/oab-download.html" | cut -d'{' -f2 | cut -d',' -f3 | cut -d'"' -f4 | sed 's/otn/otn-pub/'`
    else
        DOWNLOAD_URL=`grep ${JAVA_BIN} "${WORK_PATH}/oab-download.html" | cut -d'{' -f2 | cut -d',' -f3 | cut -d'"' -f4`
    fi
    DOWNLOAD_SIZE=`grep ${JAVA_BIN} "${WORK_PATH}/oab-download.html" | cut -d'{' -f2 | cut -d',' -f2 | cut -d':' -f2 | sed 's/"//g'`
    # Cookies required for download
    timestamp=$((`date +%s` + 180000))
    COOKIES="oraclelicense=accept-securebackup-cookie;gpw_e24=http://edelivery.oracle.com;s_cc=true;s_sq=%5B%5BB%5D%5D;s_nr=$timestamp"
    #COOKIES="oraclelicensejdk-${JAVA_VER}u${JAVA_UPD}-oth-JPR=accept-securebackup-cookie;gpw_e24=http://edelivery.oracle.com"

    ncecho " [x] Downloading ${JAVA_BIN} : ${DOWNLOAD_SIZE} "
    
    wget --no-check-certificate --header="Cookie: ${COOKIES}" -c "${DOWNLOAD_URL}" -O ${WORK_PATH}/pkg/${JAVA_BIN} >> "$log" 2>&1 &
    
    pid=$!;progress_loop $pid
    
    if [[ ! "${JAVA_BIN}" =~ .rmp ]]; then  
        ncecho " [x] Symlinking ${JAVA_BIN} "
        ln -s ${WORK_PATH}/pkg/${JAVA_BIN} ${WORK_PATH}/src/${JAVA_BIN} >> "$log" 2>&1 &
        pid=$!;progress_loop $pid
    fi
done

# Get JCE download index
if [ $JAVA_VER == "7" ]; then
    DOWNLOAD_INDEX_NO='432124'
    DOWNLOAD_VERSION="-7"
elif [ $JAVA_VER == "8" ]; then
    DOWNLOAD_INDEX_NO='2133166'
    DOWNLOAD_VERSION="8"
else
    DOWNLOAD_INDEX_NO='429243'
    DOWNLOAD_VERSION="-6"
fi

DOWNLOAD_INDEX="technetwork/java/javase/downloads/jce${DOWNLOAD_VERSION}-download-${DOWNLOAD_INDEX_NO}.html"
wget http://www.oracle.com/${DOWNLOAD_INDEX} -O "${WORK_PATH}/oab-download-jce.html" >> "$log" 2>&1 &
pid=$!;progress $pid

# Get JCE download URL, size, and cookies required for download
if [ "${JAVA_UPSTREAM}" == "sun-java6" ]; then
    JCE_POLICY="jce_policy-6.zip"
    DOWNLOAD_PATH=`grep "jce[^']*-6-oth-JPR'\]\['path" "${WORK_PATH}/oab-download-jce.html" | cut -d'=' -f2 | cut -d'"' -f2`
    DOWNLOAD_URL="${DOWNLOAD_PATH}${JCE_POLICY}"
    COOKIES="oraclelicense=accept-securebackup-cookie;gpw_e24=http://edelivery.oracle.com"
elif [ "${JAVA_UPSTREAM}" == "oracle-java7" ]; then
    JCE_POLICY="UnlimitedJCEPolicyJDK7.zip"
    DOWNLOAD_URL=`grep ${JCE_POLICY} "${WORK_PATH}/oab-download-jce.html" | cut -d'{' -f2 | cut -d',' -f3 | cut -d'"' -f4`
    COOKIES="oraclelicensejce-7-oth-JPR=accept-securebackup-cookie;gpw_e24=http://edelivery.oracle.com"
    timestamp=$((`date +%s` + 180000))
    COOKIES="oraclelicense=accept-securebackup-cookie;gpw_e24=http://edelivery.oracle.com;s_cc=true;s_sq=%5B%5BB%5D%5D;s_nr=$timestamp"
else    
    JCE_POLICY="jce_policy-8.zip"
    DOWNLOAD_URL=`grep ${JCE_POLICY} "${WORK_PATH}/oab-download-jce.html" | cut -d'{' -f2 | cut -d',' -f3 | cut -d'"' -f4`
    COOKIES="oraclelicensejce-8-oth-JPR=accept-securebackup-cookie;gpw_e24=http://edelivery.oracle.com"
    timestamp=$((`date +%s` + 180000))
    COOKIES="oraclelicense=accept-securebackup-cookie;gpw_e24=http://edelivery.oracle.com;s_cc=true;s_sq=%5B%5BB%5D%5D;s_nr=$timestamp"
fi
DOWNLOAD_SIZE=`grep ${JCE_POLICY} "${WORK_PATH}/oab-download-jce.html" | cut -d'{' -f2 | cut -d',' -f2 | cut -d'"' -f4`

ncecho " [x] Downloading ${JCE_POLICY} : ${DOWNLOAD_SIZE} "
wget --no-check-certificate --header="Cookie: ${COOKIES}" -c "${DOWNLOAD_URL}" -O ${WORK_PATH}/pkg/${JCE_POLICY} >> "$log" 2>&1 &
pid=$!;progress_loop $pid

ncecho " [x] Symlinking ${JCE_POLICY} "
ln -s ${WORK_PATH}/pkg/${JCE_POLICY} ${WORK_PATH}/src/${JCE_POLICY} >> "$log" 2>&1 &
pid=$!;progress_loop $pid

# Determine the new version
NEW_VERSION="${DEB_VERSION}~${LSB_CODE}1"

if [ -n "${SKIP_REBUILD}" -a -r "${WORK_PATH}/deb/${JAVA_DEV}${JAVA_VER}_${NEW_VERSION}_${LSB_ARCH}.changes" ]; then
  echo " [!] Package exists, skipping build "
  echo "All done!"
  exit
fi

# Genereate a build message
BUILD_MESSAGE="Automated build for ${LSB_REL} using https://github.com/adaptavist/${JAVA_UPSTREAM}"

# Change directory to the build directory
cd ${WORK_PATH}/src

# Run upstream's preparing script if it exists
if [ -f prepare.sh ]; then
    ncecho " [x] Inflating archives "
    ./prepare.sh >> "$log" 2>&1 &
    pid=$!;progress $pid
fi
# Update the changelog
ncecho " [x] Updating the changelog "
dch --distribution ${LSB_CODE} --force-distribution --newversion ${NEW_VERSION} --force-bad-version --urgency=${DEB_URGENCY} "${BUILD_MESSAGE}" >> "$log" 2>&1 &
pid=$!;progress $pid

# Build the binary packages
ncecho " [x] Building the packages "
dpkg-buildpackage -b >> "$log" 2>&1 &
pid=$!;progress_can_fail $pid

if [ -e ${WORK_PATH}/${JAVA_DEV}${JAVA_VER}_${NEW_VERSION}_${LSB_ARCH}.changes ]; then
    # Remove any existing .deb files if the 'clean' option was selected.
    if [ ${BUILD_CLEAN} -eq 1 ]; then
        ncecho " [x] Removing existing .deb packages and sources "
        rm -rfv ${WORK_PATH}/{deb,src}/* >> "$log" 2>&1 &
        pid=$!;progress $pid
    fi

    # Populate the 'apt' repository with .debs
    ncecho " [x] Moving the packages "
    mv -v ${WORK_PATH}/${JAVA_DEV}${JAVA_VER}_${NEW_VERSION}_${LSB_ARCH}.changes ${WORK_PATH}/deb/ >> "$log" 2>&1
    mv -v ${WORK_PATH}/*${JAVA_DEV}${JAVA_VER}-*_${NEW_VERSION}_*.deb ${WORK_PATH}/deb/ >> "$log" 2>&1 &
    pid=$!;progress $pid
else
    error_msg "ERROR! Packages failed to build."
fi

echo "All done!"
