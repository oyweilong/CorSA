# Welcome to CorSA!

## Project Overview

CorSA is a macro developed within ImageJ for estimating the surface area and colour score of coral fragments from photographs. 
The goal of CorSA is to allow for the batch processing of coral images to facilitate regular monitoring of the condition of the fragments.
Since surface area and colour estimation of coral fragments is done by hand, CorSA aims to reduce human error by providing a consistent solution
for estimation.

## How it works

*Surface area measurements*
CorSA works by segmenting the coral fragment from the image by creating a mask from colour thresholding the fragment from the rest of the image.
By using a predefined standard in the image for scale setting (i.e. a 1 x 1 cm square), CorSA can similarly obtain the scale of the image by thresholding
the standard. With the mask, CorSA can then estimate the surface area of the coral fragment.

*Colour measurements*
With a colour reference in the image (i.e. CoralWatch colour chart), CorSA obtains the mean gray values of each colour score and compares the mean gray values
of the coral fragment to these references. After which, the closest colour score is estimated for the fragment, with precision determined by the user
