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
    git \
    wget \
    htop

RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install nodejs
RUN curl -L git.io/nodebrew | perl - setup && \
    echo 'export PATH=$HOME/.nodebrew/current/bin:$PATH' >> ~/.bashrc
ENV PATH $HOME/.nodebrew/current/bin:$PATH
RUN . $HOME/.bashrc && nodebrew install-binary $NODE_VERSION && \
    . $HOME/.bashrc && nodebrew use $NODE_VERSION

#install fasttext
WORKDIR /opt/modules
RUN git clone https://github.com/facebookresearch/fastText.git fasttext
WORKDIR /opt/modules/fasttext
RUN pip3.6 install .

#mecab
WORKDIR /opt/modules

RUN git clone --depth 1 https://github.com/neologd/mecab-ipadic-neologd.git mecab-ipadic-neologd
WORKDIR /opt/modules/mecab-ipadic-neologd
RUN ./bin/install-mecab-ipadic-neologd -y -n -p "$(dirname $(mecab -D | awk 'NR==1 {print $2}'))"


# Install python library

RUN pip3.6 install --upgrade pip

# Install TensorFlow CPU version
# ENV TENSORFLOW_VERSION 1.2.1
# RUN pip3.6 --no-cache-dir install \
#     http://storage.googleapis.com/tensorflow/linux/cpu/tensorflow-${TENSORFLOW_VERSION}-cp36-cp36m-linux_x86_64.whl

# Install Python library for Data Science
WORKDIR /opt/modules/build
COPY requirements.txt /opt/modules/build/requirements.txt
RUN pip3.6 install -r requirements.txt
# Install fbprophet after pystan install
RUN pip3.6 install fbprophet==0.3.post2
RUN python3.6 -m ipykernel.kernelspec

# Set up Jupyter Notebook config
ENV CONFIG /root/.jupyter/jupyter_notebook_config.py
ENV CONFIG_IPYTHON /root/.ipython/profile_default/ipython_config.py

RUN jupyter notebook --generate-config --allow-root && \
    ipython profile create
RUN jupyter contrib nbextension install --user

# for tqdm
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension && \
    . $HOME/.bashrc && jupyter labextension install ipyvolume && \
    . $HOME/.bashrc && jupyter labextension install @jupyter-widgets/jupyterlab-manager@0.37.3


RUN echo "c.NotebookApp.ip = '0.0.0.0'" >>${CONFIG} && \
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
VOLUME /logs

#please write command when docker up
ENV UP_SCRIPT /root/up_script.sh

RUN touch ${UP_SCRIPT} && \
    chmod 777 ${UP_SCRIPT} && \
    echo "jupyter lab --allow-root &" >>${UP_SCRIPT} && \
    echo "tensorboard --logdir=logs --port 6006 &">>${UP_SCRIPT} && \
    echo "tail -f /dev/null">>${UP_SCRIPT}

# Run Jupyter Notebook
WORKDIR "/workdir"
# CMD ["jupyter","lab", "--allow-root"]
CMD ${UP_SCRIPT}