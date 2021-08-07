#!/bin/bash
VIRTUALENV=$1
CVS_NAME=$1

if [[ -z "$1" ]]; then
    echo "/!\\/!\\ You must specify the name of the virtualenv to create /!\\/!\\"
    echo "Exemple : hg_odoo_install bengkelvirtualenv"
    exit 0
fi

DEFAULT_PYTHON=python2.7
PYTHON=""
CVS_LOCAL_NAME=""
CREATE_ODOO_CONF=""
CREATE_XMLRPC_FILE=""
CREATE_TEST_FILE=""

WORK_PATH=/home/majac
USER_NAME="Maxime JACQUET"
USER_EMAIL="maxime.jacquet@smile.fr"


echo "##### Creation of a new Odoo project #####"
echo
echo "/!\\ Please fill in the following information /!\\"
echo
echo "?? WORK_PATH (used for creating the virtualenv) ??"
read -e -p " : " -i "$WORK_PATH" WORK_PATH
echo
echo "?? USER_NAME (used for git config) ??"
read -e -p " : " -i "$USER_NAME" USER_NAME
echo
echo "?? USER_EMAIL (used for git config) ??"
read -e -p " : " -i "$USER_EMAIL" USER_EMAIL
echo

echo
read -p "To continue ? (Yes : [OoyY]) " -n 1 -r
echo

mkdir -p $WORK_PATH
cd $WORK_PATH

if [[ $REPLY =~ ^[OoyY]$ ]]; then
    echo "---------------------------------------------------------"
    echo

    if [ ! -d "virtualenv" ]; then
        # Control will enter here if $DIRECTORY exists.
        echo "... virtualenv folder not found in $WORK_PATH."
        mkdir virtualenv
        echo "... virtualenv folder created in $WORK_PATH."
    fi

    cd $WORK_PATH/virtualenv

    read -p "?? Do you want to create this virtualenv with a specific python version --python=/usr/bin/pythonX ? (Yes : [OoyY]) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoyY]$ ]]; then
        echo "    ?? Which version of Python do you want to use ??"
        echo "    /!\\ make sure you have it installed on your workstation before /!\\"
        read -e -p "     : " -i "$DEFAULT_PYTHON" PYTHON

    fi

    read -p "?? Do you want to create this virtualenv with the option --system-site-packages option ? (Yes : [OoyY]) " -n 1 -r
    echo

    if [[ $REPLY =~ ^[OoyY]$ ]]; then
        echo
        if [[ -n "${PYTHON}" ]]; then
            virtualenv $VIRTUALENV --python=$PYTHON --system-site-packages
            echo "... virtualenv "$1" was created WITH the packages."
            echo "... virtualenv "$1" was created WITH Python "$PYTHON"."
        else
            virtualenv $VIRTUALENV --system-site-packages
            echo "... virtualenv "$1" was created WITH the packages."
        fi
    else
        if [[ -n "${PYTHON}" ]]; then
            virtualenv $VIRTUALENV --python=$PYTHON
            echo "... virtualenv "$1" was created WITHOUT the packages."
            echo "... virtualenv "$1" was created WITH Python "$PYTHON"."
        else
            virtualenv $VIRTUALENV
            echo "... virtualenv "$1" was created WITHOUT the packages."
        fi
    fi
    echo
    echo

    cd $WORK_PATH/virtualenv/$VIRTUALENV

    read -p "?? Do you want to create the file odoo-server.conf ? (Yes : [OoyY]) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoyY]$ ]]; then
        CREATE_ODOO_CONF=1
    fi
    echo
    echo

    read -p "?? Do you want to create the file xmlrpc_exec.py ? (Yes : [OoyY]) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoyY]$ ]]; then
        CREATE_XMLRPC_FILE=1
    fi
    echo
    echo
    
    read -p "?? Do you want to create the file run_test.py ? (Yes : [OoyY]) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[OoyY]$ ]]; then
        CREATE_TEST_FILE=1
    fi
    echo
    echo
    
    PS3='?? Which VCS do you want to use ? '
    options=("SVN" "Git" "Any")
    select opt in "${options[@]}"
    do
        case $opt in
            "SVN")
                echo "** SVN ** "
                echo
                echo "... create workspace/trunk"
                echo "?? Do you want to checkout the folder trunk (svn co https://dedisvn.smile.fr/$CVS_NAME/trunk) ?"
                read -p "(Yes : [OoyY]) : " -n 1 -r
                echo
                if [[ $REPLY =~ ^[OoyY]$ ]]; then
                    mkdir workspace
                    echo "3..."
                    sleep 1
                    echo "2..."
                    sleep 1
                    echo "1..."
                    sleep 1
                    /bin/bash -c "svn co https://dedisvn.smile.fr/$CVS_NAME/trunk ./workspace/trunk"
                else
                    mkdir -p workspace/trunk
                fi
                echo
                echo "... create workspace/branches"
                mkdir -p workspace/branches
                echo
                echo "... create workspace/tags"
                mkdir -p workspace/tags
                break
                ;;
            "Git")
                echo "** Git ** "
                echo
                echo "?? What is the Git group for this repo ??"
                read -e -p " : " -i "erp" CVS_GROUP
                echo
                echo "?? What is the name of the repo Git ??"
                read -e -p " : " -i "$CVS_NAME" CVS_NAME
                echo
                echo "?? Do you want to clone the repository (git clone git@git.smile.fr:$CVS_GROUP/$CVS_NAME.git) ?"
                read -p "(Yes : [OoyY]) : " -n 1 -r
                echo
                if [[ $REPLY =~ ^[OoyY]$ ]]; then
                    mkdir workspace
                    cd workspace
                    echo "3..."
                    sleep 1
                    echo "2..."
                    sleep 1
                    echo "1..."
                    sleep 1
                    /bin/bash -c "git clone git@git.smile.fr:$CVS_GROUP/$CVS_NAME.git"
                    echo "?? Do you want to put the following configuration for this repository : ?"
                    echo "    * git config --local user.email $USER_EMAIL"
                    echo "    * git config --local user.name $USER_NAME"
                    read -p "(Yes : [OoyY]) : " -n 1 -r
                    echo
                    cd $CVS_NAME
                    if [[ $REPLY =~ ^[OoyY]$ ]]; then
                        git config --local user.email "$USER_EMAIL"
                        git config --local user.name "$USER_NAME"
                    fi
                    ls -lh
                    cat << 'EOF' > .git/hooks/pre-commit
