#!/bin/bash

: ${OPT_BOOTSTRAP:=1}
: ${OPT_SYSTEM_PACKAGES:=0}
: ${OPT_WORKDIR:=$HOME/.ansible-tripleo-ci}

setup() {

    virtualenv $( [ "$OPT_SYSTEM_PACKAGES" = 1 ] && printf -- "--system-site-packages\n" ) $OPT_WORKDIR
    . $OPT_WORKDIR/bin/activate

    pip install -r requirements.txt
    python setup.py install

}

activate_venv() {
    . $OPT_WORKDIR/bin/activate
}

usage() {
    echo "$0: usage: $0 [options] virthost [release]"
}

if [ "$#" -lt 1 ]; then
    echo "ERROR: You must specify a target machine." >&2
    usage >&2
    exit 2
fi

VIRTHOST=$1
RELEASE=$2

if [ -n "$RELEASE" ] && [ -n "$OPT_UNDERCLOUD_URL" ]; then
    echo "WARNING: ignoring release $RELEASE because you have" >&2
    echo "         provided an explicit undercloud image URL." >&2

    RELEASE=
elif [ -z "$RELEASE" ] && [ -z "$OPT_UNDERCLOUD_URL" ]; then
    RELEASE=mitaka
fi

# we use this only if --undercloud-image-url was not provided on the
# command line.
: ${OPT_UNDERCLOUD_URL:=https://ci.centos.org/artifacts/rdo/images/${RELEASE}/delorean/stable/undercloud.qcow2}

echo "Setup ansible-tripleo-ci virtualenv and install dependencies"
setup
echo "Activate virtualenv"
activate_venv

export ANSIBLE_CONFIG=$PWD/ansible.cfg
export ANSIBLE_INVENTORY=$OPT_WORKDIR/hosts

ansible-playbook -vvvv playbooks/tripleo.yml \
    -e ansible_python_interpreter=/usr/bin/python \
    -e image_url=$OPT_UNDERCLOUD_URL \
    -e local_working_dir=$OPT_WORKDIR \
    -e virthost=$VIRTHOST \
