# maxlength

## Purpose
Take datasets to be combined, find common variables, and for those variables obtain the maximum length. Returns a length statement as a global macro variable.

## Usage
DSETS = Datasets to be combined (space separated)

DROPS = Variable(s) to exclude based on drop statement

KEEPS =  Variable(s) to include based on keep statement

## Example
    %maxlength(DSETS=input.dset1 input.dset2);
    data combine;
        &MAXLENGTH;
        set input.dset1 input.dset2;
    run;