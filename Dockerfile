FROM mcr.microsoft.com/dotnet/core/sdk:3.1

ARG NB_USER=jovyan
ARG NB_UID=1000
ENV USER ${NB_USER}
ENV NB_UID ${NB_UID}
ENV HOME /home/${NB_USER}

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid ${NB_UID} \
    ${NB_USER}
    
# Make sure the contents of our repo are in ${HOME}
COPY . ${HOME}
USER root
RUN chown -R ${NB_UID} ${HOME}
USER ${NB_USER}

ENV CONDA_DIR=/condinst \
        DOTNET_CLI_TELEMETRY_OPTOUT=true \
        PATH="$PATH:$CONDA_DIR/bin:${HOME}/.dotnet/tools"
        
USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    git cm-super keychain libsm6 libxext6 libxrender1 dvipng texlive-latex-extra texlive-fonts-recommended \
 && apt-get clean && rm -rf /var/lib/apt/lists/*
 
COPY startup/*.py ${HOME}/.ipython/profile_default/startup/

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8

ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

# Create NB_USER with name jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd

USER $NB_UID
WORKDIR $HOME

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/work

RUN set -o xtrace && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    /bin/bash Miniconda3-latest-Linux-x86_64.sh -f -b -p $CONDA_DIR  && \
    rm Miniconda3-latest-Linux-x86_64.sh  && \
    conda config --system --prepend channels conda-forge && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    conda install --quiet --yes conda && \
    conda install --quiet --yes pip && \
    conda env update -f "environment.yml" && \ 
    conda clean --all -f -y && \
    ${CONDA_DIR}/etc/profile.d/conda.sh && \
    conda activate datascience && \
    dotnet tool install -g --add-source "https://dotnet.myget.org/F/dotnet-try/api/v3/index.json" Microsoft.dotnet-interactive && \
    dotnet interactive jupyter install && \
    jupyter notebook --generate-config && \
    jupyter serverextension enable --py jupyter_server_proxy && \
    jupyter labextension install @jupyterlab/server-proxy && \
    jupyter lab build && \
    pip install -e. && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    set +o xtrace

#    conda update --all --quiet --yes && \
#    conda install --quiet --yes notebook jupyterlab feather-format opencv scipy matplotlib scikit-image spacy pylint -c conda-forge && \
#    conda install -q -y jupyter-server-proxy code-server && \
#    conda install -q -y pytorch torchvision torchtext cpuonly -c pytorch && \
#    pip install --no-cache-dir sklearn-pandas isoweek pandas_summary jupyter-offlinenotebook && \

    
#RUN code-server --install-extension ms-python.python ; exit 0
#RUN code-server --install-extension ms-dotnettools.csharp ; exit 0

EXPOSE 8888

# Configure container startup
ENTRYPOINT []

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID