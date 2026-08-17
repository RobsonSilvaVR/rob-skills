#!/usr/bin/env bash
# Consulta as pendências de PRs do usuário no GitHub e emite JSON normalizado.
# Réplica das três regras da aba Pendências do DevInbox (PrStateRepository.GetPendingItems).
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QUERY_FILE="$SCRIPT_DIR/../pending.graphql"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERRO: GitHub CLI (gh) não encontrado no PATH. Instale de https://cli.github.com/ e rode 'gh auth login'." >&2
  exit 1
fi

if [[ ! -f "$QUERY_FILE" ]]; then
  echo "ERRO: query não encontrada em $QUERY_FILE." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERRO: gh não está autenticado. Rode 'gh auth login' ou defina GH_TOKEN/GITHUB_TOKEN." >&2
  exit 1
fi

read -r -d '' JQ_FILTER <<'JQ'
def trunc:
  ((. // "") | gsub("\\s+"; " ") | sub("^ +"; "") | sub(" +$"; "")) as $s
  | if $s == "" then null
    elif ($s | length) > 140 then ($s[0:140] + "…")
    else $s end;

def ordena: sort_by(.repo, -.pr);

.data as $d
| ($d.mine.nodes | map(select(.number != null))) as $prs
| {
    login: $d.viewer.login,
    total: $d.mine.issueCount,
    varridos: ($prs | length),
    temMais: $d.mine.pageInfo.hasNextPage,
    custo: $d.rateLimit.cost,
    restante: $d.rateLimit.remaining,
    itens: (
      ([ $prs[]
         | . as $pr
         | $pr.reviewThreads.nodes[]?
         | select(.isResolved == false)
         | (.comments.nodes[0] // {}) as $c
         | { tipo: "Conversa",
             repo: $pr.repository.nameWithOwner,
             pr: $pr.number,
             titulo: $pr.title,
             detalhe: ($c.bodyText | trunc),
             url: (if ($c.url // "") == "" then $pr.url else $c.url end),
             autor: $c.author.login,
             isDraft: $pr.isDraft,
             baseRefName: $pr.baseRefName,
             updatedAt: $pr.updatedAt }
       ] | ordena)
      +
      ([ $prs[]
         | select(.mergeable == "CONFLICTING")
         | { tipo: "Conflito",
             repo: .repository.nameWithOwner,
             pr: .number,
             titulo: .title,
             detalhe: "Conflito com a base",
             url: .url,
             autor: null,
             isDraft: .isDraft,
             baseRefName: .baseRefName,
             updatedAt: .updatedAt }
       ] | ordena)
      +
      ([ $prs[]
         | . as $pr
         | ($pr.commits.nodes[0].commit.statusCheckRollup // {}) as $rollup
         | select($rollup.state == "FAILURE" or $rollup.state == "ERROR")
         | ([ $rollup.contexts.nodes[]?
              | select(
                  (.__typename == "CheckRun"
                   and (.conclusion == "FAILURE" or .conclusion == "TIMED_OUT" or .conclusion == "STARTUP_FAILURE"))
                  or (.__typename == "StatusContext"
                      and (.state == "FAILURE" or .state == "ERROR")))
              | (.name // .context) ]) as $falhas
         | { tipo: "Checks",
             repo: $pr.repository.nameWithOwner,
             pr: $pr.number,
             titulo: $pr.title,
             detalhe: (if ($falhas | length) > 0
                       then "CI/checks falhando: " + ($falhas | join(", "))
                       else "CI/checks falhando" end),
             url: ($pr.url + "/checks"),
             autor: null,
             isDraft: $pr.isDraft,
             baseRefName: $pr.baseRefName,
             updatedAt: $pr.updatedAt }
       ] | ordena)
    )
  }
JQ

OUT=$(gh api graphql \
  -F query=@"$QUERY_FILE" \
  -f qMine='is:pr is:open author:@me archived:false sort:updated-desc' \
  --jq "$JQ_FILTER" 2>&1)
STATUS=$?

if [[ $STATUS -ne 0 ]]; then
  echo "ERRO: falha ao consultar o GitHub GraphQL (exit $STATUS):" >&2
  echo "$OUT" >&2
  exit "$STATUS"
fi

echo "$OUT"
