#!/usr/bin/env bash

if [ ${UID} -eq 0 ]; then
  DEST_DIR="/usr/share/icons"
else
  DEST_DIR="${HOME}/.local/share/icons"
fi

readonly SRC_DIR="$(dirname -- "${BASH_SOURCE[0]:-$0}")"
[[ -n "$CACHED_THEME_FILE" ]] || CACHED_THEME_FILE="${PERSONAL_STATE_DIR}/injected-theme.json"

readonly DEFAULT_NAME="fluent"

usage() {
cat << EOF
Usage: $0 [OPTION] | COLOR

OPTIONS:
  -d, --dest               Specify theme destination directory (Default: $HOME/.local/share/icons)
  -n, --name               Specify theme name (Default: fluent)
  -h, --help               Show this help
  -c, --cached-theme

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
  local accent mode
  IFS=$'\n' read -r -d $'\0' accent mode < <(jq -r '"\(.color.secondary)\n\(.info.mode)"' "$CACHED_THEME_FILE")

  local -r THEME_NAME="${NAME}"
  local -r THEME_DIR="${DEST_DIR}/${THEME_NAME}"

  if [[ -d "${THEME_DIR}" ]]; then
    local old_accent old_mode
    IFS=$'\n' read -r -d $'\0' old_accent old_mode < <(jq -r '"\(.accent)\n\(.mode)"' "$DEST_DIR/$THEME_NAME/theme" 2>/dev/null)

    echo "$accent $mode | $old_accent $old_mode"
    if [[ "$accent $mode" != "$old_accent $old_mode" ]]; then
        rm -r "${THEME_DIR}"
    else
        echo "Theme is already installed" && exit 0
    fi
  fi

  echo "Installing '${THEME_NAME}'..."

  install -d "${THEME_DIR}"

  install -m644 "${SRC_DIR}/src/index.theme"                                     "${THEME_DIR}"

  # Update the name in index.theme
  sed -i "s/%NAME%/${THEME_NAME//-/ }/g"                                         "${THEME_DIR}/index.theme"

  # Base icons
  cp -r "${SRC_DIR}"/src/{16,22,24,32,256,scalable,symbolic}                     "${THEME_DIR}"

  # Light mode icons
  if [[ "$mode" != light ]]; then
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

  if [[ "$accent" =~ ''^([[:xdigit:]]{6})$ ]]; then
    for sub in apps places; do
      safe_sed_replace "#198ee6" "#$accent"                                      "${THEME_DIR}/scalable/${sub}/*.svg"
    done
  else
    accent="198ee6"
  fi

  if [[ "$mode" != "light" ]] && [[ "$mode" != "dark" ]]; then
      mode="light"
  fi

  cp -r "${SRC_DIR}"/links/{16,22,24,32,256,scalable,symbolic}                   "${THEME_DIR}"

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

  printf "\
{
    \"accent\": \"$accent\",
    \"mode\": \"$mode\"
}" > "$THEME_DIR/theme"

  gtk-update-icon-cache "${THEME_DIR}"
}

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
  -c|--cached-theme)
      CACHED_THEME_FILE="$2"
      shift
      ;;
    *)
      echo "ERROR: Unrecognized installation option '${1}'."
      echo "Try '${0} --help' for more information."
      exit 1
  esac

  shift
done

: "${NAME:="${DEFAULT_NAME}"}"

[[ -n "$CACHED_THEME_FILE" ]] || (echo "ERROR: '--cached-theme' was never set." 1>&2 && exit 1)
install_theme
