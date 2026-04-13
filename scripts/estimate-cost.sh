#!/usr/bin/env bash
# estimate-cost.sh — reads agent definition files and prints expected cost
# Usage: estimate-cost.sh [--cache-rate 0.4] [--batch] <agent-file.md> [<agent-file.md> ...]
# Pricing: Opus $5/$25, Sonnet $3/$15, Haiku $1/$5 per M tokens (April 2026)

set -euo pipefail

CACHE_RATE="0.4"
BATCH="0"
AGENTS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cache-rate) CACHE_RATE="$2"; shift 2 ;;
    --batch) BATCH="1"; shift ;;
    -h|--help)
      echo "usage: estimate-cost.sh [--cache-rate 0.4] [--batch] <agent-file.md>..."
      exit 0
      ;;
    *) AGENTS+=("$1"); shift ;;
  esac
done

if [[ ${#AGENTS[@]} -eq 0 ]]; then
  echo "usage: estimate-cost.sh [--cache-rate 0.4] [--batch] <agent-file.md>..." >&2
  exit 2
fi

# Pricing per 1M tokens
opus_in="5.00";   opus_out="25.00"
sonnet_in="3.00"; sonnet_out="15.00"
haiku_in="1.00";  haiku_out="5.00"

BATCH_MULT="1.0"
[[ "$BATCH" == "1" ]] && BATCH_MULT="0.5"

total="0"
opus_tokens=0
sonnet_tokens=0
haiku_tokens=0

for AGENT in "${AGENTS[@]}"; do
  if [[ ! -f "$AGENT" ]]; then
    echo "skip: $AGENT not found" >&2
    continue
  fi

  MODEL=$(awk '/^---$/{c++; if(c==2) exit; next} c==1 && /^model:/{sub(/^model:[[:space:]]*/,""); gsub(/["'"'"']/,""); print; exit}' "$AGENT")
  LINES=$(wc -l < "$AGENT")
  # rough proxy: 120 tokens per line of agent definition (input context)
  INPUT_TOKENS=$((LINES * 120))
  # flat output assumption
  OUTPUT_TOKENS=800

  case "$MODEL" in
    opus)   IN_RATE="$opus_in";   OUT_RATE="$opus_out";   opus_tokens=$((opus_tokens + INPUT_TOKENS + OUTPUT_TOKENS)) ;;
    sonnet) IN_RATE="$sonnet_in"; OUT_RATE="$sonnet_out"; sonnet_tokens=$((sonnet_tokens + INPUT_TOKENS + OUTPUT_TOKENS)) ;;
    haiku)  IN_RATE="$haiku_in";  OUT_RATE="$haiku_out";  haiku_tokens=$((haiku_tokens + INPUT_TOKENS + OUTPUT_TOKENS)) ;;
    *)      echo "skip: unknown model '$MODEL' in $AGENT" >&2; continue ;;
  esac

  # cost = ((input * (1-cache) * in_rate) + (output * out_rate)) * batch_mult / 1e6
  cost=$(awk -v in_tok="$INPUT_TOKENS" -v out_tok="$OUTPUT_TOKENS" \
             -v in_rate="$IN_RATE" -v out_rate="$OUT_RATE" \
             -v cache="$CACHE_RATE" -v batch="$BATCH_MULT" \
    'BEGIN {
      fresh_in = in_tok * (1 - cache);
      cached_in = in_tok * cache * 0.1;
      in_cost = (fresh_in + cached_in) * in_rate / 1000000;
      out_cost = out_tok * out_rate / 1000000;
      printf "%.6f", (in_cost + out_cost) * batch
    }')
  total=$(awk -v a="$total" -v b="$cost" 'BEGIN {printf "%.6f", a + b}')
done

printf "\nEstimated cost: \$%.4f USD\n" "$total"
printf "  cache rate:     %s\n" "$CACHE_RATE"
printf "  batch discount: %s\n" "$BATCH_MULT"
printf "  Opus tokens:    %d\n" "$opus_tokens"
printf "  Sonnet tokens:  %d\n" "$sonnet_tokens"
printf "  Haiku tokens:   %d\n" "$haiku_tokens"

GATE="${COST_GATE_THRESHOLD:-2.00}"
if awk -v t="$total" -v g="$GATE" 'BEGIN {exit !(t > g)}'; then
  printf "\n*** CONFIRM REQUIRED: estimate \$%.4f > gate \$%s ***\n" "$total" "$GATE"
  exit 3
fi
