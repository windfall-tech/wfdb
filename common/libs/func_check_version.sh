check_version() {
: <<inline_doc
      Tests for a minimum version level. Compares to version numbers and forces an
        exit if minimum level not met.
      NOTE: This test will fail on versions containing alpha chars. ie. jpeg 6b

    usage:	check_version "2.6.2" "`uname -r`"         "KERNEL"
		check_version "3.0"   "$BASH_VERSION"      "BASH"
		check_version "3.0"   "`gcc -dumpversion`" "GCC"

    input vars: $1=min acceptable version
    		$2=version to check
		$3=app name
    externals:  --
    modifies:   --
    returns:    nothing
    on error:	write text to console and dies
    on success: write text to console and returns
inline_doc

  declare -i major minor revision change
  declare -i ref_major ref_minor ref_revision ref_change
  declare -r spaceSTR="                       "
  declare -r spaceSTR1="                 "

  shopt -s extglob	#needed for ${x##*(0)} below

  ref_version=$1
  tst_version=$2
  TXT=$3

  # This saves us the save/restore hassle of the system IFS value
  local IFS

  write_error_and_die() {
     echo -e "\n\t\t$TXT is missing or version -->${tst_version}<-- is too old.
		    This script requires ${ref_version} or greater\n"
   # Ask the user instead of bomb, to make happy that packages which version
   # ouput don't follow our expectations
    echo "If you are sure that you have installed a proper version of ${BOLD}$TXT${OFF}"
    echo "but jhalfs has failed to detect it, press 'c' and 'ENTER' keys to continue,"
    echo -n "otherwise press 'ENTER' key to stop jhalfs.  "
    read ANSWER
    if [ x$ANSWER != "xc" ] ; then
      echo "${nl_}Please, install a proper $TXT version.${nl_}"
      exit 1
    else
      minor=$ref_minor
      revision=$ref_revision
    fi
  }

  echo -ne "${TXT}${spaceSTR:${#TXT}} ${L_arrow}${BOLD}${tst_version}${OFF}${R_arrow}"

  # Split up w.x.y.z as well as w.x.y-rc  (catch release candidates).
  # Also strip trailing "+" which appears for kernel built from a Git
  # repository where HEAD is not a tag.
  IFS=".-(pab+"
  set -- $ref_version # set positional parameters to minimum ver values
  ref_major=$1; ref_minor=$2; ref_revision=$3
  #
  set -- $tst_version # Set positional parameters to test version values
  # Values beginning with zero are taken as octal, so that for example
  # 2.07.08 gives an error because 08 cannot be octal. The ## stuff supresses
  # leading zero's
  major=${1##*(0)}; minor=${2##*(0)}; revision=${3##*(0)}
  #
  # Compare against minimum acceptable version..
  (( major > ref_major )) &&
    echo " ${spaceSTR1:${#tst_version}}${GREEN}OK${OFF} (Min version: ${ref_version})" &&
    return
  (( major < ref_major )) && write_error_and_die
    # major=ref_major
  (( minor < ref_minor )) && write_error_and_die
  (( minor > ref_minor )) &&
    echo " ${spaceSTR1:${#tst_version}}${GREEN}OK${OFF} (Min version: ${ref_version})" &&
    return
    # minor=ref_minor
  (( revision >= ref_revision )) &&
    echo " ${spaceSTR1:${#tst_version}}${GREEN}OK${OFF} (Min version: ${ref_version})" &&
    return

  # oops.. write error msg and die
  write_error_and_die
}

#----------------------------#
check_prerequisites() {      #
#----------------------------#

  # Use TOML-based host requirements checker (replaces XML/XSL)
  python3 $JHALFSDIR/tools/check_host_requirements.py
  if [ $? -ne 0 ]; then
    echo "Host requirements check failed. Please install required tools."
    exit 1
  fi
  
  # Avoid translation of version strings
  local LC_ALL=C
  export LC_ALL

  # LFS prerequisites
  if [ -n "$MIN_Linux_VER" ]; then
    check_version "$MIN_Linux_VER"     "`uname -r`"          "KERNEL"
  fi
  if [ -n "$MIN_Bash_VER" ]; then
    check_version "$MIN_Bash_VER"      "$BASH_VERSION"       "BASH"
  fi
  if [ ! -z $MIN_GCC_VER ]; then
    check_version "$MIN_GCC_VER"     "`gcc -dumpfullversion -dumpversion`"  "GCC"
    check_version "$MIN_GCC_VER"     "`g++ -dumpfullversion -dumpversion`"  "G++"
  elif [ ! -z $MIN_Gcc_VER ]; then
    check_version "$MIN_Gcc_VER"     "`gcc -dumpfullversion -dumpversion`"  "GCC"
  fi
  if [ -n "$MIN_Glibc_VER" ]; then
    check_version "$MIN_Glibc_VER"     "$(ldd --version  | head -n1 | awk '{print $NF}')"   "GLIBC"
  fi
  if [ -n "$MIN_Binutils_VER" ]; then
    check_version "$MIN_Binutils_VER"  "$(ld --version  | head -n1 | awk '{print $NF}')"    "BINUTILS"
  fi
  if [ -n "$MIN_Tar_VER" ]; then
    check_version "$MIN_Tar_VER"       "$(tar --version | head -n1 | cut -d" " -f4)"        "TAR"
  fi
  if [ -n "$MIN_Bzip2_VER" ]; then
  bzip2Ver="$(bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f8)"
    check_version "$MIN_Bzip2_VER"     "${bzip2Ver%%,*}"     "BZIP2"
  fi
  if [ -n "$MIN_Bison_VER" ]; then
    check_version "$MIN_Bison_VER"     "$(bison --version | head -n1 | cut -d" " -f4)"      "BISON"
  fi
  if [ -n "$MIN_Coreutils_VER" ]; then
    check_version "$MIN_Coreutils_VER" "$(chown --version | head -n1 | cut -d" " -f4)"      "COREUTILS"
  fi
  if [ -n "$MIN_Diffutils_VER" ]; then
    check_version "$MIN_Diffutils_VER" "$(diff --version  | head -n1 | cut -d" " -f4)"      "DIFF"
  fi
  if [ -n "$MIN_Findutils_VER" ]; then
    check_version "$MIN_Findutils_VER" "$(find --version  | head -n1 | cut -d" " -f4)"      "FIND"
  fi
  if [ -n "$MIN_Gawk_VER" ]; then
    check_version "$MIN_Gawk_VER"      "$(gawk --version  | head -n1 | awk -F'[ ,]+' '{print $3}')" "GAWK"
  fi
  if [ -n "$MIN_Grep_VER" ]; then
    check_version "$MIN_Grep_VER"      "$(grep --version  | head -n1 | awk '{print $NF}')"  "GREP"
  fi
  if [ -n "$MIN_Gzip_VER" ]; then
    check_version "$MIN_Gzip_VER"      "$(gzip --version 2>&1 | head -n1 | cut -d" " -f2)"  "GZIP"
  fi
  if [ -n "$MIN_M4_VER" ]; then
    check_version "$MIN_M4_VER"        "$(m4 --version 2>&1 | head -n1 | awk '{print $NF}')" "M4"
  fi
  if [ -n "$MIN_Make_VER" ]; then
    check_version "$MIN_Make_VER"      "$(make --version  | head -n1 | cut -d " " -f3 | cut -c1-4)" "MAKE"
  fi
  if [ -n "$MIN_Patch_VER" ]; then
    check_version "$MIN_Patch_VER"     "$(patch --version | head -n1 | sed 's/.*patch //')" "PATCH"
  fi
  if [ -n "$MIN_Perl_VER" ]; then
    check_version "$MIN_Perl_VER"      "$(perl -V:version | cut -f2 -d\')"                  "PERL"
  fi
  if [ -n "$MIN_Sed_VER" ]; then
    check_version "$MIN_Sed_VER"       "$(sed --version   | head -n1 | cut -d" " -f4)"      "SED"
  fi
  if [ -n "$MIN_Texinfo_VER" ]; then
    check_version "$MIN_Texinfo_VER"   "$(makeinfo --version | head -n1 | awk '{ print$NF }')" "TEXINFO"
  fi
  if [ -n "$MIN_Xz_VER" ]; then
    check_version "$MIN_Xz_VER"        "$(xz --version | head -n1 | cut -d" " -f4)"         "XZ"
  fi
  if [ -n "$MIN_Python_VER" ]; then
    check_version "$MIN_Python_VER"    "3.$(python3 -c"import sys; print(sys.version_info.minor,'.',sys.version_info.micro,sep='')")" "PYTHON"
  fi
}

#----------------------------#
check_alfs_tools() {         #
#----------------------------#
: << inline_doc
Those tools are needed for the proper operation of jhalfs
inline_doc

  # Avoid translation of version strings
  local LC_ALL=C
  export LC_ALL

  # Check for minimum sudo version
  SUDO_LOC="$(whereis -b sudo | cut -d" " -f2)"
  if [ -x $SUDO_LOC ]; then
    sudoVer="$(sudo -V | head -n1 | cut -d" " -f3)"
    check_version "1.7.0"  "${sudoVer}"      "SUDO"
  else
    echo "${nl_}\"${RED}sudo${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    exit 1
  fi

  # Check for wget  or curl presence (using dummy versions)
  # Do this only if we need to download packages
  # Return the result in a global variable
  if [ "$GETPKG" = y ]; then
  declare -g DOWNLOADER
  # First try wget
    WGET_LOC="$(whereis -b wget | cut -d" " -f2)"
    if [ -x $WGET_LOC ]; then
      wgetVer="$(wget --version | head -n1 | cut -d" " -f3)"
    fi
    if echo "$wgetVer" | grep -q '^[[:digit:]]'; then
      check_version "1.0.0"  "${wgetVer}"      "WGET"
      DOWNLOADER=wget
    else
    # Stop here if requesting blfs tools.
      if [ "$BLFS_TOOL" = y ]; then
        echo "${nl_}\"${RED}wget${OFF}\" ${BOLD}must be"
        echo "installed on your system for using blfs tools"
        exit 1
      fi
    # Then try curl
      CURL_LOC="$(whereis -b curl | cut -d" " -f2)"
      if [ -x $CURL_LOC ]; then
        curlVer="$(curl --version | head -n1 | cut -d" " -f2)"
      fi
      if echo "$curlVer" | grep -q '^[[:digit:]]'; then
        check_version "1.0.0"  "${curlVer}"      "CURL"
        DOWNLOADER=curl
      else
        echo "${nl_}Either \"${RED}wget${OFF}\" or \"${RED}curl${OFF}\" ${BOLD}must be"
        echo "installed on your system for retrieving source files"
        exit 1
      fi
    fi
  fi

  # Check for Python3 since we now use TOML-based build system
  PYTHON3_LOC="$(whereis -b python3 | cut -d" " -f2)"
  
  if [ ! -x $PYTHON3_LOC ]; then
    echo "${nl_}\"${RED}python3${OFF}\" ${BOLD}must be installed on your system for jhalfs to run"
    echo "${BOLD}The TOML-based build system requires Python 3.6 or later"
    exit 1
  fi
  
  # Check Python version
  python3VerFull=$(python3 --version 2>&1)
  python3Ver=$(echo $python3VerFull | cut -d " " -f2)
  check_version "3.6.0" "$python3Ver" "PYTHON3"

  # Now that we do profiling, we need the docbook DTD, and the docbook XSL
  # stylesheets.
  # Minimal docbook-xml code for testing
  XML_FILE="<?xml version='1.0' encoding='ISO-8859-1'?>
<?xml-stylesheet type='text/xsl' href='http://docbook.sourceforge.net/release/xsl/current/xhtml/docbook.xsl'?>
<!DOCTYPE article PUBLIC '-//OASIS//DTD DocBook XML V4.5//EN'
  'http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd'>
<article>
  <title>Test file</title>
  <sect1>
    <title>Some title</title>
    <para>Some text</para>
  </sect1>
</article>"

  if echo $XML_FILE | xmllint -nonet -noout -postvalid - 2>/dev/null ; then
    check_version "4.5" "4.5" "DocBook XML DTD"
  else
    echo "Error: you need the Docbook XML DTD for running jhalfs"
    exit 1
  fi

  if echo $XML_FILE | xsltproc -nonet -noout - 2>/dev/null ; then
    check_version "current" "current" "DocBook XSL stylesheets"
  else
    echo "Error: you need the Docbook XSL stylesheets for running jhalfs"
    exit 1
  fi
}
