#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
set -x                          # Output commands
set -e                          # Abort on errors



################################################################################
# Search
################################################################################

if [ -z "${BOOST_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "Boost selected, but BOOST_DIR not set. Checking some places..."
    echo "END MESSAGE"
    
    FILES="include/boost/array.hpp"
    DIRS="/usr /usr/local /usr/local/boost /usr/local/packages/boost /usr/local/apps/boost ${HOME} c:/packages/boost"
    for dir in $DIRS; do
        BOOST_DIR="$dir"
        for file in $FILES; do
            if [ ! -r "$dir/$file" ]; then
                unset BOOST_DIR
                break
            fi
        done
        if [ -n "$BOOST_DIR" ]; then
            break
        fi
    done
    
    if [ -z "$BOOST_DIR" ]; then
        echo "BEGIN MESSAGE"
        echo "Boost not found"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Found Boost in ${BOOST_DIR}"
        echo "END MESSAGE"
    fi
fi



################################################################################
# Build
################################################################################

if [ -z "${BOOST_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "Building Boost..."
    echo "END MESSAGE"
    
    # Set locations
    THORN=Boost
    NAME=boost_1_47_0
    SRCDIR=$(dirname $0)
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    BOOST_DIR=${INSTALL_DIR}
    
(
    exec >&2                    # Redirect stdout to stderr
    set -x                      # Output commands
    set -e                      # Abort on errors
    cd ${SCRATCH_BUILD}
    if [ -e ${DONE_FILE} -a ${DONE_FILE} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a ${DONE_FILE} -nt ${SRCDIR}/configure.sh ]
    then
        echo "Boost: The enclosed Boost library has already been built; doing nothing"
    else
        echo "Boost: Building enclosed Boost library"
        
        # Set up environment
        unset LIBS
        if echo '' ${ARFLAGS} | grep 64 > /dev/null 2>&1; then
            export OBJECT_MODE=64
        fi
        
        echo "Boost: Preparing directory structure..."
        mkdir build external done 2> /dev/null || true
        rm -rf ${BUILD_DIR} ${INSTALL_DIR}
        mkdir ${BUILD_DIR} ${INSTALL_DIR}
        
        echo "Boost: Unpacking archive..."
        pushd ${BUILD_DIR}
        ${TAR} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        
        echo "Boost: Configuring..."
        cd ${NAME}
        ./bootstrap.sh --prefix=${BOOST_DIR}
        
        echo "Boost: Building..."
        ./b2 || true
        
        echo "Boost: Installing..."
        ./b2 install || true
        popd
        
        echo "Boost: Cleaning up..."
        rm -rf ${BUILD_DIR}
        
        date > ${DONE_FILE}
        echo "Boost: Done."
    fi
)
    
    if (( $? )); then
        echo 'BEGIN ERROR'
        echo 'Error while building Boost. Aborting.'
        echo 'END ERROR'
        exit 1
    fi
    
fi



################################################################################
# Configure Cactus
################################################################################

# Set options
BOOST_INC_DIRS="${BOOST_DIR}/include"

if [ -d ${BOOST_DIR}/lib64 ]; then
    BOOST_LIB_DIRS="${BOOST_DIR}/lib64"
else
    BOOST_LIB_DIRS="${BOOST_DIR}/lib"
fi

# BOOST_LIBS='boost'
# BOOST_LIBS="boost_date_time boost_filesystem boost_iostreams boost_prg_exec_monitor boost_program_options boost_python boost_regex boost_serialization boost_signals boost_test_exec_monitor boost_thread boost_unit_test_framework boost_wave boost_wserialization"

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "HAVE_BOOST     = 1"
echo "BOOST_DIR      = ${BOOST_DIR}"
echo "BOOST_INC_DIRS = ${BOOST_INC_DIRS}"
echo "BOOST_LIB_DIRS = ${BOOST_LIB_DIRS}"
echo "BOOST_LIBS     = ${BOOST_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(BOOST_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(BOOST_LIB_DIRS)'
echo 'LIBRARY           $(BOOST_LIBS)'
