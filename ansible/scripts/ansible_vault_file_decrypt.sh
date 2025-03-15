default_dec_ext=".dec"

while getopts f:x:d: flag
do
  case "${flag}" in
    f) vfile=${OPTARG};;
    x) vext=${OPTARG};;
    d) vdir=${OPTARG};; 
  esac
done

# Check if a file exists
check_file (){
  if [ -f $1 ]; then 
    echo "OK : "$(stat -c '%w' $1 | awk '{print $1" "$2}' | cut -d'.' -f1)", $1"
    return 0
  else
    echo "Erreur : (fichier introuvable) $1"
    return 1
  fi
}

# Find a passfile
ensure_passfile (){
    if ! check_file $1; then
        echo "Erreur : (fichier introuvable) $1"
    else
        PASSWORD=$(cat $1)
        if [ "$2" != "$PASSWORD" ]; then
          mv $1 $(dirname $1)$(date +"%Y%m%d%H%M%S")$(basename $1).bak
          echo $2 > $1
          chmod 600 $1
        fi
    fi
    # echo $PASSWORD
}

#Main
dec_ext="${vext:-${default_dec_ext}}"
PASSWORD=$(pwgen 30 1)
PASSPATH="${vdir:-.}"
VAULTFILE="${vfile:-$PASSPATH/main.yml}"
FILENAME=$(basename "${VAULTFILE}")
if check_file $PASSPATH/.$FILENAME.pass > /dev/null 2>&1; then PASSWORD=$(cat $PASSPATH/.$FILENAME.pass); fi
ensure_passfile $PASSPATH/.$FILENAME.pass $PASSWORD

ansible-vault decrypt "${VAULTFILE}" --vault-id "${FILENAME%.*}"@$PASSPATH/.$FILENAME.pass --output "${VAULTFILE}${dec_ext}"


        
