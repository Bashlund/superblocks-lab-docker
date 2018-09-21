USAGE()
{
    SPACE_DEP="PRINT"

    cat <<_EOF
Usage:
    Init:
    space /run/
    space /install/
    space /yarn/

    Make:
    space /make/
_EOF
}

RUN()
{
    SPACE_DEP="PRINT _ISRUNNING DOCKER_RUN"
    SPACE_ENV="USER2 IMAGE CONTAINER PORT"

    # TODO use args instead of globals

    if ! _ISRUNNING; then
        local flags="--restart=always -d -v ${PWD}:/home/${USER2}/${CONTAINER} -p ${PORT}:${PORT}"
        DOCKER_RUN "${IMAGE}" "${CONTAINER}" "${flags}" "tail" "-f" "/dev/null"
    else
        PRINT "${CONTAINER} is already running."
    fi
}

RESTART()
{
    # TODO:
    SPACE_DEP="PRINT DOCKER_STOP RUN"
    SPACE_ENV="USER2 IMAGE CONTAINER PORT"

    if _ISRUNNING; then
        DOCKER_STOP "${CONTAINER}"
        docker start "${CONTAINER}"
    else
        RUN
    fi
}

KILL()
{
    SPACE_DEP="PRINT _ISRUNNING DOCKER_RM_BY_ID"
    SPACE_ENV="USER2 CONTAINER"

    if _ISRUNNING; then
        DOCKER_RM_BY_ID "${CONTAINER}"
    fi
}

_ISRUNNING()
{
    SPACE_ENV="CONTAINER"

    docker ps -a --format '{{.Names}}' | grep "^${CONTAINER}\$" >/dev/null
}

INSTALL()
{
    SPACE_ENV="USER2 CONTAINER"
    SPACE_DEP="PRINT"

    local home="/home/${USER2}"

    local ID=$(stat -c "%u" "${home}/${CONTAINER}")
    if id "${ID}" >/dev/null 2>&1; then
        PRINT "User with id ${ID} already exists."
    else
        PRINT "Create group with id ${ID}."
        groupadd -g "${ID}" "${USER2}"
        PRINT "Create user with id ${ID}."
        useradd -d "${home}" -g "${ID}" -u "${ID}" "${USER2}"
        chown "${ID}:${ID}" "${home}"
    fi

    # Install software
    pacman -Sy --noconfirm git nodejs npm yarn util-linux make python2 gcc
}

YARN()
{
    SPACE_ENV="USER2 CONTAINER"
    SPACE_DEP="PRINT"
    local home="/home/${USER2}/${CONTAINER}"

    cd "${home}"
    yarn install
}

MAKE()
{
    SPACE_SIGNATURE="[args]"
    SPACE_ENV="USER2 CONTAINER"
    SPACE_DEP="PRINT"
    local home="/home/${USER2}/${CONTAINER}"

    cd "${home}"
    make "$@"
}
