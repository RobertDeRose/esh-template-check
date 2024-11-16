#!/bin/bash
set -euo pipefail

GEN_DIR="esh_template_output"; mkdir -p "${GEN_DIR}"
KEEP_GENERATED=false
VERBOSE=false
ERRORS=false
export ESH_SHELL="/bin/bash"

while getopts ':ks:v' OPT; do
	case "$OPT" in
		k) KEEP_GENERATED=true ;;
        s) export ESH_SHELL="${OPTARG}" ;;
		v) VERBOSE=true ;;
		*) echo "$(basename "${0}"): unknown option: -$OPTARG" >&2; exit 1 ;;
	esac
done
shift $(( OPTIND - 1 ))

for file in "$@"; do
    # Extract YAML front matter (strip leading # and spaces)
    yaml="$(awk '/^<%# --- *-?%>$/{flag=!flag; next} flag {sub(/^<%# /, ""); sub(/ *-?%>$/, ""); print}' "$file")"

    if [[ -z "$yaml" ]] ; then
        "${VERBOSE}" && {
            echo "Skipping... $file"
            echo " - No front matter defined"
        } >&2
        continue
    fi

    # Parse test cases and shellcheck arguments
    test_cases=$(yq '.test_cases | select( . != null )' <<< "${yaml}")
    read -ra check_args <<< "$(yq '.check_args | select( . != null )' <<< "${yaml}")"

    if [[ -z "${test_cases}" || "${test_cases}" == "null" ]]; then
        "${VERBOSE}" && {
            echo "Skipping... No test cases found in $file."
            echo "  - No test_cases defined"
        } >&2
        continue
    fi

    count=0
    for i in $(yq 'keys | .[]' <<< "${test_cases}"); do
        # Extract environment variables for this test case
        vars=()
        while IFS=": " read -r key value; do
            vars+=("${key}=${value}")
        done < <(yq ".[$i]" <<< "${test_cases}")

        # Generate preprocessed file for this test case
        case="$((i + 1))"
        test_file="$GEN_DIR/$(basename "$file")_test_${case}.sh"
        esh "$file" "${vars[@]}" > "$test_file"

        # Run shellcheck if arguments are provided
        if [[ -n "${check_args[*]}" ]]; then
            args=("-Calways" "${check_args[@]}")
            if ! shellcheck "${args[@]}" "$test_file" | sed -E "s|(${test_file}) line ([0-9]+):|\1:\2|"; then
                ERRORS=true
            fi
        else
            [[ "$((++count))" -eq 1 ]] && "${VERBOSE}" && {
                echo "Skipping shellcheck for ${file} (no check_args provided)."
            } >&2
        fi
    done
done

"${ERRORS}" && exit 1

if ! "${KEEP_GENERATED}"; then
    rm -rf "${GEN_DIR}"
fi
