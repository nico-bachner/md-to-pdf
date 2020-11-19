function ERROR {
    echo -e "\033[38;5;1mERROR: ${1}"
    exit 1
}

function LOADING {
    echo "$2"

    STEP_SIZE=5
    MAX_LOAD=100
    TOTAL_STEPS=$((MAX_LOAD / STEP_SIZE))

    for ((k = 0; k < $TOTAL_STEPS ; k++))
    do
        echo -n "[ "

        for ((i = 0 ; i < k; i++))
        do 
            echo -n "#"
        done

        for (( j = i ; j < $TOTAL_STEPS ; j++ ))
        do
            echo -n " "
        done

        echo -n " ]"

        STEP=$((k * STEP_SIZE))
        echo -ne " ${STEP} %\r"

        R=$(( RANDOM % 4 ))
        DELAY=$(( R * $1 ))
        sleep ${DELAY}s

        echo -ne "\033[K"
        
        if [ DONE == true ]
        then
            break
        fi
    done
}

function CHECK_COMPLETE {
    if [ -e *.${1} ]
    then
        DONE=true
        echo "[ #################### ] 100 %"
        echo
    else
        ERROR "${2}"
    fi
}

function delete {
    if [ -e *.${1} ]
    then
        rm *.${1}
    fi
}

# Remove old files
delete pdf
delete log
delete aux
delete toc
delete lof
delete lot
delete bbl
delete blg
delete out

# pick first markdown the file finds
MD=$(find *.tex)
# remove .md file name
FILE=${MD%.tex}

# check if bibliography exists
# if yes, process it
if [ -e *.bib ] || [ -e *.bibtex ]
then
    DONE=false
    LOADING 0.1 "(1/4) Preparing bibliography" &
    pdflatex ${FILE}.tex >pdf.log &
    wait
    CHECK_COMPLETE pdf "PDF build failed"
    delete pdf
    
    DONE=false
    LOADING 0.05 "(2/4) Processing bibliography" &
    bibtex ${FILE}.aux >bib.log &
    wait
    # check if successful
    CHECK_COMPLETE bib "bibliography build failed"
fi

# convert latex to pdf using pdflatex
DONE=false
LOADING 0.1 "(1/2) Preparing conversion from LaTeX to PDF" &
pdflatex ${FILE}.tex >pdf.log &
wait
CHECK_COMPLETE pdf "PDF build failed"
delete pdf

# pdflatex needs to repeat the process to account for the processing of table of contents and similar environments
DONE=false
LOADING 0.1 "(2/2) Converting LaTeX to PDF" &
pdflatex ${FILE}.tex >pdf.log &
wait
CHECK_COMPLETE pdf "PDF build failed"

# Delete build files generated by pdflatex if they exist
if [ "$2" == "--log" ] || [ "$3" == "--log" ]
then
    mkdir logs
    mv *.log logs/
    "log files are in logs folder"
else
    delete log
fi
if [ "$2" == "--aux" ] || [ "$3" == "--aux" ]
then
    mkdir aux
    mv *.log aux/
    "aux files are in logs folder"
else
    delete aux
    delete out
    delete toc
    delete lof
    delete lot
    delete bbl
    delete blg
fi