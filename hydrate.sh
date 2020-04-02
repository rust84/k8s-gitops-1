#!/usr/bin/env bash

set -uxeo pipefail

HELM="docker-compose run --rm helm"

CERT_MANAGER_CHART="jetstack"
CERT_MANAGER_REPO="https://charts.jetstack.io"

STABLE_CHART="stable"
STABLE_REPO="https://kubernetes-charts.storage.googleapis.com"

_template-chart() {
	local VERSION
	VERSION=$(cat "config/charts/${NAME}/.version")

	echo "Generating helm chart for $1"
	helm template "${2}/${1}" \
		--values="config/charts/${1}/values.yaml" \
		--output-dir "namespaces/${1}" \
		--name-template="${1}" \
		--version "${VERSION}"
}

_add-chart-repo() {
	helm repo add "${1}" "${2}"
}

_clean() {
	echo "Removing stale helm charts, kube config and purging orphaned docker networks"
	rm -rf namespaces/"${1}"/"${1}"
	docker-compose down --remove-orphans 2>/dev/null
}

_hydrate() {
	local NAME=$1
	local CHART_NAME=$2
	local CHART_REPO=$3
	_clean "${NAME}"
	_add-chart-repo "${CHART_NAME}" "${CHART_REPO}"
	_template-chart "${NAME}" "${CHART_NAME}"
}

[[ "$1" == "cert-manager" ]] && _hydrate "$1" "${CERT_MANAGER_CHART}" "${CERT_MANAGER_REPO}" 
[[ "$1" == "sealed-secrets" ]] && _hydrate "$1" "${STABLE_CHART}" "${STABLE_REPO}" 
