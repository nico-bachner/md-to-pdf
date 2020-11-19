#!/bin/sh

REPO_NAME="nico-bachner/md-paper"

function warning {
    echo -e "\033[38;5;1mWARNING: ${1}"
}

if [ ! brew ls --versions pandoc ]
then
    warning "Pandoc was not found on your machine. You will need to install pandoc for this program to work."
fi

if [ ! latex -v ]
then
    warning "This program requires a TeX distribution to work, but none were found."
fi

if [ -e /usr/local/bin/md-paper ]
then
    warning "It seems a program called 'md-paper' already exists. To install please rename or delete the existing program and try again" 
    exit 1
else
    curl https://raw.githubusercontent.com/nico-bachner/md-paper/master/src/md-paper.ksh -o /usr/local/bin/md-paper 
    chmod +x ~/usr/local/bin/md-paper
    curl https://md-paper.now.sh/src/template.tex -o /usr/local/md-paper/template.tex
    
    if [ -e /usr/local/bin/md-paper ]
    then
        echo "md-paper: installation successful"
        exit 0
    else
        echo "md-paper: installation failed"
        exit 1
    fi
fi
