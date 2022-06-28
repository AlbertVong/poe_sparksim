# poe_sparksim
Path of Exile Spark Simulation

This is a simulation for Spark DPS in Path of Exile (Patch 3.18).

Contained is a MATLAB implementation of a spark simulation (sparksim_final) with corresponding function files. The main simulation file can be used for simulating a single set of parameters, or a combination of parameters (which is what I used to generate the google sheet dataset).

Contained in the function files are the more nitty gritty details of the simulation (e.g. initial spark cone angle, how I calculate hit dps, boss hitchecking, etc.)

Sorry about not implementing this in Python, but I'm more familiar with MATLAB and ended up vectorizing the majority of the simulation so it would run faster.

If there are additional questions please dm me on reddit @Butsicles

