import urllib.request
import platform
import os
import tkinter
import tkinter.messagebox
import subprocess


def programInstall(url, path):
    top = tkinter.Tk()
    canvas1 = tkinter.Canvas(top)
    canvas1.create_text(200, 50, text="This program can benifit from GPU accleration. \n Would you like to install the additional program to leverage that?", fill="black", font=('Helvetica 8'))
    canvas1.pack()
    #if user choses to skip the installation of cuda
    def install():
        tkinter.messagebox.showinfo("Downloading File", "Downloading File")
        top.destroy()
        if os.path.exists(path) == False:
            urllib.request.urlretrieve(url, path)
        os.startfile(path)
    #if user choses to skip the installation of cuda
    def skip():
        tkinter.messagebox.showinfo("Skipping Installation", "Skipping Installation")
        top.destroy()
    #Buttons for user to click on.
    B1 = tkinter.Button(top, text = "Install", command = install)
    B1.pack()
    B2 = tkinter.Button(top, text = "Skip", command = skip)
    B2.pack()
    top.mainloop()

#Creates the file in the users folder where the program is located.
simp_path = 'NvidiaCUDA.exe'
abs_path = os.path.abspath(simp_path)
try:
    subprocess.check_output('nvidia-smi')
    if platform.system() == "Windows":
        #CUDA Windows URL is the same for both Windows 10 and Windows 11
        winUrl = 'https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_516.01_windows.exe'
        programInstall(winUrl, abs_path)
    #for future use. lines of code needed to run cuda install on linux. 
    #elif platform.system() == "Linux":
    #    runscript = 'wget https://developer.download.nvidia.com/compute/cuda/11.7.0/local_installers/cuda_11.7.0_515.43.04_linux.run \n sudo sh cuda_11.7.0_515.43.04_linux.run'
    #    os.system(runscript)
except Exception: # this command not being found can raise quite a few different errors depending on the configuration
    print('No Nvidia GPU in system!')
