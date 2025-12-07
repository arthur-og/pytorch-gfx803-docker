# Dockerfile.final
# Estratégia: Usar a base completa (para ter as libs) e limpar o excesso.
FROM rocm/pytorch:rocm5.7_ubuntu22.04_py3.10_pytorch_2.0.1

# Variáveis de Ambiente (Mantidas)
ENV HSA_OVERRIDE_GFX_VERSION=8.0.3 \
    ROCM_PATH=/opt/rocm \
    PYTORCH_HIP_ALLOC_CONF=garbage_collection_threshold:0.8,max_split_size_mb:128 \
    DEBIAN_FRONTEND=noninteractive \
    SHELL="/bin/bash"

USER root

# 1. Instalar dependências extras do Jupyter/Sistema
# (Não precisamos instalar openblas/mpi/magma, pois ESSA imagem já tem!)
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs npm curl unzip libjpeg8 \
    # Adicionamos 'htop' e 'nvtop' (útil para monitorar GPU AMD)
    htop \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# 2. Copiar os wheels locais (Sua compilação customizada)
COPY wheels/ /tmp/wheels/

# 3. A GRANDE TROCA (Uninstall Oficial -> Install Customizado)
RUN echo "Trocando PyTorch..." && \
    # Remove o PyTorch que vem na imagem (incompatível com gfx803)
    # 1. ATUALIZAÇÃO CRÍTICA DO PIP (De v20 para v24+)
    pip install --upgrade pip && \

    pip uninstall -y torch torchvision torchaudio && \
    # Instala o SEU PyTorch compilado
    pip install --no-cache-dir /tmp/wheels/*.whl && \
    # Instala o restante das libs de Data Science
    pip install --no-cache-dir \
    jupyterlab matplotlib ipywidgets pandas scipy ipympl scikit-learn tqdm seaborn \
    jupyterlab_execute_time jupyter-resource-usage jupyterlab_materialdarker \
    "jupyterlab-lsp" "python-lsp-server[all]" jupyterlab_code_formatter black isort && \
    rm -rf /tmp/wheels

# 4. A LIMPEZA (Para reduzir de ~25GB para ~12GB)
# Como essa imagem vem com suporte para TODAS as placas, vamos apagar as outras.
RUN echo "Limpando drivers de outras arquiteturas..." && \
    # Limpa rocBLAS (O maior vilão do espaço)
    rm -rf /opt/rocm/rocblas/lib/library/*gfx9* && \
    rm -rf /opt/rocm/rocblas/lib/library/*gfx10* && \
    rm -rf /opt/rocm/rocblas/lib/library/*gfx11* && \
    # Limpa MIOpen (Kernels de outras placas)
    rm -rf /opt/rocm/miopen/share/miopen/db/*gfx9* && \
    rm -rf /opt/rocm/miopen/share/miopen/db/*gfx10* && \
    rm -rf /opt/rocm/miopen/share/miopen/db/*gfx11* && \
    # Remove código fonte do PyTorch antigo se sobrar algo em /opt/conda
    find /opt/conda -name "*torch*" -type d -name "test" -exec rm -rf {} +

# 5. Configurar Jupyter
RUN jupyter labextension enable jupyterlab-execute-time && \
    mkdir -p /root/.jupyter && \
    echo "c.InteractiveShellApp.matplotlib = 'ipympl'" >> /root/.jupyter/jupyter_config.py

EXPOSE 8888

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=''", "--notebook-dir=/workspace"]
