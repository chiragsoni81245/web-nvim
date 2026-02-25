FROM ubuntu:latest

WORKDIR /home/ubuntu
USER ubuntu
ENV HOME /home/ubuntu
RUN mkdir -p ./code


#### -------------------------------------
#### Install base packages
#### -------------------------------------
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
        git wget curl unzip zip tar \
        python3-venv \
        lsb-release software-properties-common gnupg


#### -------------------------------------
#### Install and Configure C++
#### -------------------------------------
# Install Clang Compiler
RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 19 all && \
    rm llvm.sh && \
    update-alternatives --install /usr/bin/clang clang /usr/bin/clang-19 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-19 100 && \
    update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-19 100 && \
    update-alternatives --install /usr/bin/lldb lldb /usr/bin/lldb-19 100 && \
    update-alternatives --install /usr/bin/lld lld /usr/bin/lld-19 100 && \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-19 100

# Install Cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v4.2.0-rc4/cmake-4.2.0-rc4-linux-x86_64.sh && \
    chmod +x cmake-4.2.0-rc4-linux-x86_64.sh && \
    mkdir -p /opt/cmake-4.2.0 && \
    ./cmake-4.2.0-rc4-linux-x86_64.sh --prefix=/opt/cmake-4.2.0 --skip-license && \
    rm cmake-4.2.0-rc4-linux-x86_64.sh &&\
    update-alternatives --install /usr/bin/cmake cmake /opt/cmake-4.2.0/bin/cmake 100 && \
    update-alternatives --install /usr/bin/ctest ctest /opt/cmake-4.2.0/bin/ctest 100 && \
    update-alternatives --install /usr/bin/cpack cpack /opt/cmake-4.2.0/bin/cpack 100

# Install Ninja Build System
RUN wget https://github.com/ninja-build/ninja/releases/download/v1.13.1/ninja-linux.zip && \
    unzip ninja-linux.zip && \
    mv ninja /usr/bin/ninja && \
    chmod +x /usr/bin/ninja && \
    rm ninja-linux.zip

# Install vcpkg for package management in C++
RUN cd ~ && \
    git clone https://github.com/microsoft/vcpkg.git && \
    cd vcpkg && \
    ./bootstrap-vcpkg.sh


#### -------------------------------------
#### Install and configure tmux
#### -------------------------------------
RUN curl -s https://raw.githubusercontent.com/chiragsoni81245/homelab/refs/heads/main/install/tools/tmux.sh -o ./tmux.sh && \
    sed -i 's/sudo //' ./tmux.sh && \
    chmod +x ./tmux.sh && \
    /bin/bash ./tmux.sh && \
    rm ./tmux.sh && \
    curl -s https://raw.githubusercontent.com/chiragsoni81245/homelab/refs/heads/main/bin/tmux-sessionizer -o /usr/local/bin/tmux-sessionizer && \
    sed -i 's/\~\/Documents/\/root\/code/' /usr/local/bin/tmux-sessionizer && \
    chmod +x /usr/local/bin/tmux-sessionizer


#### -------------------------------------
#### Install and configure nvim
#### -------------------------------------
RUN mkdir -p ./.local/share && \
    curl -s https://raw.githubusercontent.com/chiragsoni81245/homelab/refs/heads/main/install/tools/nvim.sh -o ./nvim.sh && \
    sed -i 's/sudo //' ./nvim.sh && \
    chmod +x ./nvim.sh && \
    /bin/bash ./nvim.sh && \
    rm ./nvim.sh


#### -------------------------------------
#### Install mise
#### -------------------------------------
RUN curl https://mise.run | sh && \
    mkdir -p ./.config/mise && \
    touch ./.config/mise/config.toml && \
    cat <<'EOF' > ./.config/mise/config.toml
[tools]
usage = "latest"
python = 'latest'
go = 'latest'
EOF

RUN ./.local/bin/mise install && \
    mkdir -p ./.local/share/bash-completion/ && \
    mkdir -p ./.local/share/bash-completion/completions && \
    ./.local/bin/mise completion bash --include-bash-completion-lib > ./.local/share/bash-completion/completions/mise


#### -------------------------------------
#### Gotty setup
#### -------------------------------------
RUN wget -q https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz -O ./gotty_linux_amd64.tar.gz && \
    tar -xvf ./gotty_linux_amd64.tar.gz -C ./ && \
    mv ./gotty /usr/local/bin/gotty && \
    rm ./gotty_linux_amd64.tar.gz

RUN cat <<'EOF' > ./.gotty
address = "0.0.0.0"
port = "8080"
random-url = true
random-url-length = 10
reconnect = true
reconnect-time = 3
max-connection = 5
width = 0
height = 0
term = "xterm"
title-format = "🔥 {{ .command }} on {{ .hostname }}"
permit-arguments = false
close-signal = "SIGHUP"
close-timeout = 5
preferences {
    font_size = 18
    background_color = "rgb(16, 16, 32)"
}
EOF
ENV TERM=xterm-256color


#### -------------------------------------
#### Configure bashrc
#### -------------------------------------
RUN cat <<'EOF' >> ./.bashrc
# Technicolor dreams
force_color_prompt=yes
color_prompt=yes

# Simple prompt with path in the window/pane title and caret for typing line
PS1="\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\[\e[35m\]\$(branch=\$(git symbolic-ref --short HEAD 2>/dev/null); [ -n \"\$branch\" ] && echo \" (\$branch)\")\[\e[0m\] ➜ "

alias vim="nvim";
bind '"\C-f": "/usr/local/bin/tmux-sessionizer\n"'

# For mise setup
eval "$(~/.local/bin/mise activate bash)"

# C++ setup things
export PATH=/opt/cmake-3.31.6/bin:$PATH
export VCPKG_ROOT=~/vcpkg
export PATH=$VCPKG_ROOT:$PATH
EOF

ENV PATH="/opt/nvim/bin:${PATH}"
ENV PATH="${PATH}:/usr/local/go/bin"

WORKDIR ~/

EXPOSE 8080
CMD ["/usr/local/bin/gotty", "-w", "tmux", "new", "-A", "-s", "gotty", "/bin/bash"]
