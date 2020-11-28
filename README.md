<div align="center">

<img src="https://raw.githubusercontent.com/TwentyBN/20bn-realtimenet-ios/beautification-phase1/docs/imgs/temp_realtimenetios_header_1.png" height="70px">

**State-of-the-art Real-time Action Recognition for iOS**

---

<!-- TABLE OF CONTENTS -->
<p align="center">
  <a href="https://www.20bn.com/">Website</a> •
  <a href="https://medium.com/twentybn/towards-situated-visual-ai-via-end-to-end-learning-on-video-clips-2832bd9d519f">Blogpost</a> •  
  <a href="#getting-started">Getting Started</a> •
  <a href="#deploy-your-own-classifier">Deploy Your Own Classifier</a> •
  <a href="https://20bn.com/products/datasets">Datasets</a> •   
  <a href="https://20bn.com/licensing/sdk/evaluation">SDK License</a>
</p>

<!-- BADGES -->
<p align="center">
    <a href="https://20bn.com/">
        <img alt="Documentation" src="https://img.shields.io/website/http/20bn.com.svg?down_color=red&down_message=offline&up_message=online">
    </a>
    <a href="https://github.com/TwentyBN/20bn-realtimenet/master/LICENSE">
        <img alt="GitHub" src="https://img.shields.io/github/license/TwentyBN/20bn-realtimenet.svg?color=blue">
    </a>
    <a href="https://github.com/TwentyBN/20bn-realtimenet/releases">
        <img alt="GitHub release" src="https://img.shields.io/github/release/TwentyBN/20bn-realtimenet.svg">
    </a>
    <a href="https://github.com/TwentyBN/20bn-realtimenet/blob/master/CODE_OF_CONDUCT.md">
        <img alt="Contributor Covenant" src="https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg">
    </a>
</p>

</div>

---

This repository contains the iOS version of [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) which allows you to build an iOS demo app running the pytorch models after converting them to CoreML using the provided script. 

You can convert and deploy the existing gesture detection model as is, or, use the transfer learning script in [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) to train on your own custom classification outputs on top of it. More models will be supported soon.

The model uses an efficientnet backbone and was confirmed to run smoothly on iOS devices with A11 chips (e.g. iPhone 8 or higher) and may also work on devices with A10 chips (e.g. iPad 6/7, iPhone 7).

<p align="center">
    <img src="https://raw.githubusercontent.com/TwentyBN/20bn-realtimenet-ios/beautification-phase1/docs/gifs/realtimenetiOS_gesture.gif" width="400px">
</p>

---

## Requirements and Installation

The following steps will help you install the necessary components to get up and running in no time with your project. 

#### Step 1: Clone this repository

To begin, clone this repository, as well as [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet), to a local directory of your choice:

```shell
git clone https://github.com/TwentyBN/20bn-realtimenet-iOS.git
```

#### Step 2: Clone and install the 20bn-realtimenet repository

You will also need to clone [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) (we will use it to convert Pytorch models to CoreML):

```shell
git clone https://github.com/TwentyBN/20bn-realtimenet.git
cd 20bn-realtimenet
```

Next, follow the instructions for [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) to install
 its dependencies.

#### Step 3: Download our pretrained models

You will need to download our pre-trained models to build the demo application. Once again, please follow the
 instructions in [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) to access them (you will have to create an account and agree to our terms and conditions).

--- 

## Getting Started

This section will explain how you can deploy our pre-trained models, or your own custom model, to an iOS application. 

#### Step 1: Converting a Pytorch model to CoreML

The iOS demo requires a CoreML version of our model checkpoint which you can produce using the script provided in
 `20bn-realtimenet` which, for our pre-trained gesture control model, can be run using:

```shell
python scripts/conversion/convert_to_coreml.py --backbone=efficientnet --classifier=efficient_net_gesture_control --output_name=realtimenet
```

You should now have the following CoreML file: `20bn-realtimenet/resources/coreml/realtimenet.mlmodel`.

#### Step 2: Move the converted model to the correct location

The CoreML file created in the last step can be moved from `20bn-realtimenet` to `20bn-realtimenet-iOS` in the following location: `20bn-realtimenet-iOS/20bn-realtimenet-iOS/realtimenet.mlmodel`

```shell
# If you are in 20bn-realtimenet
mv ./resources/coreml/realtimenet.mlmodel ../20bn-realtimenet-iOS/20bn-realtimenet-iOS/realtimenet.mlmodel
```

#### Step 3: Build the project

You can now open the iOS project with Xcode and build it to your device. Have fun!

---

## Deploy your own classifier

Using our transfer learning script, it is possible to further fine-tune our model to your own classification tasks. If
 you do so, you'll have to reflect the new outputs in various files in the iOS project: 

#### `20bn-realtimenet-iOS/InferenceLocal.swift` 
The number of model outputs must be updated in dimGlobalClassifier (default: 30 - number of labels in the gesture control task).

#### `20bn-realtimenet-iOS/realtimmenet_labels.json` 

By default, the dictionary in `realtimmenet_labels.json` contains the labels our model was trained on for the gesture control task. Replace these with the contents of the `label2int.json` file produced during training.

---

## Citation

We now have a [blogpost](https://medium.com/twentybn/towards-situated-visual-ai-via-end-to-end-learning-on-video-clips-2832bd9d519f) you can cite:

```bibtex
@misc{realtimenet2020blogpost,
    author = {Guillaume Berger and Antoine Mercier and Florian Letsch and Cornelius Boehm and 
              Sunny Panchal and Nahua Kang and Mark Todorovich and Ingo Bax and Roland Memisevic},
    title = {Towards situated visual AI via end-to-end learning on video clips},
    howpublished = {\url{https://medium.com/twentybn/towards-situated-visual-ai-via-end-to-end-learning-on-video-clips-2832bd9d519f}},
    note = {online; accessed 23 October 2020},
    year=2020,
}
```

---

## License 

The code is copyright (c) 2020 Twenty Billion Neurons GmbH under an MIT Licence. See the file LICENSE for details. Note that this license 
only covers the source code of this repo. Pretrained weights come with a separate license available [here](https://20bn.com/licensing/sdk/evaluation).
