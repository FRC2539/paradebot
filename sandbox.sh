if [[ -z "`which pip3 2> /dev/null`" ]]; then
    echo "pip3 must be installed"
    echo "Aborting..."
    return
fi

# Set up a virtualenv if it doesn't already exist
if [[ ! -d $PWD/.venv ]]; then
    curl --silent --retry 3 --retry-delay 1 --head http://google.com > /dev/null
    if [[ "$?" -ne 0 ]]; then
        echo "No internet connection available"
        echo "Aborting..."
        return
    fi
    if [[ -z "`which virtualenv 2> /dev/null`" ]]; then
        while true; do
            read -p "You do not have virtualenv installed. Should I install it using pip? [Y/N]" yn
            case $yn in
                [Yy]* )
                    if [[ -z "`which sudo 2> /dev/null`" ]]; then
                        pip3 install virtualenv;
                    else
                        sudo pip3 install virtualenv;
                    fi
                    if [[ -z "`which virtualenv 2> /dev/null`" ]]; then
                        echo 'Failed to install virtualenv'
                        return
                    fi
                    break;;
                [Nn]* ) echo "Please install virtualenv"; return;;
                * ) echo "Answer yes or no";;
            esac
        done
    fi

    virtualenv -p python3 --no-site-packages $PWD/.venv
    $PWD/.venv/bin/pip install -U pip
    $PWD/.venv/bin/pip install -r $PWD/requirements.txt

    if [[ ! -d $PWD/tests ]]; then
        $PWD/.venv/bin/python $PWD/robot.py add-tests 2> /dev/null
    fi

    ln -sf $PWD/hooks/* $PWD/.git/hooks/
fi

export PATH=$PWD/.venv/bin:$PATH

# Upgrade any out-of-date pip packages
# HACK: It would be better to include the logic for updating pip packages right
# here, but direnv waits for all subshells and functions to finish before it
# initializes the environment, which causes a noticeable hang when cd-ing into
# the repository. Running a script in the background does not cause a delay.
(bash $PWD/hooks/post-merge envrc &)