#!/bin/sh
###############################################################################
# Based on https://gist.github.com/stuntgoat/8800170
# Git pre-commit hook for finding and warning about Python print
# statements.
#

# Get the current git HEAD
head=`git rev-parse --verify HEAD`

# BSD regex for finding Python print statements
find_print='\+[[:space:]]*print[[:space:](]*'

# Save output to $out var
out=`git diff ${head} | grep -e ${find_print}`

# Count number of prints
count=`echo "${out}" | grep -e '\w' | wc -l`
if [ $count -gt 0 ];
   then
    echo
    echo "###############################################################################"
    echo "$out"
    echo "###############################################################################"
    echo "       " $count "print statement(s) found in commit!"
    echo
    echo ">>> \c"
    exit 1
fi
EOF
                else
                    mkdir workspace
                fi
                break
                ;;
            "Any")
                mkdir workspace
                break
                ;;
            *) echo invalid option;;
        esac
    done

    if [[ -n "${CREATE_ODOO_CONF}" ]]; then
        cat << EOF > $WORK_PATH/virtualenv/$VIRTUALENV/odoo-server.conf
[options]
; EDIT ME
prefix = $WORK_PATH/virtualenv/$VIRTUALENV/workspace/$CVS_NAME
addons_path = %(prefix)s/server/addons,%(prefix)s/server/odoo/addons,

;dbfilter=$VIRTUALENV

;enable_email_sending = False
;enable_email_fetching = False

;server.environment = dev
;server.environment.ribbon_color = rgba(255, 0, 255, .6)

;upgrades_path = %(prefix)s/upgrades
;stop_after_upgrades = True
EOF
    fi

    if [[ -n "${CREATE_XMLRPC_FILE}" ]]; then
        cat << 'EOF' > $WORK_PATH/virtualenv/$VIRTUALENV/xmlrpc_exec.py
import xmlrpclib
import getpass
sock = xmlrpclib.ServerProxy('http://localhost:8069/xmlrpc/object')
base = 'base'
uid = 1
pwd = getpass.getpass()
sock_exec = lambda *a: sock.execute(base, uid, pwd, *a)
sock_exec_wkf = lambda *a: sock.exec_workflow(base, uid, pwd, *a)
EOF
    fi

    if [[ -n "${CREATE_TEST_FILE}" ]]; then
        cat << 'EOF' > $WORK_PATH/virtualenv/$VIRTUALENV/run_test.py
# -*- coding: utf-8 -*-
import xmlrpclib
import getpass
sock = xmlrpclib.ServerProxy('http://localhost:8069/xmlrpc/common')
base = 'base'
uid = 1
pwd = getpass.getpass()
# Enter the name of the module for which to run the test
# The smile_tests module must be installed on Odoo
# And your module must include unit tests
sock.run_tests(pwd, base, ['MODULE_NAME'])
EOF
    fi

    echo
    echo "Virtualenv created on $WORK_PATH/virtualenv/$VIRTUALENV"
    echo
    echo "-------------------------------------"
    ls -lh $MOVETO
    
    exit 0
fi
