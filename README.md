# 20bn-realtimenet-iOS

20bn-realtimenet-iOS is the iOS version of [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet).
You can convert some pytorch models from [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) and run them on an iOS device. 
Currently, only our gesture detection demo using our efficientnet backbone is available for conversion. More will come soon.

The efficientnet backbone was confirmed to run smoothly on iOS devices with A11 chips (e.g. iPhone 8 or higher). 
It might also work on devices with A10 chips (e.g. iPad 6/7, iPhone 7).

## Getting Started

### 1. Clone the Repository

To begin, clone this repository to a local directory of your choice:

```shell
git clone https://github.com/TwentyBN/20bn-realtimenet-iOS.git
```

### 2. Clone and Install the 20bn-realtimenet Repository

You will need [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) to convert Pytorch models to CoreML. 
Clone it:

```shell
git clone https://github.com/TwentyBN/20bn-realtimenet.git
cd 20bn-realtimenet
```

and follow the instructions to install dependencies.

### 3. Download our pretrained models and convert them to CoreML

First, download our pretrained models (see instructions in 20bn-realtimenet, you will have to agree our terms and conditions).
Then, use the following script to produce a CoreML version of our gesture control demo:

```shell
python scripts/conversion/convert_to_coreml.py --backbone=efficientnet --classifier=efficient_net_gesture_control --output_name=realtimenet
```

The should produce the following CoreML file: `20bn-realtimenet/resources/coreml/realtimenet.mlmodel`.

### 4. Copy the converted model into this repo

Move the produced CoreML file from `20bn-realtimenet` to `20bn-realtimenet-iOS` 
and place it in the following location: `20bn-realtimenet-iOS/20bn-realtimenet-iOS/realtimenet.mlmodel`

### 5. Build the project and have fun

Everything should be ready now, build the project and have fun. 

## License 

The code is copyright (c) 2020 Twenty Billion Neurons GmbH under an MIT Licence. See the file LICENSE for details. Note that this license 
only covers the source code of this repo. Pretrained weights come with a separate license available [here](https://20bn.com/licensing/sdk/evaluation).

This repo uses PyTorch, which is licensed under a 3-clause BSD License. See the file LICENSE_PYTORCH for details.
