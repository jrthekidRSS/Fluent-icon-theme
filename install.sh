#!/usr/bin/env bash

if [ ${UID} -eq 0 ]; then
  DEST_DIR="/usr/share/icons"
else
  DEST_DIR="${HOME}/.local/share/icons"
fi

readonly SRC_DIR=$(cd $(dirname $0) && pwd)

readonly COLOR_VARIANTS=("standard" "green" "grey" "orange" "pink" "purple" "red" "yellow" "teal")
readonly BRIGHT_VARIANTS=("light" "dark")

readonly DEFAULT_NAME="fluent"

usage() {
cat << EOF
Usage: $0 [OPTION] | COLOR

OPTIONS:
  -d, --dest               Specify theme destination directory (Default: $HOME/.local/share/icons)
  -D, --dark-mode          Install the dark mode variant of the theme
  -n, --name               Specify theme name (Default: fluent)
  -h, --help               Show this help

COLOR VARIANTS:
  standard                 Standard color folder version
  green                    Green color folder version
  grey                     Grey color folder version
  orange                   Orange color folder version
  pink                     Pink color folder version
  purple                   Purple color folder version
  red                      Red color folder version
  yellow                   Yellow color folder version
  teal                     Teal color folder version
  (rrggbb)                 Custom color folder version
                           Enter as valid rgb hexadecimal code
                           You can only define one at a time

  By default, only the standard one is selected.
EOF
}

# Sed replace in-place (ignore if no match)
safe_sed_replace() {
  local from="$1" to="$2" pattern="$3"
  shopt -s nullglob
  local files=( $pattern )
  shopt -u nullglob
  [ "${#files[@]}" -eq 0 ] && return 0
  sed -i "s/${from//\//\\/}/${to//\//\\/}/g" "${files[@]}"
}

install_theme() {
  # Appends a dash if the variables are not empty
  if [[ "$1" != "standard" ]]; then
    local colorprefix="-$1"
  fi

  case "$color" in
    standard)
      theme_color='#198ee6' ;;
    purple)
      theme_color='#dc63ee' ;;
    pink)
      theme_color='#ff5c93' ;;
    red)
      theme_color='#ff6666' ;;
    orange)
      theme_color='#ff9c33' ;;
    yellow)
      theme_color='#ffcb52' ;;
    green)
      theme_color='#67cb6b' ;;
    teal)
      theme_color='#32c8ba' ;;
    grey)
      theme_color='#808080' ;;
    *)
      # Valid hex color code
      theme_color="#${color}"
      colorprefix="-custom" ;;
  esac

  local -r dark_variant="$2"

  local -r THEME_NAME="${NAME}${colorprefix}"
  local -r THEME_DIR="${DEST_DIR}/${THEME_NAME}"

  if [ -d "${THEME_DIR}" ]; then
    rm -r "${THEME_DIR}"
  fi

  echo "Installing '${THEME_NAME}'..."

  install -d "${THEME_DIR}"

  install -m644 "${SRC_DIR}/src/index.theme"                                     "${THEME_DIR}"

  # Update the name in index.theme
  sed -i "s/%NAME%/${THEME_NAME//-/ }/g"                                         "${THEME_DIR}/index.theme"

  # Base icons
  cp -r "${SRC_DIR}"/src/{16,22,24,32,256,scalable,symbolic}                   "${THEME_DIR}"

  # Light mode icons
  if ! $dark_variant; then
    # Change icon color for dark theme
    sed -i "s/#dedede/#363636/g" "${THEME_DIR}"/{16,22,24}/panel/*.svg
  # Dark mode icons
  else
    # Change icon color for dark theme
    sed -i "s/#363636/#dedede/g" "${THEME_DIR}"/{16,22,24,32}/actions/*.svg
    sed -i "s/#363636/#dedede/g" "${THEME_DIR}"/32/{devices,status}/*.svg
    sed -i "s/#363636/#dedede/g" "${THEME_DIR}"/{16,22,24}/{places,devices}/*.svg
    sed -i "s/#363636/#dedede/g" "${THEME_DIR}"/symbolic/{actions,apps,categories,devices,emblems,emotes,mimetypes,places,status}/*.svg
  fi

  if [[ -n "${colorprefix}" ]]; then
    for sub in apps places; do
      safe_sed_replace "#198ee6" "${theme_color}"                              "${THEME_DIR}/scalable/${sub}/*.svg"
    done
  fi

  cp -r "${SRC_DIR}"/links/{16,22,24,32,256,scalable,symbolic}                 "${THEME_DIR}"

  ln -sr "${THEME_DIR}/16"                                                       "${THEME_DIR}/16@2x"
  ln -sr "${THEME_DIR}/22"                                                       "${THEME_DIR}/22@2x"
  ln -sr "${THEME_DIR}/24"                                                       "${THEME_DIR}/24@2x"
  ln -sr "${THEME_DIR}/32"                                                       "${THEME_DIR}/32@2x"
  ln -sr "${THEME_DIR}/256"                                                      "${THEME_DIR}/256@2x"
  ln -sr "${THEME_DIR}/scalable"                                                 "${THEME_DIR}/scalable@2x"

  ln -sr "${THEME_DIR}/16"                                                       "${THEME_DIR}/16@3x"
  ln -sr "${THEME_DIR}/22"                                                       "${THEME_DIR}/22@3x"
  ln -sr "${THEME_DIR}/24"                                                       "${THEME_DIR}/24@3x"
  ln -sr "${THEME_DIR}/32"                                                       "${THEME_DIR}/32@3x"
  ln -sr "${THEME_DIR}/256"                                                      "${THEME_DIR}/256@3x"
  ln -sr "${THEME_DIR}/scalable"                                                 "${THEME_DIR}/scalable@3x"

  gtk-update-icon-cache "${THEME_DIR}"
}

custom_color_set=false
dark_variant=false
color="standard"

while [ $# -gt 0 ]; do
  case "${1}" in
    -d|--dest)
      DEST_DIR="${2}"
      shift
      ;;
    -n|--name)
      NAME="${2}"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -D|--dark-mode)
      dark_variant=true
      ;;
    *)
      # If the argument is a color variant, append it to the colors to be installed
      if [[ " ${COLOR_VARIANTS[*]} " = *" ${1} "* ]] && [[ "${colors[*]}" != *${1}* ]] \
          || [[ "${1}" =~ ''^([[:xdigit:]]{6})$ ]]; then

      # Default name is 'fluent'
        : "${NAME:="${DEFAULT_NAME}"}"
        install_theme
        exit 0
      else
        echo "ERROR: Unrecognized installation option '${1}'."
        echo "Try '${0} --help' for more information."
        exit 1
      fi
  esac
  shift
done
