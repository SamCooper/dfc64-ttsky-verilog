# Source this file to set up the DFC64 toolchain: `source env.sh`
DFC64_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOME/tools/oss-cad-suite/environment"
# Python is OSS CAD Suite's bundled interpreter (cocotb must embed the same one in the simulators).
# Its user-site-packages is disabled, so extra deps (test/requirements.txt) install into a
# project-local target dir instead: `pip3 install --target .pydeps -r test/requirements.txt`
export PYTHONPATH="$DFC64_ROOT/.pydeps${PYTHONPATH:+:$PYTHONPATH}"
export PATH="$HOME/tools/bin:$PATH"
