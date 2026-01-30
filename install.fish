#!/usr/bin/env fish

# Install aws-config-multiple-organizations
# Copies example config.d files and adds the fish shell hook

set script_dir (cd (dirname (status -f)); and pwd)

# Create config.d directory
mkdir -p ~/.aws/config.d

# Copy example files (skip if real files already exist)
for f in $script_dir/config.d/*
    set basename (basename $f)
    if test -f ~/.aws/config.d/$basename
        echo "skip: ~/.aws/config.d/$basename already exists"
    else
        cp $f ~/.aws/config.d/$basename
        echo "copied: ~/.aws/config.d/$basename"
    end
end

# Check if fish config already has the hook
if test -f ~/.config/fish/config.fish
    if grep -q "aws/config.d" ~/.config/fish/config.fish
        echo "skip: fish hook already present in config.fish"
    else
        set snippet (cat $script_dir/config.fish.snippet)
        # Prepend the snippet to config.fish
        set existing (cat ~/.config/fish/config.fish)
        echo $snippet\n$existing > ~/.config/fish/config.fish
        echo "added: fish hook to ~/.config/fish/config.fish"
    end
else
    mkdir -p ~/.config/fish
    cp $script_dir/config.fish.snippet ~/.config/fish/config.fish
    echo "created: ~/.config/fish/config.fish with hook"
end

# Trigger initial build
cat ~/.aws/config.d/* > ~/.aws/config
echo "built: ~/.aws/config from config.d/"
echo "done!"
