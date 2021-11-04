#!/bin/bash
SCRIPT=$(readlink -f "$0") && cd $(dirname "$SCRIPT")

# --- Script Init ---
set -euET -o pipefail
shopt -s inherit_errexit 2>/dev/null || echo "WARNING: Unable to set inherit_errexit. Possibly unsupported by this shell, Subprocess failures may not be detected."

mkdir -p log
rm -R -f log/*

# --- Setup run dirs ---

find output -type f -not -name '*summary-info*' -not -name '*.json' -exec rm -R -f {} +
mkdir output/full_correlation/

rm -R -f /tmp/%FIFO_DIR%/fifo/*
mkdir /tmp/%FIFO_DIR%/fifo/full_correlation/
rm -R -f work/*
mkdir work/kat/
mkdir work/full_correlation/
mkdir work/full_correlation/kat/

mkdir work/gul_S1_summaryaalcalc
mkdir work/full_correlation/gul_S1_summaryaalcalc

mkfifo /tmp/%FIFO_DIR%/fifo/gul_P2

mkfifo /tmp/%FIFO_DIR%/fifo/gul_S1_summary_P2
mkfifo /tmp/%FIFO_DIR%/fifo/gul_S1_eltcalc_P2
mkfifo /tmp/%FIFO_DIR%/fifo/gul_S1_summarycalc_P2
mkfifo /tmp/%FIFO_DIR%/fifo/gul_S1_pltcalc_P2

mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_P2

mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summary_P2
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_eltcalc_P2
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summarycalc_P2
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_pltcalc_P2



# --- Do ground up loss computes ---
eltcalc -s < /tmp/%FIFO_DIR%/fifo/gul_S1_eltcalc_P2 > work/kat/gul_S1_eltcalc_P2 & pid1=$!
summarycalctocsv -s < /tmp/%FIFO_DIR%/fifo/gul_S1_summarycalc_P2 > work/kat/gul_S1_summarycalc_P2 & pid2=$!
pltcalc -s < /tmp/%FIFO_DIR%/fifo/gul_S1_pltcalc_P2 > work/kat/gul_S1_pltcalc_P2 & pid3=$!
tee < /tmp/%FIFO_DIR%/fifo/gul_S1_summary_P2 /tmp/%FIFO_DIR%/fifo/gul_S1_eltcalc_P2 /tmp/%FIFO_DIR%/fifo/gul_S1_summarycalc_P2 /tmp/%FIFO_DIR%/fifo/gul_S1_pltcalc_P2 work/gul_S1_summaryaalcalc/P2.bin > /dev/null & pid4=$!
summarycalc -m -i  -1 /tmp/%FIFO_DIR%/fifo/gul_S1_summary_P2 < /tmp/%FIFO_DIR%/fifo/gul_P2 &

# --- Do ground up loss computes ---
eltcalc -s < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_eltcalc_P2 > work/full_correlation/kat/gul_S1_eltcalc_P2 & pid5=$!
summarycalctocsv -s < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summarycalc_P2 > work/full_correlation/kat/gul_S1_summarycalc_P2 & pid6=$!
pltcalc -s < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_pltcalc_P2 > work/full_correlation/kat/gul_S1_pltcalc_P2 & pid7=$!
tee < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summary_P2 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_eltcalc_P2 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summarycalc_P2 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_pltcalc_P2 work/full_correlation/gul_S1_summaryaalcalc/P2.bin > /dev/null & pid8=$!
summarycalc -m -i  -1 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summary_P2 < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_P2 &

eve 2 2 | getmodel | gulcalc -S0 -L0 -r -j /tmp/%FIFO_DIR%/fifo/full_correlation/gul_P2 -a1 -i - > /tmp/%FIFO_DIR%/fifo/gul_P2  &

wait $pid1 $pid2 $pid3 $pid4 $pid5 $pid6 $pid7 $pid8


# --- Do ground up loss kats ---

kat -s work/kat/gul_S1_eltcalc_P2 > output/gul_S1_eltcalc.csv & kpid1=$!
kat work/kat/gul_S1_pltcalc_P2 > output/gul_S1_pltcalc.csv & kpid2=$!
kat work/kat/gul_S1_summarycalc_P2 > output/gul_S1_summarycalc.csv & kpid3=$!

# --- Do ground up loss kats for fully correlated output ---

kat -s work/full_correlation/kat/gul_S1_eltcalc_P2 > output/full_correlation/gul_S1_eltcalc.csv & kpid4=$!
kat work/full_correlation/kat/gul_S1_pltcalc_P2 > output/full_correlation/gul_S1_pltcalc.csv & kpid5=$!
kat work/full_correlation/kat/gul_S1_summarycalc_P2 > output/full_correlation/gul_S1_summarycalc.csv & kpid6=$!
wait $kpid1 $kpid2 $kpid3 $kpid4 $kpid5 $kpid6

