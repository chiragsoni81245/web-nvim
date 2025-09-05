FROM ubuntu:latest

WORKDIR /root
RUN mkdir -p /root/code

# Install base packages
RUN apt update && \
    apt install -y git wget curl gcc g++

# Install and configure tmux
RUN curl -s https://raw.githubusercontent.com/chiragsoni81245/homelab/refs/heads/main/install/tools/tmux.sh -o /root/tmux.sh && \
    sed -i 's/sudo //' /root/tmux.sh && \
    chmod +x /root/tmux.sh && \
    /bin/bash /root/tmux.sh && \
    rm /root/tmux.sh && \
    curl -s https://raw.githubusercontent.com/chiragsoni81245/homelab/refs/heads/main/bin/tmux-sessionizer -o /usr/local/bin/tmux-sessionizer && \
    sed -i 's/\~\/Documents/\/root\/code/' /usr/local/bin/tmux-sessionizer && \
    chmod +x /usr/local/bin/tmux-sessionizer


# Install and configure nvim
RUN mkdir -p /root/.local/share && \
    curl -s https://raw.githubusercontent.com/chiragsoni81245/homelab/refs/heads/main/install/tools/nvim.sh -o /root/nvim.sh && \
    sed -i 's/sudo //' /root/nvim.sh && \
    chmod +x /root/nvim.sh && \
    /bin/bash /root/nvim.sh && \
    rm /root/nvim.sh

# Install mise
RUN curl https://mise.run | sh && \
    eval "\$(/root/.local/bin/mise activate bash)" && \
    mise use -g usage && \
    mkdir -p ~/.local/share/bash-completion/ && \
    mise completion bash --include-bash-completion-lib > ~/.local/share/bash-completion/completions/mise

RUN cat <<'EOF' >> /root/.config/mise/config.toml
[tools]
usage = "latest"
python = 'latest'
go = 'latest'
EOF

# Gotty setup
RUN wget -q https://github.com/yudai/gotty/releases/download/v1.0.1/gotty_linux_amd64.tar.gz -O /root/gotty_linux_amd64.tar.gz && \
    tar -xvf /root/gotty_linux_amd64.tar.gz -C /root && \
    mv /root/gotty /usr/local/bin/gotty && \
    rm /root/gotty_linux_amd64.tar.gz

RUN cat <<'EOF' >> /root/.gotty
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

# Configure bashrc
RUN cat <<'EOF' >> /root/.bashrc
# Technicolor dreams
force_color_prompt=yes
color_prompt=yes

# Simple prompt with path in the window/pane title and caret for typing line
PS1="\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\[\e[35m\]\$(branch=\$(git symbolic-ref --short HEAD 2>/dev/null); [ -n \"\$branch\" ] && echo \" (\$branch)\")\[\e[0m\] ➜ "

alias vim="nvim";
bind '"\C-f": "/usr/local/bin/tmux-sessionizer\n"'

# For mise setup
eval "$(/root/.local/bin/mise activate bash)"
EOF

ENV PATH="/opt/nvim/bin:${PATH}"
ENV PATH="${PATH}:/usr/local/go/bin"

WORKDIR /root/code

EXPOSE 8080
CMD ["/usr/local/bin/gotty", "-w", "tmux", "new", "-A", "-s", "gotty", "/bin/bash"]
