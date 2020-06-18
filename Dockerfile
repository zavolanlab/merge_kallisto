##### BASE IMAGE #####
FROM continuumio/miniconda:4.7.12

##### METADATA #####
LABEL base.image="continuumio/miniconda:4.7.12"
LABEL software="merge_kallisto"
LABEL software.description="Merge kallisto quantification"
LABEL software.website="https://github.com/zavolanlab/merge_kallisto"
LABEL software.documentation="https://github.com/zavolanlab/merge_kallisto"
LABEL software.license="https://github.com/zavolanlab/prune_tree/blob/master/LICENSE"
LABEL software.tags="Transcriptomics"
LABEL maintainer="foivos.gypas@unibas.ch"
LABEL maintainer.organisation="Biozentrum, University of Basel"
LABEL maintainer.location="Klingelbergstrasse 50/70, CH-4056 Basel, Switzerland"
LABEL maintainer.lab="Zavolan Lab"
LABEL maintainer.license="https://spdx.org/licenses/Apache-2.0"

COPY R/merge_kallisto.R /usr/local/bin/merge_kallisto.R

RUN conda \
create -n merge_kallisto \
--yes \
--channel bioconda \
--channel conda-forge \
--channel bioconda \
--channel conda-forge \
bioconductor-tximport=1.14.0 \
bioconductor-rhdf5=2.30.0 \
r-optparse=1.6.2 \
bioconductor-rtracklayer=1.46.0 \
&& conda clean --index-cache --tarballs -y

RUN echo "source activate merge_kallisto" > ~/.bashrc
ENV PATH /opt/conda/envs/merge_kallisto/bin:${PATH}
