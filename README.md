# PyTorch ROCm 5.7 Docker Stack for AMD Polaris (gfx803)

![Docker Image Size](https://img.shields.io/badge/image%20size-~12GB-blue)
![ROCm Version](https://img.shields.io/badge/ROCm-5.7-green)
![Python Version](https://img.shields.io/badge/python-3.10-yellow)

Este projeto fornece um ambiente Docker completo, estável e otimizado para rodar **PyTorch 2.3** com aceleração de GPU em placas AMD da arquitetura Polaris (RX 580, RX 590, etc), identificadas tecnicamente como `gfx803`.

O suporte oficial para estas placas foi descontinuado nas versões modernas do ROCm, mas este repositório contorna isso através da compilação manual do PyTorch e Torchvision, "transplantados" para uma imagem base moderna.

> **Baseado no trabalho de:** Este projeto foi fortemente inspirado e adaptado a partir do repositório [gfx803_rocm57_pt23 de Robert Rosenbusch](https://github.com/robertrosenbusch/gfx803_rocm57_pt23).

## 🚀 Funcionalidades

* **Aceleração de GPU Garantida:** Binários compilados especificamente para `gfx803`.
* **Jupyter Lab "Batteries Included":** Pré-configurado com:
    * Extensões visuais e monitoramento de recursos.
    * LSP (Language Server Protocol) para autocomplete e diagnósticos.
    * Formatadores de código (`black`, `isort`).
* **Data Science Ready:** Inclui Pandas, Scikit-Learn, Matplotlib (com backend interativo `ipympl`), Seaborn e TQDM.
* **Imagem Otimizada (Smart Slim):** Utiliza uma estratégia híbrida que reduz o tamanho da imagem oficial (~25GB) para cerca de **12GB**, removendo drivers de arquiteturas não utilizadas (Vega/Navi/MI100).

## 📂 Estrutura do Repositório

```text
.
├── wheels/                # Binários compilados (.whl) do PyTorch e Torchvision (Git LFS)
├── Dockerfile             # Imagem final otimizada (Runtime)
├── docker-compose.yml     # Orquestração para rodar o Jupyter Lab
├── build_scripts/         # Scripts usados para a compilação original
│   ├── Dockerfile.p1      # Parte 1: Dependências do Sistema e Git Clone
│   └── Dockerfile.p2      # Parte 2: Compilação do código fonte (Builder)
└── README.md              # Este arquivo

🛠️ Pré-requisitos

    Hardware: GPU AMD Polaris (RX 470/480/570/580/590).

    Drivers: Drivers AMD instalados no host Linux (rocminfo deve listar sua GPU).

    Docker: Docker Engine e Docker Compose instalados.

    Permissões: Seu usuário deve pertencer aos grupos video e render.

    Git LFS: Necessário para baixar os arquivos .whl corretamente.
    Bash

    sudo apt install git-lfs
    git lfs install

🏃 Como Usar (Quick Start)

Este método utiliza os wheels pré-compilados na pasta wheels/, economizando horas de compilação.
1. Clonar o Repositório
Bash

git clone [https://github.com/arthur-og/pytorch-gfx803-docker.git](https://github.com/arthur-og/pytorch-gfx803-docker.git)
cd pytorch-gfx803-docker

2. Construir a Imagem Final

O build é rápido pois apenas instala os binários e limpa a imagem.
Bash

docker build -t pytorch-gfx803:final .

3. Rodar o Ambiente

Utilize o Docker Compose para iniciar o Jupyter Lab com as configurações corretas de dispositivo (/dev/kfd) e memória compartilhada.
Bash

docker-compose up -d

    Acesse: Abra http://localhost:8888 no seu navegador.

    Logs: Para ver o token ou erros: docker-compose logs -f.

    Parar: docker-compose down.

⚙️ Detalhes da Otimização

O Dockerfile final utiliza uma técnica de substituição cirúrgica:

    Inicia com a imagem oficial rocm/pytorch:rocm5.7... para garantir todas as dependências de sistema (OpenBLAS, MAGMA, MIOpen).

    Remove o PyTorch oficial (que crasha na RX 580).

    Atualiza o pip e instala os .whl customizados da pasta wheels/.

    Executa uma limpeza agressiva em /opt/rocm, removendo bibliotecas rocBLAS e MIOpen destinadas a arquiteturas gfx9 (Vega), gfx10 (Navi/RDNA) e gfx11.

Isso resulta em um ambiente 100% funcional mas com metade do peso da imagem oficial.
🧪 Como Reproduzir a Compilação (Avançado)

Caso queira recompilar os wheels do zero (por exemplo, para atualizar a versão do PyTorch), os scripts originais estão na pasta build_scripts/.

Processo:

    Parte 1 (Base): Prepara o sistema e clona os repositórios.
    Bash

docker build -t pytorch-gfx803:part1 -f build_scripts/Dockerfile.p1 .

Parte 2 (Builder): Compila o PyTorch (pode levar horas).
Bash

docker build -t pytorch-gfx803:builder -f build_scripts/Dockerfile.p2 .

Extração: Copie os arquivos gerados de dentro do container para a pasta wheels/.
Bash

    docker create --name temp_extract pytorch-gfx803:builder
    docker cp temp_extract:/pytorch/dist/. ./wheels/
    docker cp temp_extract:/vision/dist/. ./wheels/
    docker rm temp_extract

🤝 Contribuição e Créditos

    Autor Original da abordagem: Robert Rosenbusch

    Adaptação e Otimização Docker: arthur-og

Sinta-se à vontade para abrir Issues ou Pull Requests para melhorar a compatibilidade ou reduzir ainda mais o tamanho da imagem.
