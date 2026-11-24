#!/bin/bash
# convertir-libros.sh
#
# Convierte con LaTeXML todos los libros que haya en las subcarpetas de una carpeta.
#
# Uso:
#   convertir-libros.sh [carpeta-con-libros]
#
# Si no se indica carpeta, usa la carpeta actual.
# Debe estar guardado dentro de editorial-latexml (junto a los bindings,
# latexmlpost-es y qed.css): encuentra esa carpeta por sí solo.
#
# Estructura esperada:
#   libros/
#     libro1/  (cualquier-nombre.tex, biblio.bib, ...)
#     libro2/
#
# En cada subcarpeta procesa todos los .tex que tengan \documentclass
# (los demás .tex se consideran capítulos incluidos con \input / \include).

# Carpeta donde vive este script (editorial-latexml)
DIR="$(cd "$(dirname "$0")" && pwd)"

# Carpeta con los libros
RAIZ="$(cd "${1:-.}" 2>/dev/null && pwd)"
if [ -z "$RAIZ" ]; then
  echo "No existe la carpeta: ${1:-.}"
  exit 1
fi

# Convierte un .tex (se ejecuta dentro de la carpeta del libro)
convertir_tex() {
  local tex="$1"
  local base="${tex%.tex}"
  local bibopt=()
  local bib

  # Busca el .bib en \addbibresource{...} (ignora líneas comentadas)
  bib=$(grep -v '^[[:space:]]*%' "$tex" \
        | sed -n 's/.*\\addbibresource{\([^}]*\)}.*/\1/p' | head -n 1)

  # 1) Documento principal: .tex -> .xml
  latexml --dest="${base}.xml" --path="$DIR" "$tex" \
    > "${base}-latexml.log" 2>&1 || return 1

  # 2) Bibliografía: .bib -> .xml (solo si el .tex declara un .bib que existe)
  if [ -n "$bib" ] && [ -f "$bib" ]; then
    latexml --dest="${base}-refs.xml" --path="$DIR" "$bib" \
      > "${base}-latexml-bib.log" 2>&1 || return 1
    bibopt=(--bibliography="${base}-refs.xml")
  fi

  # 3) .xml -> .html (la bibliografía se pasa aquí, a latexmlpost-es)
  "$DIR/latexmlpost-es" --dest="${base}.html" \
          "${bibopt[@]}" "${base}.xml" \
    > "${base}-latexmlpost.log" 2>&1 || return 1
}

ok=0
fallos=0

for carpeta in "$RAIZ"/*/; do
  [ -d "$carpeta" ] || continue
  nombre="$(basename "$carpeta")"

  # .tex principales: los que contienen \documentclass
  principales=$(cd "$carpeta" && grep -l '^[[:space:]]*\\documentclass' ./*.tex 2>/dev/null | sed 's|^\./||')

  if [ -z "$principales" ]; then
    echo "--- $nombre: sin .tex principal, salto"
    continue
  fi

  for tex in $principales; do
    echo "=== $nombre/$tex ==="
    if ( cd "$carpeta" && convertir_tex "$tex" ); then
      echo "    OK"
      ok=$((ok + 1))
    else
      echo "    ERROR (revisa los .log en $nombre/)"
      fallos=$((fallos + 1))
    fi
  done
done

echo
echo "Terminado: $ok correctos, $fallos con error."
