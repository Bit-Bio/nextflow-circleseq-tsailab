FROM ubuntu
LABEL authors="Jon Ambler" \
      description="Docker image containing all software requirements for the bit-bio/<your-pipline> pipeline"

# NOTE: The conde env name (nextflow-image-template) needs to match that of the conda installation directory added to
# PATH. This only effects you if you change the name in either the Dockerfile or the environment.yml file.
RUN apt-get update

RUN apt-get install -y build-essential
RUN apt-get install -y wget curl unzip

RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*


# Install miniconda
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
     /bin/bash ~/miniconda.sh -b -p /opt/conda

# Put conda in path so we can use conda activate
ENV PATH=$CONDA_DIR/bin:$PATH

# Install the conda environment
COPY containers/environment.yml /
RUN conda env create --quiet -f /environment.yml && conda clean -a

# Add conda installation dir to PATH (instead of doing 'conda activate')
ENV PATH /opt/conda/envs/nextflow-circleseq-tsailabsj/bin:$PATH

# Dump the details of the installed packages to a file for posterity
RUN conda env export --name nextflow-circleseq-tsailabsj > nextflow-circleseq-tsailabsj-details.yml

# Install dependency for aws cli
#RUN conda install -c anaconda groff

#RUN conda install -c conda-forge awscli

# Symlink to /usr/bin/aws - This fails at times, more testing needed.
RUN ln -sf /opt/conda/bin/aws /usr/bin/aws
RUN ln -sf /opt/conda/bin/aws /usr/local/bin/aws

RUN apt-get update && apt-get install -y git

COPY containers/requirements.txt /
RUN python -m pip install -r requirements.txt

RUN mkdir /test
RUN cd /test && git clone https://github.com/tsailabSJ/circleseq
WORKDIR /test


