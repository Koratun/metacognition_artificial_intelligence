# Metacognition Artificial Intelligence

A Flutter and Python project to visually educate users how to build AI using TensorFlow and Keras. Please make sure you have around 5GB of space available on your device. (Eventually you will need more, perhaps another 1 or 2 GB for the AI)

Note that even if you are only working on Flutter, you still need to setup python even if you don't write code in it.

Python devs also need to setup Flutter so they can test their backend changes through the UI (as well as testing through the code).

Please ensure that git is installed and you can manage git branches. For VSCode I like the Git Graph and GitLens extensions in tandem with the normal GitHub extensions.

## Getting Started in Flutter

Follow the instructions on <https://docs.flutter.dev/get-started/install> (Feel free to skip the setup for Android and Web sections) for your system and then clone this repository into a directory of your choosing. Note that around 2.5 GB will be taken up by flutter and this repository is about 600MB at the time I wrote this -- minus the python libraries.

Verify that you have setup your environment correctly by running the application. (Note that the build process can take up to a minute and will most definitely take longer the first time you run the app) 

Ignore any errors you may see about Python if you haven't setup python yet.

## Getting Started in Python

Setup a Python 3.9.10 venv in your workspace by running `python -m venv .venv` in your workspace. Obviously, install 3.9.10 if you haven't done so already.

If you are on Windows and VS Code, close all your terminals and open a new terminal. If an error appears, open a PowerShell window in Administrator mode and execute the following command: `Set-ExecutionPolicy RemoteSigned`. Then reopen a terminal window.

### Install required Python packages

Run `python -m pip install --upgrade pip`. This is required, it doesn't just make it look cooler.

Then run `pip install -r requirements.txt`. (Note that around 1.4GB of space will be taken up here).

This will take care of most of the heavy lifting for you.

## GPU Setup (Optional)

If you have a compatible [Nvidia](https://developer.nvidia.com/cuda-gpus) (Steps [2](https://developer.nvidia.com/cuda-toolkit-archive) and [3](https://developer.nvidia.com/rdp/cudnn-archive)) or [AMD](https://medium.com/analytics-vidhya/install-tensorflow-2-for-amd-gpus-87e8d7aeb812) GPU, please go to the respective website and install the components necessary for Python to leverage your GPU in AI calculations. Note that this is not necessary but it will be beneficial if you are creating/testing anything beyond a very small model.

Eventually we will want to natively detect if the system running our app has a TensorFlow compatible GPU for the AI and redirect the user to the appropriate website to install those components.

# Working in the Codebase

## Working with schemas

If you need to change a schema in python, notify myself and those working on the frontend. They need to know that the data you are sending them is going to change.
If you need to add/remove/change something in a schema and you are on the frontend team, notify myself and we will make a card in Trello so someone on the backend can work on it (which I will probably just do anyway to expedite the process). 

### **_DO NOT TOUCH THE SCHEMAS ON THE DART SIDE!!!_** 
They are autogenerated for us based on the schemas the backend has created.

### Schema autogeneration

If you are working in python and you change a schema or enum in any way, you must then run the following commands:

`python pydantic-dart-converter.py`

`flutter pub run build_runner build`

This will first take the python schemas and create/overwrite their dart equivalents. The next command will take those newly created dart schemas and flesh them out for use by the frontend team.
