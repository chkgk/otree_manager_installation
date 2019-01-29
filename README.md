# oTree Manager installation scripts

This repository contains script(s) to automate the installation of oTree Manager. To learn more about oTree Manager, please head over to <http://docs.otree-manager.com> or take a look at the source code at <https://github.com/otree-manager/otree_manager>.


To install oTree Manager clone this repository to a machine running a fresh Debian 9 installation. Then, run the setup script with super user privileges. 

Note: The installation script is specifically written for Debian 9.

Installation from this repository (skip the first two lines if git is installed already):
```bash
$ sudo apt update
$ sudo apt install git
$ git clone https://github.com/otree-manager/otree_manager_installation.git
$ cd otree_manager_installation
$ sudo bash ./otree_manager_setup.sh
``` 


Known issues:
* Sometimes nginx and supervisor need to be reloaded manually for the worker process to actually respond to tasks. I recommend to run ``sudo service supervisor restart`` and ``sudo service nginx restart`` manually after the installation completes.