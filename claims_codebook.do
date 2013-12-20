/*creates codebook from merged claims dataset*/

capture log close

clear all
set mem 1200m
set matsize 800
set more off

local logpath J:\Geriatrics\Geri\Hospice Project\output\

log using "`logpath'claims_codebook.txt", text replace

local datapath J:\Geriatrics\Geri\Hospice Project\Hospice\working\

use "`datapath'all_claims_clean.dta"

codebook, header

log close
