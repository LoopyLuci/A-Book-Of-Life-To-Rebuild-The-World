# Computer Vision Fundamentals

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Computer vision turns a grid of numbers into a statement about the world.
The pipeline always has the same shape: fix the image, find features, feed
a classifier, then check the result against reality. The key principle is
that the pixels are only the input: the work that matters is in the
training set and in an honest measurement of what the system gets wrong,
because a vision model scored only on easy examples fails on the first
hard night.

## Prerequisites

- Linear algebra basics: vectors, matrices, and dot products
- Basic statistics and the idea of a distribution
- Python with an array library and an imaging library
- Machine Learning Fundamentals

## Materials & Tools

- Camera with a known resolution and lens, or a fixed image dataset
- Image library able to read and write the common formats
- Scripting environment for batch processing and plotting
- Labelled image set with a written labelling guide
- Plotting tool for histograms, confusion matrices, and precision-recall
  curves
- Storage for the raw images and a manifest of every file
- Annotation tool, and a second person to check a sample of the labels

## Procedure

### Prepare the images

1. Record the resolution, the colour depth, and the format of every
   source, and check for colour and orientation errors before use.
2. Convert to a consistent form, either 8-bit grayscale with 256 levels
   for shape work or 8 bits per colour channel for colour work, and write
   a manifest of the conversion.
3. Normalise brightness and contrast against a fixed reference, and leave
   the original files untouched.

### Extract features

1. Apply a Gaussian blur with a radius of about 1 percent of the image
   width to suppress noise before any edge or shape work.
2. Find edges with a gradient operator such as Sobel, whose weighting of
   1, 2, 1 along each axis makes it less sensitive to noise than a plain
   difference.
3. Segment the image into regions and describe each region by simple
   measurements: area, aspect ratio, mean colour, and edge orientation.

### Train a classifier

1. Split the labelled images into about 60 percent for training, 20
   percent for validation, and 20 percent for the sealed test, and keep
   the split fixed.
2. Train a simple classifier, such as a support vector machine or a
   nearest-neighbour model, and tune it on the validation set only.
3. Score the result on the sealed test set with the confusion matrix, and
   report precision and recall per class rather than one overall number.

### Deploy with checks

1. Extend the training set with augmentation that matches the real
   variations: brightness, scale, rotation, blur, and partial occlusion.
2. Run the classifier on a live feed or a fresh sample and compare the
   output with a human reading the same images.
3. Log the inputs, the outputs, and the failures, and set a schedule for
   reviewing the results and retraining when the conditions change.

## Safety Notes

- A camera pointed at people captures them. Get consent, post a notice,
  and restrict access to the recordings as you would any private record.
- Never let a vision system control machinery without an independent
  interlock and a human override that works when the system is wrong.
- Do not build a system that identifies or tracks individuals for
  surveillance without an agreed governance and a stated purpose.
- Check the eye-safety class of any infrared illuminator or laser
  rangefinder before mounting it where people or animals can look into it.
- Outdoor cameras need weatherproof housings, drip loops on every cable,
  and surge protection on any line that leaves the building.
- Under-represented groups are misidentified more often, so measure the
  error rate per group and per lighting condition before trusting the
  system.
- A model trained on one season or one camera position will fail when
  either changes; keep the mount rigid and re-check the results after any
  disturbance.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST AI Risk Framework (public domain)
