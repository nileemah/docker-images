FROM nvidia/cuda:13.0.0-devel-ubuntu22.04

ENV PATH=/usr/local/cuda-13.0/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/cuda-13.0/lib64:/usr/local/cuda/lib64:${LD_LIBRARY_PATH}


ENV DEBIAN_FRONTEND=noninteractive
# Installed comprehensive LaTeX packages, modern fonts, chromium, and pandoc
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip \
    python3-venv \
    git \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-science \
    texlive-xetex \
    fonts-lmodern \
    fonts-dejavu \
    lmodern \
    pandoc \
    chromium-browser \
    && rm -rf /var/lib/apt/lists/*


# Create and activate virtual environment
RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
  
# Upgrade pip inside the venv
RUN pip install --no-cache-dir --upgrade pip 


# 1. Install Jupyter Environment with WebPDF Playwright Extras
RUN pip install --no-cache-dir \
    jupyterlab \
    notebook \
    "nbconvert[webpdf]" \
    playwright

# Install Playwright's specific headless Chromium browser inside the container
RUN playwright install chromium

# Install system dependencies required specifically for Playwright's Chromium binary
USER root
RUN playwright install-deps chromium

# 1. Install Jupyter Environment
RUN pip install --no-cache-dir jupyterlab notebook nbconvert pyppeteer

# Pre-download Chromium inside the virtual environment for WebPDF conversion
RUN pyppeteer-install

# 2. Install Machine Learning Frameworks (with CUDA 13 capabilities)
RUN pip install --no-cache-dir torch torchvision torchaudio
RUN pip install --no-cache-dir "tensorflow[and-cuda]"

# 3. Install Data Science, Visualization & Computer Vision Packages
RUN pip install --no-cache-dir \
    numpy \
    pandas \
    matplotlib \
    seaborn \
    scikit-learn \
    Pillow \
    opencv-python-headless
    
# Fix TensorFlow's internal driver searching paths
RUN cd $(dirname $(python -c 'print(__import__("tensorflow").__file__)')) && \
    ln -svf ../nvidia/*/lib/*.so* .

WORKDIR /workspace
EXPOSE 8888

CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]

