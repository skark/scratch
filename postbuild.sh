#!/bin/bash

set -o xtrace
# Enable the proxy extension in notebook and lab
jupyter serverextension enable --py jupyter_server_proxy
jupyter labextension install @jupyterlab/server-proxy
jupyter lab build

# Install the VS code proxy
pip install -e.

dotnet tool install -g --add-source "https://dotnet.myget.org/F/dotnet-try/api/v3/index.json" Microsoft.dotnet-interactive
dotnet interactive jupyter install

#code-server --install-extension ms-python.python
#code-server --install-extension ms-dotnettools.csharp

set +o xtrace