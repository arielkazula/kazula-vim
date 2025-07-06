# syntax=docker/dockerfile:1.4

# Neovim IDE container – Kickstart + fzf-lua + full tool-chain
FROM ubuntu:24.04
ARG DEBIAN_FRONTEND=noninteractive

# ──────────────────────────────────────────────────────────────────────────── #
# 0. Optimize APT using BuildKit cache mounts and config                     #
# ──────────────────────────────────────────────────────────────────────────── #
RUN --mount=type=cache,target=/var/lib/apt/lists \
    --mount=type=cache,target=/var/cache/apt \
    tee /etc/apt/apt.conf.d/99optim <<EOF
Acquire::Languages "none";
Acquire::CompressionTypes::Order "gz";
APT::Acquire::Retries "3";
Acquire::Queue-Mode "host";
Acquire::ForceIPv4 "true";
Acquire::http { Pipeline-Depth "200"; };
EOF

# ──────────────────────────────────────────────────────────────────────────── #
# 1. Prerequisites for external repositories                                 #
# ──────────────────────────────────────────────────────────────────────────── #
RUN --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common curl gnupg lsb-release \
        apt-transport-https ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────────────── #
# 2. Add PPAs and Postgres repository                                        #
# ──────────────────────────────────────────────────────────────────────────── #
RUN add-apt-repository -y ppa:neovim-ppa/unstable && \
    add-apt-repository -y ppa:openjdk-r/ppa && \
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc \
        | gpg --dearmor -o /usr/share/keyrings/pgdg.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/pgdg.gpg] \
      http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" \
        > /etc/apt/sources.list.d/pgdg.list

# ──────────────────────────────────────────────────────────────────────────── #
# 3. Base build tools                                                       #
# ──────────────────────────────────────────────────────────────────────────── #
RUN --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential git curl wget xz-utils \
        ca-certificates sudo nano && \
    rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────────────── #
# 4. Editor & Python integration                                             #
# ──────────────────────────────────────────────────────────────────────────── #
RUN --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        neovim libncurses5-dev libncursesw5-dev \
        python3 python3-dev python3-venv python3-pip python3-neovim && \
    rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────────────── #
# 5. Database headers & SSL                                                  #
# ──────────────────────────────────────────────────────────────────────────── #
RUN --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        postgresql-server-dev-all libpq-dev postgresql-16 postgresql \
        libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────────────── #
# 6. Compiler toolchain & Linters                                            #
# ──────────────────────────────────────────────────────────────────────────── #
RUN --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        clangd cmake clang gcc g++ make \
        universal-ctags shellcheck ripgrep fd-find doxygen fzf bat gdb uuid-dev libaio-dev && \
    ln -sf /usr/bin/fd-find /usr/local/bin/fd && \
    rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────────────── #
# 7. Node.js & global LSP servers                                             #
# ──────────────────────────────────────────────────────────────────────────── #
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update && apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*
RUN npm install -g \
    neovim \
    tree-sitter-cli \
    typescript typescript-language-server \
    bash-language-server \
    yaml-language-server \
    vim-language-server \
    pyright

# ──────────────────────────────────────────────────────────────────────────── #
# 8. Go installation                                                         #
# ──────────────────────────────────────────────────────────────────────────── #
ENV GO_VERSION=1.21.1
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz && \
    mkdir -p /go/src /go/bin /go/pkg/mod
ENV PATH="/usr/local/go/bin:/go/bin:${PATH}" \
    GOPATH="/go"
ENV GOBIN=/usr/local/bin

# 3. Install the latest fzf and verify
RUN go install github.com/junegunn/fzf@latest \
  && fzf --version

# ──────────────────────────────────────────────────────────────────────────── #
# 9. LuaRocks                                                                #
# ──────────────────────────────────────────────────────────────────────────── #
RUN --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    apt-get install -y --no-install-recommends lua5.4 lua5.4-dev unzip && \
    wget https://luarocks.org/releases/luarocks-3.9.1.tar.gz && \
    tar zxpf luarocks-3.9.1.tar.gz && cd luarocks-3.9.1 && \
    ./configure && make && make install && cd .. && \
    rm -rf luarocks-3.9.1 luarocks-3.9.1.tar.gz && \
    rm -rf /var/lib/apt/lists/*

# ──────────────────────────────────────────────────────────────────────────── #
# 10. LazyGit                                                                #
# ──────────────────────────────────────────────────────────────────────────── #
RUN set -eux; \
    LG_VER="$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
              | grep -Po '"tag_name":\s*"v\K[0-9.]+')"; \
    curl -L -o /tmp/lazygit.tar.gz \
         "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VER}/lazygit_${LG_VER}_Linux_x86_64.tar.gz"; \
    tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit; \
    install -m0755 /tmp/lazygit /usr/local/bin/lazygit; \
    rm -rf /tmp/lazygit /tmp/lazygit.tar.gz

# ──────────────────────────────────────────────────────────────────────────── #
# 11. Python global packages                                                  #
# ──────────────────────────────────────────────────────────────────────────── #
RUN python3 -m pip install --break-system-packages pynvim neovim

# ──────────────────────────────────────────────────────────────────────────── #
# 12. GoogleTest & cleanup                                                     #
# ──────────────────────────────────────────────────────────────────────────── #
RUN git clone https://github.com/google/googletest.git /usr/src/googletest && \
    cd /usr/src/googletest && mkdir build && cd build && cmake .. && \
    make -j$(nproc) && make install && \
    rm -rf /usr/src/googletest && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN ldconfig


RUN --mount=type=cache,target=/var/lib/apt/lists \
    apt-get update && \
    apt-get install -y --no-install-recommends xclip xauth postgresql-server-dev-all libpq-dev postgresql-16 postgresql openjdk-8-jdk&& \
    rm -rf /var/lib/apt/lists/*


# Create a symlink for cmake3 pointing to cmake
RUN ln -s /usr/bin/cmake /usr/local/bin/cmake3
RUN ln -s /usr/include/postgresql/16/server/postgres_ext.h /usr/include/postgres_ext.h

# ──────────────────────────────────────────────────────────────────────────── #
# 13. Kickstart Neovim configuration (read-only)                               #
# ──────────────────────────────────────────────────────────────────────────── #

ENV LANG=en_US.UTF-8
ENV XDG_CONFIG_HOME=/opt/nvim-config
RUN mkdir -p ${XDG_CONFIG_HOME}/nvim && rm -f ${XDG_CONFIG_HOME}/nvim/lazy-lock.json

WORKDIR /workspace
CMD ["nvim"]