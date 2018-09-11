# TensorFlow & scikit-learn with Python3.6
FROM python:3.6
LABEL maintainer “t.kaku <jyaou_shingan@yahoo.co.jp>”

ENV NODE_VERSION v10.10.0

# Install dependencies
RUN apt-get update && apt-get install -y \
    libblas-dev \
	liblapack-dev\
    libatlas-base-dev \
    mecab \
    mecab-naist-jdic \
    libmecab-dev \
	gfortran \
    libav-tools \
    python3-setuptools \
    vim \
    htop

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install nodejs
RUN curl -L git.io/nodebrew | perl - setup && \
    echo 'export PATH=$HOME/.nodebrew/current/bin:$PATH' >> ~/.bashrc
ENV PATH $HOME/.nodebrew/current/bin:$PATH
RUN . $HOME/.bashrc && nodebrew install-binary $NODE_VERSION && \
    . $HOME/.bashrc && nodebrew use $NODE_VERSION

# Install python library

RUN pip install --upgrade pip

# Install TensorFlow CPU version
ENV TENSORFLOW_VERSION 1.2.1
RUN pip --no-cache-dir install \
    http://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-${TENSORFLOW_VERSION}-cp36-cp36m-linux_x86_64.whl

# Install Python library for Data Science
RUN pip --no-cache-dir install \
        keras \
        sklearn \
        jupyter \
        ipykernel \
		scipy \
        simpy \
        matplotlib \
        numpy \
        pandas \
        plotly \
        sympy \
        mecab-python3 \
        librosa \
        Pillow \
        h5py \
        google-api-python-client \
        fbprophet \
        jupyterlab \
        tqdm \
        && \
    python -m ipykernel.kernelspec

# Set up Jupyter Notebook config
ENV CONFIG /root/.jupyter/jupyter_notebook_config.py
ENV CONFIG_IPYTHON /root/.ipython/profile_default/ipython_config.py

RUN jupyter notebook --generate-config --allow-root && \
    ipython profile create
# for tqdm
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
    . $HOME/.bashrc && jupyter labextension install ipyvolume && \
    . $HOME/.bashrc && jupyter labextension install @jupyter-widgets/jupyterlab-manager@0.37.3


RUN echo "c.NotebookApp.ip = '*'" >>${CONFIG} && \
    echo "c.NotebookApp.open_browser = False" >>${CONFIG} && \
    echo "c.NotebookApp.iopub_data_rate_limit=10000000000" >>${CONFIG} && \
    echo "c.MultiKernelManager.default_kernel_name = 'python3'" >>${CONFIG} && \
    echo "c.NotebookApp.token = ''" >>${CONFIG}

RUN echo "c.InteractiveShellApp.exec_lines = ['%matplotlib inline']" >>${CONFIG_IPYTHON}

# Copy sample notebooks.
# COPY workdir /workdir

# port
EXPOSE 8888 6006

VOLUME /workdir

# Run Jupyter Notebook
WORKDIR "/workdir"
CMD ["jupyter","lab", "--allow-root"]
