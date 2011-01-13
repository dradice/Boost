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
    echo "BOOST selected, but BOOST_DIR not set.  Checking some places..."
    echo "END MESSAGE"
    
    FILES="include/boost/array.hpp"
    DIRS="/usr /usr/local /usr/local/boost /usr/local/packages/boost /usr/local/apps/boost ${HOME} c:/packages/boost"
    for file in $FILES; do
        for dir in $DIRS; do
            if test -r "$dir/$file"; then
                BOOST_DIR="$dir"
                break
            fi
        done
    done
    
    if [ -z "$BOOST_DIR" ]; then
        echo "BEGIN MESSAGE"
        echo "BOOST not found"
        echo "END MESSAGE"
    else
        echo "BEGIN MESSAGE"
        echo "Found BOOST in ${BOOST_DIR}"
        echo "END MESSAGE"
    fi
fi



################################################################################
# Build
################################################################################

if [ -z "${BOOST_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "Building BOOST..."
    echo "END MESSAGE"
    
    # Set locations
    NAME=boost_1_45_0
    SRCDIR=$(dirname $0)
    INSTALL_DIR=${SCRATCH_BUILD}
    BOOST_DIR=${INSTALL_DIR}/${NAME}
    
    # Clean up environment
    unset LIBS
    unset MAKEFLAGS
    
(
    exec >&2                    # Redirect stdout to stderr
    set -x                      # Output commands
    set -e                      # Abort on errors
    cd ${INSTALL_DIR}
    if [ -e done-${NAME} -a done-${NAME} -nt ${SRCDIR}/dist/${NAME}.tar.gz \
                         -a done-${NAME} -nt ${SRCDIR}/BOOST.sh ]
    then
        echo "BOOST: The enclosed BOOST library has already been built; doing nothing"
    else
        echo "BOOST: Building enclosed BOOST library"
        
        echo "BOOST: Unpacking archive..."
        rm -rf build-${NAME}
        mkdir build-${NAME}
        pushd build-${NAME}
        # Should we use gtar or tar?
        TAR=$(gtar --help > /dev/null 2> /dev/null && echo gtar || echo tar)
        ${TAR} xzf ${SRCDIR}/dist/${NAME}.tar.gz
        popd
        
        echo "BOOST: Configuring..."
        rm -rf ${NAME}
        mkdir ${NAME}
        pushd build-${NAME}/${NAME}
        ./bootstrap.sh --prefix=${BOOST_DIR}
        
        echo "BOOST: Building..."
        ./bjam
        
        echo "BOOST: Installing..."
        ./bjam install
        popd
        
        echo 'done' > done-${NAME}
        echo "BOOST: Done."
    fi
)
    
    if (( $? )); then
        echo 'BEGIN ERROR'
        echo 'Error while building BOOST.  Aborting.'
        echo 'END ERROR'
        exit 1
    fi
    
fi



################################################################################
# Check for additional libraries
################################################################################

# Set options
BOOST_INC_DIRS="${BOOST_DIR}/include"
BOOST_LIB_DIRS="${BOOST_DIR}/lib"
BOOST_LIBS='boost'



# Check whether we are running on Windows
if perl -we 'exit (`uname` =~ /^CYGWIN/)'; then
    is_windows=0
else
    is_windows=1
fi

# Check whether we are running on MacOS
if perl -we 'exit (`uname` =~ /^Darwin/)'; then
    is_macos=0
else
    is_macos=1
fi

################################################################################
# Configure Cactus
################################################################################

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
