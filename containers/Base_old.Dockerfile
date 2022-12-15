FROM nfcore/base:1.14
LABEL authors="Alan Tracey" \
      description="Docker image containing all software requirements for the bit-bio/nextflow-circleseq-tsailabsj pipeline"

RUN apt update -y && apt upgrade -y

RUN apt install -y curl unzip vim

# Install the conda environment
COPY containers/environment.yml /

#ensure we install into python2.7 (eg HTSlib into python 2.7)
RUN conda env create --quiet -f /environment.yml python=2.7 && conda clean -a

# Add conda installation dir to PATH (instead of doing 'conda activate')
ENV PATH /opt/conda/envs/nextflow-circleseq-tsailabsj/bin:$PATH

# Dump the details of the installed packages to a file for posterity
RUN conda env export --name nextflow-circleseq-tsailabsj > nextflow-circleseq-tsailabsj-details.yml

# Install dependency for aws cli
RUN conda install -c anaconda groff

RUN conda install -c conda-forge awscli

#awscli and boto3 will go into python3
RUN pip3 install awscli

# Symlink to /usr/bin/aws - This fails at times, more testing needed.
RUN ln -sf /opt/conda/envs/nextflow-circleseq-tsailabsj/bin/aws /usr/local/bin/aws
RUN ln -sf /opt/conda/envs/nextflow-circleseq-tsailabsj/bin/aws /usr/bin/aws


#RUN pip3 install circle_seq

#Allows python API calls on AWS - used in the group for lambda function calls
RUN pip3 install boto3

RUN mkdir /test

RUN cd /test && git clone https://github.com/tsailabSJ/circleseq


WORKDIR /test

RUN wget -P ~/.local/lib https://bootstrap.pypa.io/pip/2.7/get-pip.py
RUN python2.7 ~/.local/lib/get-pip.py --user
RUN python2.7 -m pip install nose
RUN python2.7 -m pip install pyyaml
RUN python2.7 -m pip install svgwrite
#RUN apt-get install build-essential python2.7-dev python-numpy python-matplotlib python-pysam python-htseq

#To fix CL input "Do you want to continue? [Y/n]"
RUN yes | apt-get install build-essential python2.7-dev python-htseq

RUN python2.7 -m pip install pyfaidx
#Regex has to be this specific version - newer version drop support for python 2.7
RUN python2.7 -m pip install "regex<2022.1.18"

#tsailab recommend samtools 1.3 - here is 1.3.1:
#hopefully this is now installed in the conda build - this didn't work via env.yml
#RUN conda install -c compbiocore samtools



#bwa 0.7.11 must be used - this is working correctly
RUN wget https://downloads.sourceforge.net/project/bio-bwa/bwakit/bwakit-0.7.11_x64-linux.tar.bz2
RUN tar xjvf bwakit-0.7.11_x64-linux.tar.bz2
RUN rm -rf bwakit-0.7.11_x64-linux.tar.bz2
RUN /bin/mv /opt/conda/envs/nextflow-circleseq-tsailabsj/bin/bwa /opt/conda/envs/nextflow-circleseq-tsailabsj/bin/bwa_0.7.17
RUN /bin/ln -s /test/bwa.kit/bwa /opt/conda/envs/nextflow-circleseq-tsailabsj/bin/bwa

#1000 seconds
#RUN python2.7 -m pip install statsmodels

#someone recommends downgrading statsmodels to 0.10.0 to fix numpy thing
#not sure we see this conda after build
#1000 seconds, numpy 1.23.4
#this is supposed to install 0.10.1, but is actually installing 0.13.2
RUN wget https://anaconda.org/conda-forge/statsmodels/0.10.1/download/linux-64/statsmodels-0.10.1-py27hc1659b7_2.tar.bz2
RUN conda install statsmodels-0.10.1-py27hc1659b7_2.tar.bz2
RUN rm -rf statsmodels-0.10.1-py27hc1659b7_2.tar.bz2
ENV PATH /opt/conda/pkgs/statsmodels-0.10.1-py27hc1659b7_2/lib/python2.7/site-packages:$PATH

#RUN conda install -c cdat-forge statsmodels=linux-64/statsmodels-0.10.1-py27hc1659b7_2.tar.bz2

#how to copy nextflow repo template?























