# ==============================================================================
# Dockerfile for IST Summer School 2027 Diffusion MRI Workshop (Standalone)
# Multi-stage container definition:
#   Stage 1: FreeSurfer 7.4.1 (with SynthSeg AI, pruned)
#   Stage 2: FSL 6.0.7 (pruned)
#   Stage 3: ANTs 2.5.0 (pruned)
#   Stage 4: MRtrix3 3.0.8 (built from source with Python 3.12 support)
#   Stage 5: Unified Runtime (Ubuntu 24.04 + Native Python 3.12 + umask 000)
#   + /opt/ist2027/precomputed (precomputed SynthSeg of the workshop T1)
# ==============================================================================

# ------------------------------------------------------------------------------
# --- Stage 1: FreeSurfer ---
# ------------------------------------------------------------------------------
FROM ubuntu:24.04 AS builder_freesurfer
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget tar && \
    rm -rf /var/lib/apt/lists/*

# Download and extract FreeSurfer 7.4.1, pruning unused heavy assets
RUN wget --no-check-certificate -qO- "https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.4.1/freesurfer-linux-ubuntu22_amd64-7.4.1.tar.gz" | tar zxv --no-same-owner -C /opt/ && \
    rm -rf /opt/freesurfer/subjects \
           /opt/freesurfer/average \
           /opt/freesurfer/trctrain \
           /opt/freesurfer/docs \
           /opt/freesurfer/matlab \
           /opt/freesurfer/fsfast \
           /opt/freesurfer/fsafd \
           /opt/freesurfer/mni \
           /opt/freesurfer/mni-1.4

# ------------------------------------------------------------------------------
# --- Stage 2: FSL ---
# ------------------------------------------------------------------------------
FROM ubuntu:24.04 AS builder_fsl
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget python3 bc dc file libfontconfig1 libfreetype6 \
    libgl1-mesa-dev libglu1-mesa libgomp1 libice6 libxcursor1 libxft2 \
    libxinerama1 libxrandr2 libxrender1 libxt6 libquadmath0 \
    locales sudo bzip2 curl && \
    rm -rf /var/lib/apt/lists/*

# Install FSL 6.0.7 via official installer and clean unused caches/headers
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py && \
    yes | python3 fslinstaller.py -d /opt/fsl -V 6.0.7 -r -n && \
    ln -s /opt/fsl/bin/micromamba /opt/fsl/bin/conda && \
    rm -f fslinstaller.py && \
    rm -rf /opt/fsl/pkgs \
           /opt/fsl/include \
           /opt/fsl/src \
           /opt/fsl/doc \
           /opt/fsl/data/atlases \
           /opt/fsl/data/standard/tissuepriors

# ------------------------------------------------------------------------------
# --- Stage 3: ANTs ---
# ------------------------------------------------------------------------------
FROM ubuntu:24.04 AS builder_ants
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget unzip && \
    rm -rf /var/lib/apt/lists/*

# Install ANTs 2.5.0 and prune non-registration executables
RUN wget https://github.com/ANTsX/ANTs/releases/download/v2.5.0/ants-2.5.0-ubuntu-22.04-X64-gcc.zip && \
    unzip ants-2.5.0-ubuntu-22.04-X64-gcc.zip -d /opt/ && \
    mv /opt/ants-2.5.0 /opt/ants && \
    rm -f ants-2.5.0-ubuntu-22.04-X64-gcc.zip && \
    mkdir -p /opt/ants_clean/bin /opt/ants_clean/lib && \
    cp -P /opt/ants/lib/* /opt/ants_clean/lib/ 2>/dev/null || true && \
    for bin in antsRegistration antsRegistrationSyN.sh antsRegistrationSyNQuick.sh \
               antsApplyTransforms antsApplyTransformsToPoints N4BiasFieldCorrection \
               ImageMath ThresholdImage antsSliceRegularizedRegistration PrintHeader; do \
        [ -e "/opt/ants/bin/$bin" ] && cp -P "/opt/ants/bin/$bin" /opt/ants_clean/bin/; \
    done && \
    rm -rf /opt/ants && \
    mv /opt/ants_clean /opt/ants

# ------------------------------------------------------------------------------
# --- Stage 4: MRtrix3 ---
# ------------------------------------------------------------------------------
FROM ubuntu:24.04 AS builder_mrtrix3
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    git g++ python3 python-is-python3 libeigen3-dev zlib1g-dev \
    libqt5opengl5-dev libqt5svg5-dev libgl1-mesa-dev libfftw3-dev \
    libtiff-dev libpng-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Build MRtrix3 3.0.8 from source
RUN git clone https://github.com/MRtrix3/mrtrix3.git /opt/mrtrix3 && \
    cd /opt/mrtrix3 && \
    (git checkout 3.0.8 || git checkout 3.0_RC3 || true) && \
    ./configure && \
    ./build && \
    rm -rf /opt/mrtrix3/tmp

# ------------------------------------------------------------------------------
# --- Stage 5: Unified Runtime ---
# ------------------------------------------------------------------------------
FROM ubuntu:24.04 AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    PYTHONUNBUFFERED=1 \
    MPLCONFIGDIR=/tmp

# Install runtime system packages and Native Python 3.12
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget curl unzip zip tar bzip2 bc dc gawk libgomp1 libquadmath0 \
    libglu1-mesa libxt6 libxmu6 libgl1 freeglut3-dev time tcsh parallel dcm2niix git sudo \
    # Python 3.12 (native) & build dependencies
    python3 python3-pip python3-venv python3-dev python-is-python3 \
    build-essential gcc g++ libblas-dev liblapack-dev libfreetype6-dev \
    # FSL runtime dependencies
    libfontconfig1 libice6 libsm6 libxcursor1 libxft2 libxinerama1 libxrandr2 libxrender1 \
    # MRtrix3 runtime dependencies
    libqt5opengl5t64 libqt5svg5 libqt5gui5t64 libqt5core5t64 libqt5widgets5t64 libfftw3-double3 libfftw3-single3 libtiff6 libpng16-16t64 \
    # Locales
    locales && \
    locale-gen en_US.UTF-8 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Silence the citation notice for GNU Parallel
RUN echo 'will cite' | parallel --citation 1> /dev/null 2> /dev/null || true

# Set up Python 3.12 Virtual Environment and Install Dependencies
COPY requirements.txt /tmp/requirements.txt
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Copy minified software binaries from builder stages
COPY --from=builder_freesurfer /opt/freesurfer /opt/freesurfer
COPY --from=builder_fsl /opt/fsl /opt/fsl
COPY --from=builder_ants /opt/ants /opt/ants
COPY --from=builder_mrtrix3 /opt/mrtrix3 /opt/mrtrix3

# Precomputed SynthSeg of the workshop T1 (mri_synthseg needs ~15 GB RAM).
# Participants copy it manually if SynthSeg crashes (see tutorial_1.6, Step 3).
# Lives outside /summer_school so the repository bind-mount does not hide it.
COPY precomputed/ /opt/ist2027/precomputed/
RUN chmod -R a+rX /opt/ist2027/precomputed

# Set up FreeSurfer license
RUN wget -q --no-check-certificate -O /opt/freesurfer/.license "https://www.dropbox.com/s/zs4k3bcfxderj58/license.txt?dl=0" || \
    echo "academic_user@ist2027\n00000\n *XXXXXX*\n FSYYYYYY" > /opt/freesurfer/.license

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

# Automatic environment activation & umask 000 (fully unlocked files)
RUN echo "# --- IST Summer School 2027 Environment Setup ---" >> /etc/bash.bashrc && \
    echo "umask 000" >> /etc/bash.bashrc && \
    echo "umask 000" >> /etc/profile && \
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
