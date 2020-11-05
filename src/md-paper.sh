#!/bin/ksh

PROGRAM_NAME="md-paper"
ROOT_DIRECTORY="/usr/local/${PROGRAM_NAME}"

# gives option to update without reinstalling
if [ $1 = "update" ]
then
  cd $ROOT_DIRECTORY
  sudo git fetch origin master
  sudo git reset --hard origin/master
  exit 0
fi

# uninstall everything
if [ $1 = "uninstall" ]
then
  cd /usr/local
  sudo rm bin/md-paper
  sudo rm -rf md-paper
  exit 0
fi

DOCUMENT=$1
PROJECT_DIRECTORY=$(PWD)
BUILD_FOLDER="build"

function error {
  echo $1
  exit 1
}

function loading {
  echo
  echo "$2"
  
  STEP_SIZE=2
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
    echo -n " ] "
    
    STEP=$((k * STEP_SIZE))
    echo -n "${STEP} %" $'\r'

    R=$(( RANDOM % 10 ))
    DELAY=$(( R * $1 ))
    sleep ${DELAY}s
  done
}

function pdfGenError {
  error "PDF build failed"
}

# Remove old files
if [ -e ${DOCUMENT}.pdf ]
then
  rm ${DOCUMENT}.pdf
fi
if [ -e ${DOCUMENT}.tex ]
then
  rm ${DOCUMENT}.tex
fi

mkdir build

# convert from md to tex using pandoc
loading 0.01 "Converting Markdown to LaTeX"
pandoc -f markdown ${DOCUMENT}.md --template=${ROOT_DIRECTORY}/src/template.tex -t latex -o ${BUILD_FOLDER}/${DOCUMENT}.tex

cd $BUILD_FOLDER

# check if successful
if [ -e *.tex ]
then
  echo "[ ################################################## ] 100 %"
else
  error "An error occurred while converting Markdown to LaTeX"
fi

# check if bibliography exists
# if yes, process it
if [ -e *.bib ] || [ -e *.bibtex ]
then
  loading 0.03 "Preparing bibliography" &
  pdflatex ${DOCUMENT}.tex >pdf.log
  if [ -e ${DOCUMENT}.pdf ]
  then
    echo "[ ################################################## ] 100 % "
    rm ${DOCUMENT}.pdf
  else
    pdfGenError
  fi
  loading 0.01 "Processing bibliography" &
  bibtex ${DOCUMENT}.aux >bib.log
  if [ -e ${DOCUMENT}.pdf ]
  then
    echo "[ ################################################## ] 100 %"
    rm ${DOCUMENT}.pdf
  else
    pdfGenError
  fi
fi

# convert latex to pdf using pdflatex
loading 0.02 "Preparing Conversion from LaTeX to PDF" &
pdflatex ${DOCUMENT}.tex >pdf.log
if [ -e ${DOCUMENT}.pdf ]
then
  rm ${DOCUMENT}.pdf
  echo "[ ################################################## ] 100 %"
else
  pdfGenError
fi
loading 0.02 "Converting LaTeX to PDF" &
pdflatex ${DOCUMENT}.tex >pdf.log
if [ -e ${DOCUMENT}.pdf ]
then
  mv ${DOCUMENT}.pdf $PROJECT_DIRECTORY
  echo "[ ################################################## ] 100 %"
else
  pdfGenError
fi

# Delete auxiliary build files generated by pdflatex if they exist
if [ "$2" = "latex" ] || [ "$3" = "latex" ] || [ "$4" = "latex" ]
then
  latex=true
fi

if [ "$2" = "log" ] || [ "$3" = "log" ] || [ "$4" = "log" ]
then
  log=true
fi

if [ "$2" = "LOG" ] || [ "$3" = "LOG" ] || [ "$4" = "LOG" ]
then
  log=true
  toc=true
  aux=true
  bib=true
  lof=true
  lot=true
fi
if [ "$latex" = true ] || [ "$log" = true ] || [ "$LOG" = true ]
then
  echo "Kept the following files in '/build/':"
fi

if [ "$latex" = true ]
then
  echo " - ${DOCUMENT}.tex"
else
  if [ -e ${DOCUMENT}.tex ]
  then
    rm ${DOCUMENT}.tex
  fi
fi
  
if [ "$log" = true ]
then
  echo " - ${DOCUMENT}.log"
  echo " - pdf.log"
else
  if [ -e ${DOCUMENT}.log ]
  then
    rm ${DOCUMENT}.log
    rm pdf.log
  fi
fi

if [ "$aux" = true ]
then
  echo " - ${DOCUMENT}.aux"
  echo " - ${DOCUMENT}.out"
else
  if [ -e ${DOCUMENT}.aux ]
  then
    rm ${DOCUMENT}.aux
  fi
  if [ -e ${DOCUMENT}.out ]
  then
    rm ${DOCUMENT}.out
  fi
fi

if [ "$toc" = true ]
then
  echo " - ${DOCUMENT}.toc"
else
  if [ -e ${DOCUMENT}.toc ]
  then
    rm ${DOCUMENT}.toc
  fi
fi

if [ "$bib" = true ]
then
  echo " - ${DOCUMENT}.bib"
else
  # Delete aux bibliography build files if a bibliography exists
  if [ -e *.bib ] || [ -e *.bibtex ]
  then
    rm ${DOCUMENT}.bbl
    rm ${DOCUMENT}.blg
    rm bib.log
  fi
fi

if [ "$lof" = true ]
then
  echo " - ${DOCUMENT}.lof"
else
  if [ -e ${DOCUMENT}.lof ]
  then
    rm ${DOCUMENT}.lof
  fi
fi

if [ "$lot" = true ]
then
  echo " - ${DOCUMENT}.lot"
else
  if [ -e ${DOCUMENT}.lot ]
  then
    rm ${DOCUMENT}.lot
  fi
fi

if [ "$texput" = true ]
then
  echo " - texput.log"
else
  # Delete texput.log if exists
  if [ -e texput.log ]
  then
    rm texput.log
  fi
fi



echo
exit 0
