# Metacognition Artificial Intelligence

A Flutter and Python project to visually educate users how to build AI using TensorFlow and Keras

## Getting Started in Flutter

Follow the instructions on <https://docs.flutter.dev/get-started/install> for your system and then clone this repository into a directory of your choosing.

Verify that you have setup your environment correctly by running the application. (Note that the build process can take up to a minute)

## Getting Started in Python

Setup a Python 3.9.10 venv in your workspace by running `python -m venv .venv` in your workspace.

If you are on Windows and VS Code, close all your terminals and open a new terminal. If an error appears open a PowerShell window in Administrator mode and execute the following command: `Set-ExecutionPolicy RemoteSigned`. Then reopen a terminal window.

### Install required Python packages

Run `python -m pip install --upgrade pip`. This is required, it doesn't just make it look cooler.
Then run `pip install -r requirements.txt`.
This will take care of most of the heavy lifting for you.

## GPU Setup (Optional)

If you have a compatible [Nvidia](https://developer.nvidia.com/cuda-gpus) (Steps [2](https://developer.nvidia.com/cuda-toolkit-archive) and [3](https://developer.nvidia.com/rdp/cudnn-archive)) or [AMD](https://medium.com/analytics-vidhya/install-tensorflow-2-for-amd-gpus-87e8d7aeb812) GPU, please go to the respective website and install the components necessary for Python to leverage your GPU in AI calculations. Note that this is not necessary but it will be beneficial if you are creating/testing anything beyond a very small model.

Eventually we will want to natively detect if the system running our app has a TensorFlow compatible GPU for the AI and redirect the user to the appropriate website to install those components.
