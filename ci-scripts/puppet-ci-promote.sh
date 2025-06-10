set -e
delorean_components_url="$(curl -s ${delorean_url} | awk -F= '/baseurl/ {print $2}')"

# Setup a virtual env for dlrnapi
python3 -m venv --system-site-packages dlrnapi_venv
source dlrnapi_venv/bin/activate
pip install -U dlrnapi_client shyaml

: ${DLRNAPI_USERNAME:="ciuser"}
: ${PROMOTE_TO:="${PROMOTE_TARGET}"}
: ${DLRNAPI_URL:="${delorean_api_url}"}
: ${MAX_RETRIES:=3}
: ${DELAY:=10}

for component_url in ${delorean_components_url}; do
    curl -sLo commit.yaml ${component_url}/commit.yaml
    COMMIT_HASH=$(shyaml get-value commits.0.commit_hash < ./commit.yaml)
    DISTRO_HASH=$(shyaml get-value commits.0.distro_hash < ./commit.yaml)

    # Assign label to the specific hash using the DLRN API with retries
    attempt=1
    while [ $attempt -le $MAX_RETRIES ]; do
        echo "Attempt $attempt of $MAX_RETRIES for component ${component_url}..."
        if dlrnapi --url "$DLRNAPI_URL" \
            --username "$DLRNAPI_USERNAME" \
            repo-promote \
            --commit-hash "$COMMIT_HASH" \
            --distro-hash "$DISTRO_HASH" \
            --promote-name "$PROMOTE_TO"; then
            echo "Promotion succeeded for component ${component_url}"
            break
        else
            echo "dlrnapi command failed, retrying..."
            if [ $attempt -eq $MAX_RETRIES ]; then
                echo "Max retries reached for component ${component_url}. Exiting."
                exit 1
            fi
            echo "Waiting $DELAY seconds before retrying..."
            sleep $DELAY
            attempt=$((attempt + 1))
        fi
    done
done
