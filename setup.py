from setuptools import setup, find_packages

setup(
    name='mai_python_internals', 
    version='1.0', 
    package_dir={'': 'lib'},
    packages=find_packages(where="lib")
    )
