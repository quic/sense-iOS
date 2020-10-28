# 20bn-realtimenet-iOS

20bn-realtimenet-iOS is the iOS version of [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet).
You can convert some pytorch model from 20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) and run them on an iOS device. 
Currently, only the efficentnetLite 4 version of the gesture detection is available for conversion. More will come soon.

The efficientnet backbone run on iOS devices with A11 chips or better. It might work on devices with A10 chips, but it is not testsed.

## Getting Started

### 1. Clone the Repository

To begin, clone this repository to a local directory of your choice:
```
git clone git@github.com:TwentyBN/20bn-realtimenet-iOS.git
cd 20bn-realtimenet-iOS.git
```

### 2. Install the 20bn-realtimenet Repository

Install this repository: [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) and follow the instructions to install it.

### 3. Get the models and convert them to coreml

In 20bn-realtimenet, follow the instruction to download the models (you will need to accept the terms).
Then follow the instruction to convert a model into coreml.

### 4. Copy the converted model into this repo

The output of the conversion script will be found in /path/to/20bn-realtimenet/resources/coreml.
Rename the output coreml file to realtimenet.mlmodel and move it to 20bn-realtimenet-iOS/20bn-realtimenet-iOS/realtimenet.mlmodel

### 5. Changes to InferenceLocal.swift 
Set the dimGlobalClassifier to the right number of outputs. 
By default, it is set to 30 (number of outputs for the gesture control).

### 6. Changes to realtimmenet_labels.json 
Change the realtimmenet_labels.json file to reflect the outputs of your converted model.
By default, this file is filled with classes for the gesture control.

### 7. Build the project and enjoy it
The code is ready, build the project and enjoy the result on your device. 



## License 

The code is copyright (c) 2020 Twenty Billion Neurons GmbH under an MIT Licence. See the file LICENSE for details. Note that this license 
only covers the source code of this repo. Pretrained weights come with a separate license available [here](https://20bn.com/licensing/sdk/evaluation).

This repo uses PyTorch, which is licensed under a 3-clause BSD License. See the file LICENSE_PYTORCH for details.
