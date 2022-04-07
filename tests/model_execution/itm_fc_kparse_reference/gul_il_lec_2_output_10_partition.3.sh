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

rm -R -f fifo/*
mkdir fifo/full_correlation/
rm -R -f work/*
mkdir work/kat/
mkdir work/full_correlation/
mkdir work/full_correlation/kat/

mkdir work/gul_S1_summaryleccalc
mkdir work/gul_S1_summaryaalcalc
mkdir work/gul_S2_summaryleccalc
mkdir work/gul_S2_summaryaalcalc
mkdir work/full_correlation/gul_S1_summaryleccalc
mkdir work/full_correlation/gul_S1_summaryaalcalc
mkdir work/full_correlation/gul_S2_summaryleccalc
mkdir work/full_correlation/gul_S2_summaryaalcalc
mkdir work/il_S1_summaryleccalc
mkdir work/il_S1_summaryaalcalc
mkdir work/il_S2_summaryleccalc
mkdir work/il_S2_summaryaalcalc
mkdir work/full_correlation/il_S1_summaryleccalc
mkdir work/full_correlation/il_S1_summaryaalcalc
mkdir work/full_correlation/il_S2_summaryleccalc
mkdir work/full_correlation/il_S2_summaryaalcalc

mkfifo fifo/full_correlation/gul_fc_P4

mkfifo fifo/gul_P4

mkfifo fifo/gul_S1_summary_P4
mkfifo fifo/gul_S1_summary_P4.idx
mkfifo fifo/gul_S1_eltcalc_P4
mkfifo fifo/gul_S1_summarycalc_P4
mkfifo fifo/gul_S1_pltcalc_P4
mkfifo fifo/gul_S2_summary_P4
mkfifo fifo/gul_S2_summary_P4.idx
mkfifo fifo/gul_S2_eltcalc_P4
mkfifo fifo/gul_S2_summarycalc_P4
mkfifo fifo/gul_S2_pltcalc_P4

mkfifo fifo/il_P4

mkfifo fifo/il_S1_summary_P4
mkfifo fifo/il_S1_summary_P4.idx
mkfifo fifo/il_S1_eltcalc_P4
mkfifo fifo/il_S1_summarycalc_P4
mkfifo fifo/il_S1_pltcalc_P4
mkfifo fifo/il_S2_summary_P4
mkfifo fifo/il_S2_summary_P4.idx
mkfifo fifo/il_S2_eltcalc_P4
mkfifo fifo/il_S2_summarycalc_P4
mkfifo fifo/il_S2_pltcalc_P4

mkfifo fifo/full_correlation/gul_P4

mkfifo fifo/full_correlation/gul_S1_summary_P4
mkfifo fifo/full_correlation/gul_S1_summary_P4.idx
mkfifo fifo/full_correlation/gul_S1_eltcalc_P4
mkfifo fifo/full_correlation/gul_S1_summarycalc_P4
mkfifo fifo/full_correlation/gul_S1_pltcalc_P4
mkfifo fifo/full_correlation/gul_S2_summary_P4
mkfifo fifo/full_correlation/gul_S2_summary_P4.idx
mkfifo fifo/full_correlation/gul_S2_eltcalc_P4
mkfifo fifo/full_correlation/gul_S2_summarycalc_P4
mkfifo fifo/full_correlation/gul_S2_pltcalc_P4

mkfifo fifo/full_correlation/il_P4

mkfifo fifo/full_correlation/il_S1_summary_P4
mkfifo fifo/full_correlation/il_S1_summary_P4.idx
mkfifo fifo/full_correlation/il_S1_eltcalc_P4
mkfifo fifo/full_correlation/il_S1_summarycalc_P4
mkfifo fifo/full_correlation/il_S1_pltcalc_P4
mkfifo fifo/full_correlation/il_S2_summary_P4
mkfifo fifo/full_correlation/il_S2_summary_P4.idx
mkfifo fifo/full_correlation/il_S2_eltcalc_P4
mkfifo fifo/full_correlation/il_S2_summarycalc_P4
mkfifo fifo/full_correlation/il_S2_pltcalc_P4



# --- Do insured loss computes ---
eltcalc -s < fifo/il_S1_eltcalc_P4 > work/kat/il_S1_eltcalc_P4 & pid1=$!
summarycalctocsv -s < fifo/il_S1_summarycalc_P4 > work/kat/il_S1_summarycalc_P4 & pid2=$!
pltcalc -H < fifo/il_S1_pltcalc_P4 > work/kat/il_S1_pltcalc_P4 & pid3=$!
eltcalc -s < fifo/il_S2_eltcalc_P4 > work/kat/il_S2_eltcalc_P4 & pid4=$!
summarycalctocsv -s < fifo/il_S2_summarycalc_P4 > work/kat/il_S2_summarycalc_P4 & pid5=$!
pltcalc -H < fifo/il_S2_pltcalc_P4 > work/kat/il_S2_pltcalc_P4 & pid6=$!
tee < fifo/il_S1_summary_P4 fifo/il_S1_eltcalc_P4 fifo/il_S1_summarycalc_P4 fifo/il_S1_pltcalc_P4 work/il_S1_summaryaalcalc/P4.bin work/il_S1_summaryleccalc/P4.bin > /dev/null & pid7=$!
tee < fifo/il_S1_summary_P4.idx work/il_S1_summaryaalcalc/P4.idx work/il_S1_summaryleccalc/P4.idx > /dev/null & pid8=$!
tee < fifo/il_S2_summary_P4 fifo/il_S2_eltcalc_P4 fifo/il_S2_summarycalc_P4 fifo/il_S2_pltcalc_P4 work/il_S2_summaryaalcalc/P4.bin work/il_S2_summaryleccalc/P4.bin > /dev/null & pid9=$!
tee < fifo/il_S2_summary_P4.idx work/il_S2_summaryaalcalc/P4.idx work/il_S2_summaryleccalc/P4.idx > /dev/null & pid10=$!
summarycalc -m -f  -1 fifo/il_S1_summary_P4 -2 fifo/il_S2_summary_P4 < fifo/il_P4 &

# --- Do ground up loss computes ---
eltcalc -s < fifo/gul_S1_eltcalc_P4 > work/kat/gul_S1_eltcalc_P4 & pid11=$!
summarycalctocsv -s < fifo/gul_S1_summarycalc_P4 > work/kat/gul_S1_summarycalc_P4 & pid12=$!
pltcalc -H < fifo/gul_S1_pltcalc_P4 > work/kat/gul_S1_pltcalc_P4 & pid13=$!
eltcalc -s < fifo/gul_S2_eltcalc_P4 > work/kat/gul_S2_eltcalc_P4 & pid14=$!
summarycalctocsv -s < fifo/gul_S2_summarycalc_P4 > work/kat/gul_S2_summarycalc_P4 & pid15=$!
pltcalc -H < fifo/gul_S2_pltcalc_P4 > work/kat/gul_S2_pltcalc_P4 & pid16=$!
tee < fifo/gul_S1_summary_P4 fifo/gul_S1_eltcalc_P4 fifo/gul_S1_summarycalc_P4 fifo/gul_S1_pltcalc_P4 work/gul_S1_summaryaalcalc/P4.bin work/gul_S1_summaryleccalc/P4.bin > /dev/null & pid17=$!
tee < fifo/gul_S1_summary_P4.idx work/gul_S1_summaryaalcalc/P4.idx work/gul_S1_summaryleccalc/P4.idx > /dev/null & pid18=$!
tee < fifo/gul_S2_summary_P4 fifo/gul_S2_eltcalc_P4 fifo/gul_S2_summarycalc_P4 fifo/gul_S2_pltcalc_P4 work/gul_S2_summaryaalcalc/P4.bin work/gul_S2_summaryleccalc/P4.bin > /dev/null & pid19=$!
tee < fifo/gul_S2_summary_P4.idx work/gul_S2_summaryaalcalc/P4.idx work/gul_S2_summaryleccalc/P4.idx > /dev/null & pid20=$!
summarycalc -m -i  -1 fifo/gul_S1_summary_P4 -2 fifo/gul_S2_summary_P4 < fifo/gul_P4 &

# --- Do insured loss computes ---
eltcalc -s < fifo/full_correlation/il_S1_eltcalc_P4 > work/full_correlation/kat/il_S1_eltcalc_P4 & pid21=$!
summarycalctocsv -s < fifo/full_correlation/il_S1_summarycalc_P4 > work/full_correlation/kat/il_S1_summarycalc_P4 & pid22=$!
pltcalc -H < fifo/full_correlation/il_S1_pltcalc_P4 > work/full_correlation/kat/il_S1_pltcalc_P4 & pid23=$!
eltcalc -s < fifo/full_correlation/il_S2_eltcalc_P4 > work/full_correlation/kat/il_S2_eltcalc_P4 & pid24=$!
summarycalctocsv -s < fifo/full_correlation/il_S2_summarycalc_P4 > work/full_correlation/kat/il_S2_summarycalc_P4 & pid25=$!
pltcalc -H < fifo/full_correlation/il_S2_pltcalc_P4 > work/full_correlation/kat/il_S2_pltcalc_P4 & pid26=$!
tee < fifo/full_correlation/il_S1_summary_P4 fifo/full_correlation/il_S1_eltcalc_P4 fifo/full_correlation/il_S1_summarycalc_P4 fifo/full_correlation/il_S1_pltcalc_P4 work/full_correlation/il_S1_summaryaalcalc/P4.bin work/full_correlation/il_S1_summaryleccalc/P4.bin > /dev/null & pid27=$!
tee < fifo/full_correlation/il_S1_summary_P4.idx work/full_correlation/il_S1_summaryaalcalc/P4.idx work/full_correlation/il_S1_summaryleccalc/P4.idx > /dev/null & pid28=$!
tee < fifo/full_correlation/il_S2_summary_P4 fifo/full_correlation/il_S2_eltcalc_P4 fifo/full_correlation/il_S2_summarycalc_P4 fifo/full_correlation/il_S2_pltcalc_P4 work/full_correlation/il_S2_summaryaalcalc/P4.bin work/full_correlation/il_S2_summaryleccalc/P4.bin > /dev/null & pid29=$!
tee < fifo/full_correlation/il_S2_summary_P4.idx work/full_correlation/il_S2_summaryaalcalc/P4.idx work/full_correlation/il_S2_summaryleccalc/P4.idx > /dev/null & pid30=$!
summarycalc -m -f  -1 fifo/full_correlation/il_S1_summary_P4 -2 fifo/full_correlation/il_S2_summary_P4 < fifo/full_correlation/il_P4 &

# --- Do ground up loss computes ---
eltcalc -s < fifo/full_correlation/gul_S1_eltcalc_P4 > work/full_correlation/kat/gul_S1_eltcalc_P4 & pid31=$!
summarycalctocsv -s < fifo/full_correlation/gul_S1_summarycalc_P4 > work/full_correlation/kat/gul_S1_summarycalc_P4 & pid32=$!
pltcalc -H < fifo/full_correlation/gul_S1_pltcalc_P4 > work/full_correlation/kat/gul_S1_pltcalc_P4 & pid33=$!
eltcalc -s < fifo/full_correlation/gul_S2_eltcalc_P4 > work/full_correlation/kat/gul_S2_eltcalc_P4 & pid34=$!
summarycalctocsv -s < fifo/full_correlation/gul_S2_summarycalc_P4 > work/full_correlation/kat/gul_S2_summarycalc_P4 & pid35=$!
pltcalc -H < fifo/full_correlation/gul_S2_pltcalc_P4 > work/full_correlation/kat/gul_S2_pltcalc_P4 & pid36=$!
tee < fifo/full_correlation/gul_S1_summary_P4 fifo/full_correlation/gul_S1_eltcalc_P4 fifo/full_correlation/gul_S1_summarycalc_P4 fifo/full_correlation/gul_S1_pltcalc_P4 work/full_correlation/gul_S1_summaryaalcalc/P4.bin work/full_correlation/gul_S1_summaryleccalc/P4.bin > /dev/null & pid37=$!
tee < fifo/full_correlation/gul_S1_summary_P4.idx work/full_correlation/gul_S1_summaryaalcalc/P4.idx work/full_correlation/gul_S1_summaryleccalc/P4.idx > /dev/null & pid38=$!
tee < fifo/full_correlation/gul_S2_summary_P4 fifo/full_correlation/gul_S2_eltcalc_P4 fifo/full_correlation/gul_S2_summarycalc_P4 fifo/full_correlation/gul_S2_pltcalc_P4 work/full_correlation/gul_S2_summaryaalcalc/P4.bin work/full_correlation/gul_S2_summaryleccalc/P4.bin > /dev/null & pid39=$!
tee < fifo/full_correlation/gul_S2_summary_P4.idx work/full_correlation/gul_S2_summaryaalcalc/P4.idx work/full_correlation/gul_S2_summaryleccalc/P4.idx > /dev/null & pid40=$!
summarycalc -m -i  -1 fifo/full_correlation/gul_S1_summary_P4 -2 fifo/full_correlation/gul_S2_summary_P4 < fifo/full_correlation/gul_P4 &

tee < fifo/full_correlation/gul_fc_P4 fifo/full_correlation/gul_P4  | fmcalc -a2 > fifo/full_correlation/il_P4  &
eve 4 10 | getmodel | gulcalc -S0 -L0 -r -j fifo/full_correlation/gul_fc_P4 -a1 -i - | tee fifo/gul_P4 | fmcalc -a2 > fifo/il_P4  &

wait $pid1 $pid2 $pid3 $pid4 $pid5 $pid6 $pid7 $pid8 $pid9 $pid10 $pid11 $pid12 $pid13 $pid14 $pid15 $pid16 $pid17 $pid18 $pid19 $pid20 $pid21 $pid22 $pid23 $pid24 $pid25 $pid26 $pid27 $pid28 $pid29 $pid30 $pid31 $pid32 $pid33 $pid34 $pid35 $pid36 $pid37 $pid38 $pid39 $pid40


# --- Do insured loss kats ---

kat -s work/kat/il_S1_eltcalc_P4 > output/il_S1_eltcalc.csv & kpid1=$!
kat work/kat/il_S1_pltcalc_P4 > output/il_S1_pltcalc.csv & kpid2=$!
kat work/kat/il_S1_summarycalc_P4 > output/il_S1_summarycalc.csv & kpid3=$!
kat -s work/kat/il_S2_eltcalc_P4 > output/il_S2_eltcalc.csv & kpid4=$!
kat work/kat/il_S2_pltcalc_P4 > output/il_S2_pltcalc.csv & kpid5=$!
kat work/kat/il_S2_summarycalc_P4 > output/il_S2_summarycalc.csv & kpid6=$!

# --- Do insured loss kats for fully correlated output ---

kat -s work/full_correlation/kat/il_S1_eltcalc_P4 > output/full_correlation/il_S1_eltcalc.csv & kpid7=$!
kat work/full_correlation/kat/il_S1_pltcalc_P4 > output/full_correlation/il_S1_pltcalc.csv & kpid8=$!
kat work/full_correlation/kat/il_S1_summarycalc_P4 > output/full_correlation/il_S1_summarycalc.csv & kpid9=$!
kat -s work/full_correlation/kat/il_S2_eltcalc_P4 > output/full_correlation/il_S2_eltcalc.csv & kpid10=$!
kat work/full_correlation/kat/il_S2_pltcalc_P4 > output/full_correlation/il_S2_pltcalc.csv & kpid11=$!
kat work/full_correlation/kat/il_S2_summarycalc_P4 > output/full_correlation/il_S2_summarycalc.csv & kpid12=$!

# --- Do ground up loss kats ---

kat -s work/kat/gul_S1_eltcalc_P4 > output/gul_S1_eltcalc.csv & kpid13=$!
kat work/kat/gul_S1_pltcalc_P4 > output/gul_S1_pltcalc.csv & kpid14=$!
kat work/kat/gul_S1_summarycalc_P4 > output/gul_S1_summarycalc.csv & kpid15=$!
kat -s work/kat/gul_S2_eltcalc_P4 > output/gul_S2_eltcalc.csv & kpid16=$!
kat work/kat/gul_S2_pltcalc_P4 > output/gul_S2_pltcalc.csv & kpid17=$!
kat work/kat/gul_S2_summarycalc_P4 > output/gul_S2_summarycalc.csv & kpid18=$!

# --- Do ground up loss kats for fully correlated output ---

kat -s work/full_correlation/kat/gul_S1_eltcalc_P4 > output/full_correlation/gul_S1_eltcalc.csv & kpid19=$!
kat work/full_correlation/kat/gul_S1_pltcalc_P4 > output/full_correlation/gul_S1_pltcalc.csv & kpid20=$!
kat work/full_correlation/kat/gul_S1_summarycalc_P4 > output/full_correlation/gul_S1_summarycalc.csv & kpid21=$!
kat -s work/full_correlation/kat/gul_S2_eltcalc_P4 > output/full_correlation/gul_S2_eltcalc.csv & kpid22=$!
kat work/full_correlation/kat/gul_S2_pltcalc_P4 > output/full_correlation/gul_S2_pltcalc.csv & kpid23=$!
kat work/full_correlation/kat/gul_S2_summarycalc_P4 > output/full_correlation/gul_S2_summarycalc.csv & kpid24=$!
wait $kpid1 $kpid2 $kpid3 $kpid4 $kpid5 $kpid6 $kpid7 $kpid8 $kpid9 $kpid10 $kpid11 $kpid12 $kpid13 $kpid14 $kpid15 $kpid16 $kpid17 $kpid18 $kpid19 $kpid20 $kpid21 $kpid22 $kpid23 $kpid24

