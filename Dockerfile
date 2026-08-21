# ==============================================================================
# Dockerfile for IST Summer School 2027 Diffusion MRI Workshop
# Multi-stage container definition:
#   Stage 1: FreeSurfer (with SynthSeg AI)
#   Stage 2: FSL
#   Stage 3: ANTs
#   Stage 4: MRtrix3
#   Stage 5: Unified Runtime (Ubuntu 22.04 + Python Virtualenv + JupyterLab)
# ==============================================================================

# ------------------------------------------------------------------------------
# --- Stage 1: FreeSurfer ---
# ------------------------------------------------------------------------------
FROM ubuntu:22.04 AS builder_freesurfer
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget tar && \
    rm -rf /var/lib/apt/lists/*

# Install FreeSurfer 7.4.1 (includes mri_synthseg and neural models)
RUN wget --no-check-certificate -qO- "https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.4.1/freesurfer-linux-ubuntu22_amd64-7.4.1.tar.gz" | tar zxv --no-same-owner -C /opt/

# ------------------------------------------------------------------------------
# --- Stage 2: FSL ---
# ------------------------------------------------------------------------------
FROM ubuntu:22.04 AS builder_fsl
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget python3 bc dc file libfontconfig1 libfreetype6 \
    libgl1-mesa-dev libglu1-mesa libgomp1 libice6 libxcursor1 libxft2 \
    libxinerama1 libxrandr2 libxrender1 libxt6 libquadmath0 libgtk2.0-0 \
    locales sudo bzip2 curl && \
    rm -rf /var/lib/apt/lists/*

# Install FSL 6.0.7 using official installer
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py && \
    yes | python3 fslinstaller.py -d /opt/fsl -V 6.0.7 -r -n

# Create symlink for conda as micromamba for compatibility
RUN ln -s /opt/fsl/bin/micromamba /opt/fsl/bin/conda

# ------------------------------------------------------------------------------
# --- Stage 3: ANTs ---
# ------------------------------------------------------------------------------
FROM ubuntu:22.04 AS builder_ants
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget unzip && \
    rm -rf /var/lib/apt/lists/*

# Install ANTs 2.5.0 precompiled binary
RUN wget https://github.com/ANTsX/ANTs/releases/download/v2.5.0/ants-2.5.0-ubuntu-22.04-X64-gcc.zip && \
    unzip ants-2.5.0-ubuntu-22.04-X64-gcc.zip -d /opt/ && \
    mv /opt/ants-2.5.0 /opt/ants && \
    rm ants-2.5.0-ubuntu-22.04-X64-gcc.zip

# ------------------------------------------------------------------------------
# --- Stage 4: MRtrix3 ---
# ------------------------------------------------------------------------------
FROM ubuntu:22.04 AS builder_mrtrix3
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    git g++ python-is-python3 libeigen3-dev zlib1g-dev \
    libqt5opengl5-dev libqt5svg5-dev libgl1-mesa-dev libfftw3-dev \
    libtiff5-dev libpng-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Build MRtrix3 3.0.4 from source
RUN git clone https://github.com/MRtrix3/mrtrix3.git /opt/mrtrix3 && \
    cd /opt/mrtrix3 && \
    git checkout 3.0.4 && \
    ./configure && \
    ./build

# ------------------------------------------------------------------------------
# --- Stage 5: Unified Runtime ---
# ------------------------------------------------------------------------------
FROM ubuntu:22.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PYTHONUNBUFFERED=1 \
    MPLCONFIGDIR=/tmp

# Install runtime system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core system tools & parallel processing
    ca-certificates wget curl unzip zip tar bzip2 bc dc gawk libgomp1 libquadmath0 \
    libglu1-mesa libxt6 libxmu6 libgl1 freeglut3-dev time tcsh parallel dcm2niix git sudo \
    # Python 3 and build dependencies
    python3.10 python3-pip python3-venv python3-dev python-is-python3 \
    libblas-dev liblapack-dev libfreetype6-dev \
    # FSL runtime dependencies
    libfontconfig1 libice6 libsm6 libxcursor1 libxft2 libxinerama1 libxrandr2 libxrender1 libgtk2.0-0 \
    # MRtrix3 runtime dependencies
    libqt5opengl5 libqt5svg5 libqt5gui5 libqt5core5a libqt5widgets5 libfftw3-3 libtiff5 libpng16-16 \
    # Locales
    locales && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Silence the citation notice for GNU Parallel
RUN echo 'will cite' | parallel --citation 1> /dev/null 2> /dev/null || true

# Copy software binaries from builder stages
COPY --from=builder_freesurfer /opt/freesurfer /opt/freesurfer
COPY --from=builder_fsl /opt/fsl /opt/fsl
COPY --from=builder_ants /opt/ants /opt/ants
COPY --from=builder_mrtrix3 /opt/mrtrix3 /opt/mrtrix3

# Set up FreeSurfer license
RUN wget -q --no-check-certificate -O /opt/freesurfer/.license "https://www.dropbox.com/s/zs4k3bcfxderj58/license.txt?dl=0" || \
    echo "academic_user@ist2027\n00000\n *XXXXXX*\n FSYYYYYY" > /opt/freesurfer/.license

# Copy requirements and install in a dedicated virtualenv
COPY requirements.txt /tmp/requirements.txt
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
ENV SETUPTOOLS_USE_DISTUTILS=stdlib

RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Global Neuroimaging Environment Variables
ENV FREESURFER_HOME=/opt/freesurfer \
    FS_LICENSE=/opt/freesurfer/.license \
    FSLDIR=/opt/fsl \
    ANTSPATH=/opt/ants/bin/ \
    MRTRIX3_HOME=/opt/mrtrix3 \
    OS=Linux \
    FS_OVERRIDE=0 \
    FIX_VERTEX_AREA="" \
    SUBJECTS_DIR=/opt/freesurfer/subjects \
    FSF_OUTPUT_FORMAT=nii.gz \
    FSLOUTPUTTYPE=NIFTI_GZ \
    PYTHONPATH=/opt/freesurfer/python/packages \
    DO_NOT_SEARCH_FS_LICENSE_IN_FREESURFER_HOME="true" \
    PATH="/opt/venv/bin:/opt/ants/bin:/opt/mrtrix3/bin:/opt/fsl/bin:/opt/fsl/share/fsl/bin:/opt/freesurfer/bin:$PATH"

# Expose JupyterLab default port
EXPOSE 8888

# Automatic environment activation for interactive bash sessions
RUN echo "# --- IST Summer School 2027 Environment Setup ---" >> /etc/bash.bashrc && \
    echo "source /opt/venv/bin/activate" >> /etc/bash.bashrc && \
    echo "export FREESURFER_HOME=/opt/freesurfer" >> /etc/bash.bashrc && \
    echo "export FS_LICENSE=/opt/freesurfer/.license" >> /etc/bash.bashrc && \
    echo "export FSLDIR=/opt/fsl" >> /etc/bash.bashrc && \
    echo "export ANTSPATH=/opt/ants/bin/" >> /etc/bash.bashrc && \
    echo "export MRTRIX3_HOME=/opt/mrtrix3" >> /etc/bash.bashrc && \
    echo "export PATH=\"/opt/venv/bin:/opt/ants/bin:/opt/mrtrix3/bin:/opt/fsl/bin:/opt/fsl/share/fsl/bin:/opt/freesurfer/bin:\$PATH\"" >> /etc/bash.bashrc && \
    echo "[ -f /opt/fsl/etc/fslconf/fsl.sh ] && . /opt/fsl/etc/fslconf/fsl.sh" >> /etc/bash.bashrc && \
    echo "alias setup_fs='source /opt/freesurfer/SetUpFreeSurfer.sh'" >> /etc/bash.bashrc && \
    echo "[ -f /opt/freesurfer/SetUpFreeSurfer.sh ] && . /opt/freesurfer/SetUpFreeSurfer.sh > /dev/null 2>&1 || true" >> /etc/bash.bashrc

WORKDIR /data

CMD ["/bin/bash"]
