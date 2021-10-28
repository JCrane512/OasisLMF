#!/usr/bin/env -S bash -euET -o pipefail -O inherit_errexit
SCRIPT=$(readlink -f "$0") && cd $(dirname "$SCRIPT")

# --- Script Init ---

mkdir -p log
rm -R -f log/*

# --- Setup run dirs ---

find output -type f -not -name '*summary-info*' -not -name '*.json' -exec rm -R -f {} +
mkdir output/full_correlation/

rm -R -f fifo/*
mkdir fifo/full_correlation/
rm -R -f work/*
mkdir work/kat/
mkdir work/full_correlation/
mkdir work/full_correlation/kat/


mkfifo fifo/full_correlation/gul_fc_P10

mkfifo fifo/il_P10

mkfifo fifo/il_S1_summary_P10
mkfifo fifo/il_S1_eltcalc_P10

mkfifo fifo/full_correlation/il_P10

mkfifo fifo/full_correlation/il_S1_summary_P10
mkfifo fifo/full_correlation/il_S1_eltcalc_P10



# --- Do insured loss computes ---
eltcalc -s < fifo/il_S1_eltcalc_P10 > work/kat/il_S1_eltcalc_P10 & pid1=$!
tee < fifo/il_S1_summary_P10 fifo/il_S1_eltcalc_P10 > /dev/null & pid2=$!
summarycalc -m -f  -1 fifo/il_S1_summary_P10 < fifo/il_P10 &

# --- Do insured loss computes ---
eltcalc -s < fifo/full_correlation/il_S1_eltcalc_P10 > work/full_correlation/kat/il_S1_eltcalc_P10 & pid3=$!
tee < fifo/full_correlation/il_S1_summary_P10 fifo/full_correlation/il_S1_eltcalc_P10 > /dev/null & pid4=$!
summarycalc -m -f  -1 fifo/full_correlation/il_S1_summary_P10 < fifo/full_correlation/il_P10 &

fmcalc -a2 < fifo/full_correlation/gul_fc_P10 > fifo/full_correlation/il_P10 &
eve 10 20 | getmodel | gulcalc -S100 -L100 -r -j fifo/full_correlation/gul_fc_P10 -a1 -i - | fmcalc -a2 > fifo/il_P10  &

wait $pid1 $pid2 $pid3 $pid4


# --- Do insured loss kats ---

kat -s work/kat/il_S1_eltcalc_P10 > output/il_S1_eltcalc.csv & kpid1=$!

# --- Do insured loss kats for fully correlated output ---

kat -s work/full_correlation/kat/il_S1_eltcalc_P10 > output/full_correlation/il_S1_eltcalc.csv & kpid2=$!
wait $kpid1 $kpid2
