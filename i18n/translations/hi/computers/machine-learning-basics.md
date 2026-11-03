# Machine Learning Fundamentals

> **Domain:** computers | **Difficulty:** apprentice | **Safety:** green

*Reference material only. Verify this information against primary sources
and qualified professionals before acting on it. This entry is not a sole
source of information.*

## Overview

Machine learning fits a model to data instead of writing the rule by hand.
The hard part is not the fitting, it is the honesty of the evaluation: a
model that has seen the test set during training reports a score it will
never reach in the field. The key principle is that the way the data is
split decides what the final number means, so a baseline, a held-out
set, and a written record of how the data was collected matter more than
the choice of model.

## Prerequisites

- Basic statistics: mean, variance, and correlation
- Probability and the idea of a distribution
- Python or an equivalent language with arrays and plotting
- Reading a table of numbers without being misled by it

## Materials & Tools

- A machine with a scripting environment and a notebook or spreadsheet
- A dataset with a clear question attached, of a few hundred rows or more
- The reference implementation of the model, taken from its documentation
- A plotting tool for the learning curve and the confusion matrix
- A data dictionary and an experiment log kept with the dataset
- Held-out data collected later, if the task is predictive
- A written statement of what the model will be used for and by whom

## Procedure

### Frame the problem

1. Write down the decision the model will support, and the cost of a
   false positive and of a false negative in that setting.
2. Define the target label precisely, so that two people would label the
   same case the same way.
3. Collect the data by the same process the model will meet in use, and
   record the collection conditions with it.

### Prepare the data

1. Look for missing values, duplicates, and impossible values, and decide
   case by case whether to drop, impute, or keep each one.
2. Split the data before any fitting, into about 60 percent for training,
   20 percent for validation, and 20 percent for the final test.
3. Keep the test set sealed until the end, and save the splits so the
   same experiment can be repeated exactly.

### Train and compare

1. Fit a trivial baseline first, such as always predicting the most
   common class, and record its score as the number to beat.
2. Fit a simple model, then a more complex one, changing one thing at a
   time and writing every run into the log.
3. Compare the models on the validation set with the metric you chose,
   and read the learning curve for signs of overfitting.

### Evaluate honestly

1. Evaluate the chosen model once on the sealed test set and report that
   number, not the best one from the search.
2. Break the results down by subgroup and by time period, because an
   average hides the failures.
3. State the limits of the data in the write-up, including where the
   model must not be used, and set a review date.

## Safety Notes

- A model is a tool that carries the bias of its data. Where a wrong
  answer matters, keep a trained person in the loop and record who
  reviewed each decision.
- Do not let a model make decisions about medical treatment, legal
  status, or safety without the appropriate expert involvement, and do
  not rely on any note here as medical or legal advice.
- Collect the least personal data that will do, get consent, and delete
  what is no longer needed; training data outlives the project.
- Do not deploy a model that has only been tested on data from a
  different population than the one it will serve.
- Watch for drift after deployment: the world moves on, the model does
  not, and a silent degradation is the usual failure.
- A surveillance or monitoring system built from these methods affects
  real people's lives, so agree the governance before you collect.
- Keep the data and the model versioned, and keep the ability to roll
  back to the previous version.

## Verification

- **Status:** draft
- **Tested by:** —
- **Date:** —

## Sources

- NIST AI Risk Framework (public domain)
