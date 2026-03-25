#!/usr/bin/env bash

k_render_template() {
  local template_file="$1"
  local id="$2"
  local type="$3"
  local title="$4"
  local scope="$5"
  local tags_csv="$6"
  local created="$7"
  local updated="$8"
  local status="$9"

  [[ -f "$template_file" ]] || k_die "Template not found: $template_file"

  local tags_bracketed
  tags_bracketed="$(k_tags_bracketed "$tags_csv")"

  sed \
    -e "s/{{id}}/$(k_escape_sed_replacement "$id")/g" \
    -e "s/{{type}}/$(k_escape_sed_replacement "$type")/g" \
    -e "s/{{title}}/$(k_escape_sed_replacement "$title")/g" \
    -e "s#{{scope}}#$(k_escape_sed_replacement "$scope")#g" \
    -e "s/{{tags}}/$(k_escape_sed_replacement "$tags_bracketed")/g" \
    -e "s/{{created}}/$(k_escape_sed_replacement "$created")/g" \
    -e "s/{{updated}}/$(k_escape_sed_replacement "$updated")/g" \
    -e "s/{{status}}/$(k_escape_sed_replacement "$status")/g" \
    "$template_file"
}
