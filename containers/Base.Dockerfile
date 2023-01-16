FROM nfcore/base:1.14
LABEL authors="Alan Tracey" \
      description="Docker image containing all software requirements for the bit-bio/nextflow-circleseq-tsailabsj pipeline"

FROM continuumio/miniconda3

RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 curl git build-essential && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install the conda environment
#COPY containers/environment.yml /

RUN conda create --name  nextflow-circleseq-tsailabsj_py2-7 python=2.7
#RUN conda env create --quiet -f /environment.yml python=2.7 && conda clean -a
RUN echo "conda activate nextflow-circleseq-tsailabsj_py2-7" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]
#RUN conda init bash
RUN mkdir /test
RUN cd /test && git clone https://github.com/tsailabSJ/circleseq
WORKDIR /test
RUN pip install nose
RUN pip install pyyaml
RUN pip install svgwrite
RUN conda install -c bioconda htseq
RUN pip install pyfaidx
RUN pip install "regex<2022.1.18"
RUN wget https://anaconda.org/conda-forge/statsmodels/0.10.1/download/linux-64/statsmodels-0.10.1-py27hc1659b7_2.tar.bz2
RUN conda install statsmodels-0.10.1-py27hc1659b7_2.tar.bz2
RUN rm -rf statsmodels-0.10.1-py27hc1659b7_2.tar.bz2
ENV PATH /opt/conda/pkgs/statsmodels-0.10.1-py27hc1659b7_2/lib/python2.7/site-packages:$PATH
RUN conda install -c conda-forge pandas
RUN wget https://sourceforge.net/projects/bio-bwa/files/bwakit/bwakit-0.7.11_x64-linux.tar.bz2
RUN tar xjvf bwakit-0.7.11_x64-linux.tar.bz2
RUN rm -rf bwakit-0.7.11_x64-linux.tar.bz2
RUN /bin/ln -s /test/bwa.kit/bwa /opt/conda/envs/nextflow-circleseq-tsailabsj_py2-7/bin/bwa
RUN conda config --add channels bioconda
RUN conda config --add channels conda-forge
RUN conda install -c bioconda samtools
RUN conda install -c bioconda bcftools
RUN conda install -c conda-forge openssl
RUN conda install -c conda-forge libopenblas

RUN conda create --name  nextflow-circleseq-tsailabsj_py3-10 python=3.10
RUN echo "conda activate nextflow-circleseq-tsailabsj_py3-10" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]
RUN conda activate
RUN source /opt/conda/bin/activate nextflow-circleseq-tsailabsj_py3-10
RUN conda install -c anaconda groff
RUN conda install -c conda-forge awscli
RUN pip3 install boto3
RUN ln -sf /opt/conda/bin/aws /usr/bin/aws
RUN ln -sf /opt/conda/bin/aws /usr/local/bin/aws

RUN echo "conda activate nextflow-circleseq-tsailabsj_py2-7" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]
RUN conda activate
RUN source /opt/conda/bin/activate nextflow-circleseq-tsailabsj_py2-7
#ENV PATH /opt/conda/envs/nextflow-circleseq-tsailabsj_py2-7/bin:$PATH
RUN apt-get update && apt-get install nano
RUN conda install -c conda-forge awscli
RUN pip install boto3
RUN ln -sf /opt/conda/bin/aws /usr/bin/aws
RUN ln -sf /opt/conda/bin/aws /usr/local/bin/aws

RUN cd /test
ENV PATH /opt/conda/envs/nextflow-circleseq-tsailabsj_py3-10/bin:$PATH
WORKDIR /test/circleseq/circleseq
COPY .bashrc /root/.bashrc
COPY bin/link_fq.py .
COPY bin/get_samples.py .
