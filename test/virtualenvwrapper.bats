#!/usr/bin/env bats

load test_helper

setup() {
  export PYENV_ROOT="${TMP}/pyenv"
  for version in "2.7.6" "3.3.3"; do
    PYENV_VERSION="${version}" create_executable "python" <<EOS
#!/usr/bin/env bash
echo python is invoked
EOS
    PYENV_VERSION="${version}" create_executable "virtualenv" <<EOS
#!/usr/bin/env bash
echo virtualenv is invoked
EOS
    PYENV_VERSION="${version}" create_executable "virtualenv-clone" <<EOS
#!/usr/bin/env bash
echo virtualenv-clone is invoked
EOS

    install -p "${BATS_TEST_DIRNAME}/virtualenvwrapper"/* "${PYENV_ROOT}/versions/${version}/bin/"
  done
}

create_executable() {
  name="${1?}"
  shift 1
  bin="${PYENV_ROOT}/versions/${PYENV_VERSION}/bin"
  mkdir -p "$bin"
  { if [ $# -eq 0 ]; then cat -
    else echo "$@"
    fi
  } | sed -Ee '1s/^ +//' > "${bin}/$name"
  chmod +x "${bin}/$name"
}

gen_script() {
  stub pyenv "version-name : echo \"${PYENV_VERSION}\""
  stub pyenv "prefix ${PYENV_VERSION} : echo \"${PYENV_ROOT}/versions/${PYENV_VERSION}\""

  run pyenv-sh-virtualenvwrapper

  unstub pyenv
  assert_success

  echo "${output%;}"
}

@test "initialize virtualenvwrapper" {
  export PYENV_VERSION="3.3.3"

  script="$(gen_script)"

  stub pyenv "version-name : echo \"${PYENV_VERSION}\""

  run eval "${script}"

  unstub pyenv
  assert_success
  assert_output <<EOS
virtualenvwrapper.sh is loaded
EOS
}

@test "initialize virtualenvwrapper without changing version" {
  export PYENV_VERSION="3.3.3"

  script="$(gen_script)"

  stub pyenv "version-name : echo \"${PYENV_VERSION}\""

  run eval "${script}"

  unstub pyenv
  assert_success
  assert_output <<EOS
virtualenvwrapper.sh is loaded
EOS
}

@test "initialize virtualenvwrapper with changing version" {
  export PYENV_VERSION="3.3.3"

  script="$(gen_script)"

  stub pyenv "version-name : echo \"2.7.6\""
  stub pyenv "prefix 2.7.6 : echo \"${PYENV_ROOT}/versions/2.7.6\""

  run eval "${script}"

  unstub pyenv
  assert_success
  assert_output <<EOS
virtualenvwrapper.sh is loaded
EOS
}

@test "invoke mkvirtualenv" {
  export PYENV_VERSION="3.3.3"

  script="$(gen_script)"

  stub pyenv "version-name : echo \"${PYENV_VERSION}\""
  stub pyenv "version-name : echo \"${PYENV_VERSION}\""
  stub pyenv "version-name : echo \"${PYENV_VERSION}\""

  run eval "${script}; mkvirtualenv venv33"

  unstub pyenv
  assert_success
  assert_output <<EOS
virtualenvwrapper.sh is loaded
virtualenvwrapper_verify_workon_home is invoked
PYTHON=${PYENV_ROOT}/versions/${PYENV_VERSION}/bin/python VIRTUALENV=${PYENV_ROOT}/versions/${PYENV_VERSION}/bin/virtualenv mkvirtualenv venv33
EOS
}

@test "invoke lsvirtualenv" {
  export PYENV_VERSION="3.3.3"

  script="$(gen_script)"

  stub pyenv "version-name : echo \"${PYENV_VERSION}\""
  stub pyenv "version-name : echo \"${PYENV_VERSION}\""

  run eval "${script}; lsvirtualenv"

  unstub pyenv
  assert_success
  assert_output <<EOS
virtualenvwrapper.sh is loaded
virtualenvwrapper_verify_workon_home is invoked
PYTHON=${PYENV_ROOT}/versions/${PYENV_VERSION}/bin/python VIRTUALENV=${PYENV_ROOT}/versions/${PYENV_VERSION}/bin/virtualenv lsvirtualenv
EOS
}
