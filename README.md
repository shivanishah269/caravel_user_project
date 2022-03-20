# Cache Simulator

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

Computer architects need to choose the design configurations which will work effectively across most commonly used workloads. Our work enables the architect to choose the right configuration based on metrics such as hit rates, power, area, and timing. We implement an FPGA accelerated parameterized two-level multi-core cache simulator called Cache-accel which can be partially reconfigured to include prefetching. The key motivation behind the idea is the speed with which the design space exploration can be carried out by exploiting the parallelism available in an FPGA and the accuracy of the results as compared to a software simulator.

You can find more details about our project over here: [FPGA Accelerated Multi-Core Cache Simulator](https://github.com/shivanishah269/FPGA_based_Multicore_Cache_Simuator)

## Cache Simulator on Caravel SoC
We have integrated a L1 Cache module with the picoRV32 core on the user project area of Caravel platform. We have integrated a smaller version of the 4-way set associative 512B L1 cache as user project area in caravel SoC has limited silicon area of 2.92mm x 3.52mm. We have used Logic Analyzer (LA) to probe the output (hit metric of L1 cache).

<a href = "url"><img src = "https://user-images.githubusercontent.com/15063738/158312888-f4e65a2f-1dce-4c08-83eb-4053ac25368b.png" width="800">
