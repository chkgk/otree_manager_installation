# oTree Manager installation scripts

This repository contains script(s) to automate the installation of oTree Manager. To learn more about oTree Manager, please head over to <http://docs.otree-manager.com> or take a look at the source code at <https://github.com/chkgk/otree_manager>.


To install oTree Manager clone this repository to a machine running a fresh Debian 9 installation. Then, run the setup script with super user privileges. 

Installation from this repository (requires Git to be installed):
```bash
$ git clone https://github.com/chkgk/otree_manager_setup.git
$ cd otree_manager_setup
$ sudo bash ./otree_manager_setup.sh
``` 

Alternatively, if you do not have git installed, you can also download the script from my website. It is a copy of the one in this repository.

To install without having Git installed:
```bash 
$ wget https://ckgk.de/otree_manager_setup.sh
$ sudo bash ./otree_manager_setup.sh
```

Known issues:
* Sometimes nginx and supervisor need to be reloaded manually for the worker process to actually respond to tasks. I recommend to run ``sudo service supervisor restart`` and ``sudo service nginx restart`` manually after the installation completes.