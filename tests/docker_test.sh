#!/bin/bash

# Process options
SERVER=$1
shift;

SHOW_HELP="0"
CLEAN="0"

case ${SERVER} in
    app|manage)
    ;;
    "")
    echo "ERROR: You must specify the test to run"
    echo
    SHOW_HELP="1"
    ;;
    *)
    echo "ERROR: Unknown test type: '${SERVER}'"
    echo
    SHOW_HELP="1"
    ;;
esac

OPTION=$1
case $OPTION in
    "") # Do nothing
    ;;
    -h|--help)
    SHOW_HELP="1"
    ;;
    -c|--clean)
    CLEAN="1"
    ;;
    *)
    echo "Unkown option: '${OPTION}'"
    echo
    SHOW_HELP="1"
    ;;
esac


if [ $SHOW_HELP == "1" ]; then
    echo "'docker_test.sh' is a script to test the deploy of Stepup in a docker container."
    echo "Requires docker, compatible with docker-machine."
    echo "All tests run in the docker container."
    echo
    echo "Usage: docker_test.sh <test> [--clean]"
    echo "<test> specifies the test to run:"
    echo "'app' : Deploy an app server"
    echo "'manage' : Deploy a manage server"
    echo
    echo "--clean|-c : kill and rm an existing container before running the test"
    echo
    echo "The script builds and starts a docker container and then runs the specified test."
    echo "The script leaves the container running, reusing an existing container."
    echo "To rerun in a clean container add the '--clean' option, this will stop and rm the"
    echo "running container."
    echo
    echo "Use: 'docker exec -i -t ansible-test /bin/bash' to connect to the container."
    exit 0
fi

BASEDIR=`dirname $0`
REPODIR="${BASEDIR}/../"

DOCKER=`which docker`
if [ -z "${DOCKER}" -o ! -x ${DOCKER} ]; then
    echo "'docker' is not in path or not executable. Please install docker."
    exit 1;
fi
echo "Using docker: ${DOCKER}"

echo '===== CHECK for existing container "ansible-test" ====='
if [ `docker ps -a -f name=ansible-test | wc -l` -gt 1 ]; then
    echo 'Container "ansible-test" exists'
    if [ "${CLEAN}" == 1 ]; then
        echo "'--clean' option provided; killing and rm'ing container"
        echo '===== docker kill ansible-test ====='
        docker kill ansible-test

        echo '===== docker rm ansible-test ====='
        docker rm ansible-test
    else
        echo 'Reusing existing container'
        echo 'use the "--clean" option to kill & rebuild container'
        # Clean ansible roles so docker cp will copy files again (including changes)
        docker exec -t ansible-test sh -c 'rm -r /ansible/filter_plugins /ansible/scripts /ansible/roles /ansible/deploy.yml /ansible/site.yml'
        # Ensure container is started
        docker start ansible-test
    fi
fi
# Recheck container, we could have just rm'ed it
if [ `docker ps -a -f name=ansible-test | wc -l` -eq 1 ]; then
  echo 'No container named "ansible-test"'
  echo 'Build / start container'
  echo '===== BUILD surfnet/centos7-openconext ====='
  docker build --rm -t surfnet/centos7-openconext -f tests/Dockerfile.centos-7 .

  echo '===== RUN surfnet/centos7-openconext as ansible-test ====='
  docker run --detach --privileged \
  --hostname ${SERVER}.stepup.example.com \
  --add-host middleware.stepup.example.com:127.0.0.1 \
  --add-host selfservice.stepup.example.com:127.0.0.1 \
  --add-host ra.stepup.example.com:127.0.0.1 \
  --add-host gateway.stepup.example.com:127.0.0.1 \
  --add-host tiqr.stepup.example.com:127.0.0.1 \
  --add-host keyserver.stepup.example.com:127.0.0.1 \
  --add-host manage.stepup.example.com:127.0.0.1 \
  --name ansible-test surfnet/centos7-openconext

  if [ "$?" -ne 0 ]; then echo "docker run failed"; exit 1; fi
fi

# Enable strict error checking
set -e

echo '===== SYNC Stepup-Deploy to /ansible ====='
# Copy files into the container using docker cp instead of mounting
# This method works with both a local docker container and docker-machine
docker exec -t ansible-test sh -c 'mkdir -p /ansible'
docker cp ${REPODIR}/environments ansible-test:/ansible/environments
docker cp ${REPODIR}/filter_plugins ansible-test:/ansible/filter_plugins
docker cp ${REPODIR}/scripts ansible-test:/ansible/scripts
docker cp ${REPODIR}/roles ansible-test:/ansible/roles
docker cp ${REPODIR}/deploy.yml ansible-test:/ansible/
docker cp ${REPODIR}/site.yml ansible-test:/ansible/

echo '===== Create ansible environment for docker ====='
docker exec -t ansible-test sh -c '/ansible/scripts/create_new_environment.sh /ansible/environments/docker'

echo '===== Create /ansible/ansible.cfg ====='
docker exec -t ansible-test sh -c 'echo -e "[defaults]\ncallback_plugins=/ansible/callback_plugins\ncallback_whitelist=profile_tasks\n[ssh_connection]\nssh_args=-o ControlMaster=auto -o ControlPersist=60m\npipelining=True" > /ansible/ansible.cfg'

echo '===== Contents of /ansible/ansible.cfg ====='
docker exec -t ansible-test sh -c 'cat /ansible/ansible.cfg'

