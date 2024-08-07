# OSPAN
OSPAN is a cognitive task that the sample is required to remember random sequences of alphabets of certain length (either 4, 5, 6, 7, or 8, that are randomly assigned). Alphabets are shown one by one on the screen (this can be any device that they used for this task). 
Between each letters, sample is asked whether the math equation on the screen is correct or not. For example, if '1 + 1 = 2' is on the screen, sample should respond 'correct' on the screen. If '1 + 1 = 3' on the screen, then sample would answer 'wrong'. After all alphabets are shown  (either 4, 5, 6, 7, or 8 letters), sample is asked to input the whole sequence of alphabets. 

The script ospan.m scores all samples' response in two distinct grading system.

1. strict scoring: This shows the percentage of letters that are in the exact positions with the answer.

2. flexible scoring: This shows the percentage of letters that are contained in the correct sequence.

Also, the algorithm calculates several error rates of samples.

missing error: This shows the percentage of letters that are missing from the correct sequence.  

additional error: This shows the number of letters that are not contained in the correct sequence.

For example, if the sample's input is 'ACBIEF' while the answer is 'ABCDE', strict score = 40, flex score = 80, missing error = 20, additional error = 2.

The output will show the average, standard deviation, and error rates in two different scoring methods (strict and flexible) for each sessions/tests of samples to analyze the result of sleep on short term memories.


# RST

Cognitive task that sample has to either tap the congruent side of screen or incongruent side of the screen based on memorized objects. Sample are given three tests: congruent, incongruent, and mix. In the beginning of the congruent and incongruent test, sample is given one object each. For instance, if sample was shown picture of apple in the beginning of the congruent task, then sample should tap the side that has apple on the screen
