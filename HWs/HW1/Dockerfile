FROM ubuntu:20.04

# lets-make-your-docker-image-better-than-90-of-existing-ones
ARG BUILD_DATE
LABEL maintainer="ksu_marshmallow" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="BAM Processing Pipeline Image" \
      org.label-schema.description="Docker image for BAM file processing with Samtools" \
      org.label-schema.vcs-ref="main" \
      org.label-schema.schema-version="1.0"

# Setting environment variables for non-interactive apt operations
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/bin:$PATH"

RUN echo "Setting up base image and installing dependencies..."

# Update and install dependencies in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget make unzip gcc openjdk-17-jdk libbz2-dev zlib1g-dev \
    liblzma-dev libcurl4-openssl-dev libncurses5-dev libncurses-dev \
    perl libfindbin-libs-perl \
    python3=3.8.* python3-pip && \
    rm -rf /var/lib/apt/lists/*

#################################################
# 1. Install tools
#################################################

# Set working directory
WORKDIR /usr/src

# Install MultiQC
RUN pip3 install --no-cache-dir multiqc==1.13

# Install HTSLIB, SAMTOOLS, BCFTOOLS
RUN for tool in htslib-1.21 samtools-1.16.1 bcftools-1.18; do \
        wget -q https://github.com/samtools/${tool%%-*}/releases/download/${tool#*-}/$tool.tar.bz2 && \
        tar -xjf $tool.tar.bz2 && \
        cd $tool && \
        make && make install && \
        cd .. && rm -rf $tool*; \
    done

# Install FastQC
RUN wget http://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.5.zip -O /tmp/fastqc.zip && \
    unzip /tmp/fastqc.zip -d /usr/local/ && \
    chmod a+x /usr/local/FastQC/fastqc && \
    ln -s /usr/local/FastQC/fastqc /usr/local/bin/fastqc && \
    rm /tmp/fastqc.zip

# Clean up
RUN apt-get purge -y gcc make unzip && apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/*

# Verify tool installations
RUN samtools --version && \
    bcftools --version && \
    fastqc --version && \
    multiqc --version && \
    echo "All tools installed"

#################################################
# 2. .bam processing pipeline setup
#################################################

# Copy pipeline script
COPY pipeline.sh .
RUN chmod +x pipeline.sh

# Default command
CMD ["./pipeline.sh"]
