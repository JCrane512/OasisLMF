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

rm -R -f work/*
mkdir work/kat/
mkdir work/full_correlation/
mkdir work/full_correlation/kat/

rm -R -f /tmp/%FIFO_DIR%/
mkdir -p /tmp/%FIFO_DIR%/fifo/
mkdir /tmp/%FIFO_DIR%/fifo/full_correlation/
mkdir work/gul_S1_summaryaalcalc
mkdir work/gul_S2_summaryaalcalc
mkdir work/full_correlation/gul_S1_summaryaalcalc
mkdir work/full_correlation/gul_S2_summaryaalcalc
mkdir work/il_S1_summaryaalcalc
mkdir work/il_S2_summaryaalcalc
mkdir work/full_correlation/il_S1_summaryaalcalc
mkdir work/full_correlation/il_S2_summaryaalcalc

mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_fc_P1

mkfifo /tmp/%FIFO_DIR%/fifo/gul_P1

mkfifo /tmp/%FIFO_DIR%/fifo/gul_S1_summary_P1
mkfifo /tmp/%FIFO_DIR%/fifo/gul_S1_eltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/gul_S1_summarycalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/gul_S1_pltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/gul_S2_summary_P1
mkfifo /tmp/%FIFO_DIR%/fifo/gul_S2_eltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/gul_S2_summarycalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/gul_S2_pltcalc_P1

mkfifo /tmp/%FIFO_DIR%/fifo/il_P1

mkfifo /tmp/%FIFO_DIR%/fifo/il_S1_summary_P1
mkfifo /tmp/%FIFO_DIR%/fifo/il_S1_eltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/il_S1_summarycalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/il_S1_pltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/il_S2_summary_P1
mkfifo /tmp/%FIFO_DIR%/fifo/il_S2_eltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/il_S2_summarycalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/il_S2_pltcalc_P1

mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_P1

mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summary_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_eltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summarycalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_pltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_summary_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_eltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_summarycalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_pltcalc_P1

mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/il_P1

mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_summary_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_eltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_summarycalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_pltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_summary_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_eltcalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_summarycalc_P1
mkfifo /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_pltcalc_P1



# --- Do insured loss computes ---

eltcalc < /tmp/%FIFO_DIR%/fifo/il_S1_eltcalc_P1 > work/kat/il_S1_eltcalc_P1 & pid1=$!
summarycalctocsv < /tmp/%FIFO_DIR%/fifo/il_S1_summarycalc_P1 > work/kat/il_S1_summarycalc_P1 & pid2=$!
pltcalc < /tmp/%FIFO_DIR%/fifo/il_S1_pltcalc_P1 > work/kat/il_S1_pltcalc_P1 & pid3=$!
eltcalc < /tmp/%FIFO_DIR%/fifo/il_S2_eltcalc_P1 > work/kat/il_S2_eltcalc_P1 & pid4=$!
summarycalctocsv < /tmp/%FIFO_DIR%/fifo/il_S2_summarycalc_P1 > work/kat/il_S2_summarycalc_P1 & pid5=$!
pltcalc < /tmp/%FIFO_DIR%/fifo/il_S2_pltcalc_P1 > work/kat/il_S2_pltcalc_P1 & pid6=$!


tee < /tmp/%FIFO_DIR%/fifo/il_S1_summary_P1 /tmp/%FIFO_DIR%/fifo/il_S1_eltcalc_P1 /tmp/%FIFO_DIR%/fifo/il_S1_summarycalc_P1 /tmp/%FIFO_DIR%/fifo/il_S1_pltcalc_P1 work/il_S1_summaryaalcalc/P1.bin > /dev/null & pid7=$!
tee < /tmp/%FIFO_DIR%/fifo/il_S2_summary_P1 /tmp/%FIFO_DIR%/fifo/il_S2_eltcalc_P1 /tmp/%FIFO_DIR%/fifo/il_S2_summarycalc_P1 /tmp/%FIFO_DIR%/fifo/il_S2_pltcalc_P1 work/il_S2_summaryaalcalc/P1.bin > /dev/null & pid8=$!

summarycalc -m -f  -1 /tmp/%FIFO_DIR%/fifo/il_S1_summary_P1 -2 /tmp/%FIFO_DIR%/fifo/il_S2_summary_P1 < /tmp/%FIFO_DIR%/fifo/il_P1 &

# --- Do ground up loss computes ---

eltcalc < /tmp/%FIFO_DIR%/fifo/gul_S1_eltcalc_P1 > work/kat/gul_S1_eltcalc_P1 & pid9=$!
summarycalctocsv < /tmp/%FIFO_DIR%/fifo/gul_S1_summarycalc_P1 > work/kat/gul_S1_summarycalc_P1 & pid10=$!
pltcalc < /tmp/%FIFO_DIR%/fifo/gul_S1_pltcalc_P1 > work/kat/gul_S1_pltcalc_P1 & pid11=$!
eltcalc < /tmp/%FIFO_DIR%/fifo/gul_S2_eltcalc_P1 > work/kat/gul_S2_eltcalc_P1 & pid12=$!
summarycalctocsv < /tmp/%FIFO_DIR%/fifo/gul_S2_summarycalc_P1 > work/kat/gul_S2_summarycalc_P1 & pid13=$!
pltcalc < /tmp/%FIFO_DIR%/fifo/gul_S2_pltcalc_P1 > work/kat/gul_S2_pltcalc_P1 & pid14=$!


tee < /tmp/%FIFO_DIR%/fifo/gul_S1_summary_P1 /tmp/%FIFO_DIR%/fifo/gul_S1_eltcalc_P1 /tmp/%FIFO_DIR%/fifo/gul_S1_summarycalc_P1 /tmp/%FIFO_DIR%/fifo/gul_S1_pltcalc_P1 work/gul_S1_summaryaalcalc/P1.bin > /dev/null & pid15=$!
tee < /tmp/%FIFO_DIR%/fifo/gul_S2_summary_P1 /tmp/%FIFO_DIR%/fifo/gul_S2_eltcalc_P1 /tmp/%FIFO_DIR%/fifo/gul_S2_summarycalc_P1 /tmp/%FIFO_DIR%/fifo/gul_S2_pltcalc_P1 work/gul_S2_summaryaalcalc/P1.bin > /dev/null & pid16=$!

summarycalc -m -i  -1 /tmp/%FIFO_DIR%/fifo/gul_S1_summary_P1 -2 /tmp/%FIFO_DIR%/fifo/gul_S2_summary_P1 < /tmp/%FIFO_DIR%/fifo/gul_P1 &

# --- Do insured loss computes ---

eltcalc < /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_eltcalc_P1 > work/full_correlation/kat/il_S1_eltcalc_P1 & pid17=$!
summarycalctocsv < /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_summarycalc_P1 > work/full_correlation/kat/il_S1_summarycalc_P1 & pid18=$!
pltcalc < /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_pltcalc_P1 > work/full_correlation/kat/il_S1_pltcalc_P1 & pid19=$!
eltcalc < /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_eltcalc_P1 > work/full_correlation/kat/il_S2_eltcalc_P1 & pid20=$!
summarycalctocsv < /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_summarycalc_P1 > work/full_correlation/kat/il_S2_summarycalc_P1 & pid21=$!
pltcalc < /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_pltcalc_P1 > work/full_correlation/kat/il_S2_pltcalc_P1 & pid22=$!


tee < /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_summary_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_eltcalc_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_summarycalc_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_pltcalc_P1 work/full_correlation/il_S1_summaryaalcalc/P1.bin > /dev/null & pid23=$!
tee < /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_summary_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_eltcalc_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_summarycalc_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_pltcalc_P1 work/full_correlation/il_S2_summaryaalcalc/P1.bin > /dev/null & pid24=$!

summarycalc -m -f  -1 /tmp/%FIFO_DIR%/fifo/full_correlation/il_S1_summary_P1 -2 /tmp/%FIFO_DIR%/fifo/full_correlation/il_S2_summary_P1 < /tmp/%FIFO_DIR%/fifo/full_correlation/il_P1 &

# --- Do ground up loss computes ---

eltcalc < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_eltcalc_P1 > work/full_correlation/kat/gul_S1_eltcalc_P1 & pid25=$!
summarycalctocsv < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summarycalc_P1 > work/full_correlation/kat/gul_S1_summarycalc_P1 & pid26=$!
pltcalc < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_pltcalc_P1 > work/full_correlation/kat/gul_S1_pltcalc_P1 & pid27=$!
eltcalc < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_eltcalc_P1 > work/full_correlation/kat/gul_S2_eltcalc_P1 & pid28=$!
summarycalctocsv < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_summarycalc_P1 > work/full_correlation/kat/gul_S2_summarycalc_P1 & pid29=$!
pltcalc < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_pltcalc_P1 > work/full_correlation/kat/gul_S2_pltcalc_P1 & pid30=$!


tee < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summary_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_eltcalc_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summarycalc_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_pltcalc_P1 work/full_correlation/gul_S1_summaryaalcalc/P1.bin > /dev/null & pid31=$!
tee < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_summary_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_eltcalc_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_summarycalc_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_pltcalc_P1 work/full_correlation/gul_S2_summaryaalcalc/P1.bin > /dev/null & pid32=$!

summarycalc -m -i  -1 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S1_summary_P1 -2 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_S2_summary_P1 < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_P1 &

tee < /tmp/%FIFO_DIR%/fifo/full_correlation/gul_fc_P1 /tmp/%FIFO_DIR%/fifo/full_correlation/gul_P1  | fmcalc -a2 > /tmp/%FIFO_DIR%/fifo/full_correlation/il_P1  &
eve 1 1 | getmodel | gulcalc -S0 -L0 -r -j /tmp/%FIFO_DIR%/fifo/full_correlation/gul_fc_P1 -a1 -i - | tee /tmp/%FIFO_DIR%/fifo/gul_P1 | fmcalc -a2 > /tmp/%FIFO_DIR%/fifo/il_P1  &

wait $pid1 $pid2 $pid3 $pid4 $pid5 $pid6 $pid7 $pid8 $pid9 $pid10 $pid11 $pid12 $pid13 $pid14 $pid15 $pid16 $pid17 $pid18 $pid19 $pid20 $pid21 $pid22 $pid23 $pid24 $pid25 $pid26 $pid27 $pid28 $pid29 $pid30 $pid31 $pid32


# --- Do insured loss kats ---

kat -s work/kat/il_S1_eltcalc_P1 > output/il_S1_eltcalc.csv & kpid1=$!
kat work/kat/il_S1_pltcalc_P1 > output/il_S1_pltcalc.csv & kpid2=$!
kat work/kat/il_S1_summarycalc_P1 > output/il_S1_summarycalc.csv & kpid3=$!
kat -s work/kat/il_S2_eltcalc_P1 > output/il_S2_eltcalc.csv & kpid4=$!
kat work/kat/il_S2_pltcalc_P1 > output/il_S2_pltcalc.csv & kpid5=$!
kat work/kat/il_S2_summarycalc_P1 > output/il_S2_summarycalc.csv & kpid6=$!

# --- Do insured loss kats for fully correlated output ---

kat -s work/full_correlation/kat/il_S1_eltcalc_P1 > output/full_correlation/il_S1_eltcalc.csv & kpid7=$!
kat work/full_correlation/kat/il_S1_pltcalc_P1 > output/full_correlation/il_S1_pltcalc.csv & kpid8=$!
kat work/full_correlation/kat/il_S1_summarycalc_P1 > output/full_correlation/il_S1_summarycalc.csv & kpid9=$!
kat -s work/full_correlation/kat/il_S2_eltcalc_P1 > output/full_correlation/il_S2_eltcalc.csv & kpid10=$!
kat work/full_correlation/kat/il_S2_pltcalc_P1 > output/full_correlation/il_S2_pltcalc.csv & kpid11=$!
kat work/full_correlation/kat/il_S2_summarycalc_P1 > output/full_correlation/il_S2_summarycalc.csv & kpid12=$!

# --- Do ground up loss kats ---

kat -s work/kat/gul_S1_eltcalc_P1 > output/gul_S1_eltcalc.csv & kpid13=$!
kat work/kat/gul_S1_pltcalc_P1 > output/gul_S1_pltcalc.csv & kpid14=$!
kat work/kat/gul_S1_summarycalc_P1 > output/gul_S1_summarycalc.csv & kpid15=$!
kat -s work/kat/gul_S2_eltcalc_P1 > output/gul_S2_eltcalc.csv & kpid16=$!
kat work/kat/gul_S2_pltcalc_P1 > output/gul_S2_pltcalc.csv & kpid17=$!
kat work/kat/gul_S2_summarycalc_P1 > output/gul_S2_summarycalc.csv & kpid18=$!

# --- Do ground up loss kats for fully correlated output ---

kat -s work/full_correlation/kat/gul_S1_eltcalc_P1 > output/full_correlation/gul_S1_eltcalc.csv & kpid19=$!
kat work/full_correlation/kat/gul_S1_pltcalc_P1 > output/full_correlation/gul_S1_pltcalc.csv & kpid20=$!
kat work/full_correlation/kat/gul_S1_summarycalc_P1 > output/full_correlation/gul_S1_summarycalc.csv & kpid21=$!
kat -s work/full_correlation/kat/gul_S2_eltcalc_P1 > output/full_correlation/gul_S2_eltcalc.csv & kpid22=$!
kat work/full_correlation/kat/gul_S2_pltcalc_P1 > output/full_correlation/gul_S2_pltcalc.csv & kpid23=$!
kat work/full_correlation/kat/gul_S2_summarycalc_P1 > output/full_correlation/gul_S2_summarycalc.csv & kpid24=$!
wait $kpid1 $kpid2 $kpid3 $kpid4 $kpid5 $kpid6 $kpid7 $kpid8 $kpid9 $kpid10 $kpid11 $kpid12 $kpid13 $kpid14 $kpid15 $kpid16 $kpid17 $kpid18 $kpid19 $kpid20 $kpid21 $kpid22 $kpid23 $kpid24

