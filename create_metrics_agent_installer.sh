#!/bin/bash -e
source commons

# takes the first argument as the version. Defaults to the latest version
# of monasca-agent if no argument is specified.
MONASCA_AGENT_VERSION=${1:-`pip search monasca-agent | grep monasca-agent | \
                            awk '{print $2}' | sed 's|(||' | sed 's|)||'`}
UPPER_CONSTRAINT_FILE=${2:-""}

MONASCA_AGENT_TMP_DIR="${TMP_DIR}/monasca-agent"
PIP_DEPENDENCIES=("pymysql")

mkdir -p ${MONASCA_AGENT_TMP_DIR}

virtualenv ${MONASCA_AGENT_TMP_DIR}

if [ -z "${UPPER_CONSTRAINT_FILE}" ]; then
    for dependencies in ${PIP_DEPENDENCIES[@]}; do
        ${MONASCA_AGENT_TMP_DIR}/bin/pip install $dependencies
    done
    ${MONASCA_AGENT_TMP_DIR}/bin/pip install monasca-agent==$MONASCA_AGENT_VERSION
else
    for dependencies in ${PIP_DEPENDENCIES[@]}; do
        ${MONASCA_AGENT_TMP_DIR}/bin/pip install -c ${UPPER_CONSTRAINT_FILE} $dependencies
    done
    ${MONASCA_AGENT_TMP_DIR}/bin/pip install -c ${UPPER_CONSTRAINT_FILE} monasca-agent==$MONASCA_AGENT_VERSION
fi
virtualenv --relocatable ${MONASCA_AGENT_TMP_DIR}

cp configure_metrics_agent.sh ${MONASCA_AGENT_TMP_DIR}/bin

if [ -d "${MAKESELF_DIR}" ]; then
    cd ${MAKESELF_DIR}
    git pull
    cd -
else
    git clone ${MAKESELF_REPO} ${MAKESELF_DIR}
fi

cat metrics_agent_help_header > metrics_agent_help_header.tmp
${MONASCA_AGENT_TMP_DIR}/bin/python ${MONASCA_AGENT_TMP_DIR}/bin/monasca-setup --help \
    >> metrics_agent_help_header.tmp

${MAKESELF_DIR}/makeself.sh --notemp \
                            --help-header metrics_agent_help_header.tmp \
                            ${MONASCA_AGENT_TMP_DIR} \
                            monasca-agent-${MONASCA_AGENT_VERSION}.run \
                            "Monasca Agents installer" \
                            ./bin/configure_metrics_agent.sh

rm -rf ${MONASCA_AGENT_TMP_DIR}
