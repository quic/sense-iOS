# 20bn-realtimenet-iOS

This repository contains the iOS version of [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) which allows you to build an iOS demo app running the pytorch models after converting them to CoreML using the provided script. 

Currently, only our gesture detection demo using our efficientnet backbone is available for conversion with more to come soon.

The efficientnet backbone was confirmed to run smoothly on iOS devices with A11 chips (e.g. iPhone 8 or higher) and may also work on devices with A10 chips (e.g. iPad 6/7, iPhone 7).


![](gifs/realtimenetiOS_gesture.gif)

## Getting Started

The following steps will help you install the necessary components to get up and running in no time with your project. 

#### 1. Clone the repository

To begin, clone this repository, as well as [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet), to a local directory of your choice:

```shell
git clone https://github.com/TwentyBN/20bn-realtimenet-iOS.git
```

#### 2. Clone and install the 20bn-realtimenet repository

You will also need to clone [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) (we will use it to convert Pytorch models to CoreML):

```shell
git clone https://github.com/TwentyBN/20bn-realtimenet.git
cd 20bn-realtimenet
```

Next, follow the instructions for [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) to install dependencies.

#### 3. Download our pretrained models and convert them to CoreML

We will start by using our pre-trained models for this project. Once again, please follow the instructions in [20bn-realtimenet](https://github.com/TwentyBN/20bn-realtimenet) to access them (you will have to create an account and agree to our terms and conditions).

Once you have done so, the following script can be used to produce a CoreML version of our gesture control demo:

```shell
python scripts/conversion/convert_to_coreml.py --backbone=efficientnet --classifier=efficient_net_gesture_control --output_name=realtimenet
```

It should produce the following CoreML file: `20bn-realtimenet/resources/coreml/realtimenet.mlmodel`.

#### 4. Move the converted model to the correct location

The CoreML file created in the last step can be moved from `20bn-realtimenet` to `20bn-realtimenet-iOS` in the following location: `20bn-realtimenet-iOS/20bn-realtimenet-iOS/realtimenet.mlmodel`

```shell
# If you are in 20bn-realtimenet
mv ./resources/coreml/realtimenet.mlmodel ../20bn-realtimenet-iOS/20bn-realtimenet-iOS/realtimenet.mlmodel
```

#### 6. Build the project

You can now open the iOS project with xcode and build it to your device. Have fun!

## Modifying the model outputs

Using our transfer learning script, it is possible to further fine-tune the model to your own classification tasks. If you do so, you'll have to reflect the new outputs in various file in the iOS project: 

#### InferenceLocal.swift 
The number of model outputs must be updated in dimGlobalClassifier (default: 30 - number of labels in the gesture control task).

#### realtimmenet_labels.json 

By default, the dictionary in `realtimmenet_labels.json` contains the labels our model was trained on for the gesture control task. Replace these with the contents of the `label2int.json` file produced during training.

## Citation

We now have a [blogpost](https://medium.com/twentybn/towards-situated-visual-ai-via-end-to-end-learning-on-video-clips-2832bd9d519f) you can cite:

```bibtex
@misc{realtimenet2020blogpost,
    author = {Guillaume Berger and Antoine Mercier and Florian Letsch and Cornelius Boehm and Sunny Panchal and Nahua Kang and Mark Todorovich and Ingo Bax and Roland Memisevic},
    title = {Towards situated visual AI via end-to-end learning on video clips},
    howpublished = {\url{https://medium.com/twentybn/towards-situated-visual-ai-via-end-to-end-learning-on-video-clips-2832bd9d519f}},
    note = {online; accessed 23 October 2020},
    year=2020,
}
```

## License 

The code is copyright (c) 2020 Twenty Billion Neurons GmbH under an MIT Licence. See the file LICENSE for details. Note that this license 
only covers the source code of this repo. Pretrained weights come with a separate license available [here](https://20bn.com/licensing/sdk/evaluation).

This repo uses PyTorch, which is licensed under a 3-clause BSD License. See the file LICENSE_PYTORCH for details.
