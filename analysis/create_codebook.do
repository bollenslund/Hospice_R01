capture log close
clear all
set more off

local datapath J:\Geriatrics\Geri\Hospice Project\Hospice\working
local logpath J:\Geriatrics\Geri\Hospice Project\output

log using "`logpath'\codebook_Stata_dataset-LOG.txt", text replace

cd "`datapath'"

use ltd_vars_for_analysis1_clean.dta, replace

codebook

log close
