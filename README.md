# cell-manufacturing
Code used in: On-demand serum-free media formulations for human hematopoietic cell expansion using a high dimensional search algorithm” by Kim and Audet, Communications Biology (accepted Nov 28, 2018)


High Dimensional-Differential Evolution (HD-DE) by Michelle Kim and Julie Audet (University of Toronto)
An evolutionary algorithm-guided optimization approach demonstrated in “On-demand serum-free media formulations for human hematopoietic cell expansion using a high dimensional search algorithm” by Kim and Audet, Communications Biology (accepted Nov 28, 2018). The core optimization mechanism follows the DE algorithm principles inspired by Darwinian evolutionary concepts including mutation, crossover, and competition between individuals. The optimization occurs through the selection of individuals with improved fitness (better performance) over generations (iterative cycles of experimentation). The optimization may be conducted in silico based on biological response simulated by an objective function, or in vitro accepting input of biological response generated from the testing of suggested factor-dose combinations.

1.	System requirements
1.1.	All software dependencies and operating systems (including version numbers) – Requires Mathworks Matlab, Microsoft Excel
1.2.	Versions the software has been tested on – Tested on Matlab 2015b, 2017b
1.3.	Any required non-standard hardware – Generates input file in the form of an .xlsx file for the Hamilton Microlab liquid handling system. Accepts batch processing information in .xlsx file format from the BD FacsDiva or Beckman Coulter CytExpert platforms.

2.	Installation guide
2.1.	Instructions – Installation on local device not required. Runs from within whichever directory selected as the current directory in Matlab.
2.2.	Typical install time on a "normal" desktop computer – Installation not required for execution of the algorithm.

3.	Demo
3.1.	Instructions to run on data – An optimization benchmark function can be defined in OptimProblem.m as the objective function to run the optimization in silico.
3.2.	Expected output – The HD-DE algorithm will perform the optimization based on the solution space defined by the factor-dose levels specified in the data output template file.
3.3.	Expected run time for demo on a "normal" desktop computer – A few minutes per generation. 

4.	Instructions for use
4.1.	How to run the software on your data – Execution of the algorithm starts at main.m in Matlab. Selection of template file containing factor-dose information, output of test combinations, and input of flow cytometry batch analysis information follows command line prompts. An example of the batch analysis file containing cell counts is provided to test algorithm operation.
4.2.	(OPTIONAL) Reproduction instructions – The in silico optimization results were generated based on a 15-factor optimization on the Rosenbrock function. The in vitro optimization results were generated based on a 15-factor (TF-1 cells) or 14-factor (T cells) optimization. The combinations suggested by the algorithm were tested in vitro to obtain the biological response data.