#echo '===== Ansible groups ====='
#docker exec -t ansible-test env TERM=xterm ANSIBLE_CONFIG=/ansible/ansible.cfg \
#  ansible localhost -m debug -a 'var=groups' -i /ansible/environments/docker/inventory

echo '===== Ansible syntax check of site.yml ====='
docker exec -t ansible-test env TERM=xterm ANSIBLE_CONFIG=/ansible/ansible.cfg \
  ansible-playbook -i /ansible/environments/docker/inventory /ansible/site.yml \
  --syntax-check

if [ ${SERVER} == "app" ]; then
    echo '===== Ansible deploy of site.yml for app.stepup.example.com ====='
    # Deploy site.yml to app server.
    # - Use "--skip-tags skip_docker_test" to skip Ansible tasks that do not run in a docker environment
    # - Omit "-t" flag to "docker exec" to work around a deadlock that is triggerd by this specific ansible-playbook.
    #   This means no nice coloured terminal output.
    docker exec ansible-test env TERM=xterm ANSIBLE_CONFIG=/ansible/ansible.cfg \
      ansible-playbook -i /ansible/environments/docker/inventory /ansible/site.yml \
      --limit app.stepup.example.com --skip-tags skip_docker_test -e "galera_bootstrap_node=app.stepup.example.com"

    echo '===== Downloading component tarballs ====='
    tarballs=(
        "https://github.com/SURFnet/Stepup-Gateway/releases/download/2.2.0-20161018092553Z-bc6bbf8e2006d15cbe883d8045724cdb1166e759/Stepup-Gateway-2.2.0-20161018092553Z-bc6bbf8e2006d15cbe883d8045724cdb1166e759.tar.bz2"
        "https://github.com/SURFnet/Stepup-Middleware/releases/download/2.3.1-20161202111856Z-842810702ab76ce36b9fef8c00ba56f91f4bd935/Stepup-Middleware-2.3.1-20161202111856Z-842810702ab76ce36b9fef8c00ba56f91f4bd935.tar.bz2"
        "https://github.com/SURFnet/Stepup-SelfService/releases/download/2.3.0-20161118105735Z-eebc000542020fa8518edf016221e9b973874bd2/Stepup-SelfService-2.3.0-20161118105735Z-eebc000542020fa8518edf016221e9b973874bd2.tar.bz2"
        "https://github.com/SURFnet/Stepup-RA/releases/download/2.4.0-20161130155145Z-bafb84b3ee966990f5b2115d56b04988e7f0cc6b/Stepup-RA-2.4.0-20161130155145Z-bafb84b3ee966990f5b2115d56b04988e7f0cc6b.tar.bz2"
        "https://github.com/SURFnet/Stepup-tiqr/releases/download/release-1.1.4-20161027120418Z-6616dd165903ff4e849b26b755612a3da6fb0409/Stepup-tiqr-release-1.1.4-20161027120418Z-6616dd165903ff4e849b26b755612a3da6fb0409.tar.bz2"
        "https://github.com/SURFnet/oath-service-php/releases/download/1.0.1-20150723081351Z-56c990e62b4ba64ac755ca99093c9e8fce3e8fe9/oath-service-php-1.0.1-20150723081351Z-56c990e62b4ba64ac755ca99093c9e8fce3e8fe9.tar.bz2"
        )
    for url in "${tarballs[@]}"; do
        docker exec -t ansible-test sh -c "wget -P /ansible --continue ${url}"
    done

    echo '===== Deploying components ====='
    for url in "${tarballs[@]}"; do
        name=`basename ${url}`
        echo "Deploying ${name}"
        docker exec -t ansible-test env TERM=xterm ANSIBLE_CONFIG=/ansible/ansible.cfg \
          /ansible/scripts/deploy.sh /ansible/${name} -i /ansible/environments/docker/inventory \
          --limit app.stepup.example.com
    done

    echo '===== Running bootstrap scripts ====='
    echo 'Running: 01-gateway-db_migrate.sh'
    docker exec -t ansible-test sh -c 'echo y | /root/01-gateway-db_migrate.sh'
    echo 'Running: 01-middleware-db_migrate.sh'
    docker exec -t ansible-test sh -c 'echo y | /root/01-middleware-db_migrate.sh'
    echo 'Running: 01-keyserver-db_init.sh'
    docker exec -t ansible-test sh -c '/root/01-keyserver-db_init.sh'
    echo 'Running: 01-tiqr-db_init.sh'
    docker exec -t ansible-test sh -c '/root/01-tiqr-db_init.sh'
    echo 'Running: 02-middleware-config.sh'
    docker exec -t ansible-test sh -c '/root/02-middleware-config.sh'
    echo 'Running: 04-middleware-whitelist.sh'
    docker exec -t ansible-test sh -c '/root/04-middleware-whitelist.sh'
    echo 'Running: 05-middleware-institution.sh'
    docker exec -t ansible-test sh -c '/root/05-middleware-institution.sh'
    echo 'Running: 06-middleware-bootstrap-sraa-users.sh'
    docker exec -t ansible-test sh -c '/root/06-middleware-bootstrap-sraa-users.sh --always-yes'
fi

if [ ${SERVER} == "manage" ]; then
    echo '===== Ansible deploy of site.yml for manage.stepup.example.com ====='
    # Deploy site.yml to app server. This excludes
    docker exec -t ansible-test env TERM=xterm ANSIBLE_CONFIG=/ansible/ansible.cfg \
      ansible-playbook -i /ansible/environments/docker/inventory /ansible/site.yml \
      --limit manage.stepup.example.com --skip-tags skip_docker_test -e "galera_bootstrap_node=app.stepup.example.com"

fi
