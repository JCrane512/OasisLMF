#!/bin/bash
SCRIPT=$(readlink -f "$0") && cd $(dirname "$SCRIPT")

# --- Script Init ---
set -euET -o pipefail
shopt -s inherit_errexit 2>/dev/null || echo "WARNING: Unable to set inherit_errexit. Possibly unsupported by this shell, Subprocess failures may not be detected."

mkdir -p log
rm -R -f log/*

# --- Setup run dirs ---

find output -type f -not -name '*summary-info*' -not -name '*.json' -exec rm -R -f {} +

rm -R -f fifo/*
rm -R -f work/*
mkdir work/kat/


mkfifo fifo/il_P8

mkfifo fifo/il_S1_summary_P8
mkfifo fifo/il_S1_pltcalc_P8



# --- Do insured loss computes ---
pltcalc -H < fifo/il_S1_pltcalc_P8 > work/kat/il_S1_pltcalc_P8 & pid1=$!
tee < fifo/il_S1_summary_P8 fifo/il_S1_pltcalc_P8 > /dev/null & pid2=$!
summarycalc -m -f  -1 fifo/il_S1_summary_P8 < fifo/il_P8 &

eve 8 20 | getmodel | gulcalc -S100 -L100 -r -i - | fmcalc -a2 > fifo/il_P8  &

wait $pid1 $pid2


# --- Do insured loss kats ---

kat work/kat/il_S1_pltcalc_P8 > output/il_S1_pltcalc.csv & kpid1=$!
wait $kpid1

