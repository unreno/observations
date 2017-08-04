# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

Initial setup 

As root ...
useradd jakewendt
passwd jakewendt
usermod -aG sudo jakewendt
usermod -s /bin/bash jakewendt
sudo mkdir /home/jakewendt
sudo chown jakewendt /home/jakewendt
sudo vi /etc/network/interfaces
reboot
sudo dpkg-reconfigure openssh-server


As jakewendt
ln -s github/jakewendt/my/init/gitconfig .gitconfig
ln -s github/jakewendt/my/init/inputrc .inputrc
ln -s github/jakewendt/my/init/vim .vim
ln -s github/jakewendt/my/init/vimrc .vimrc
vi .bash_profile


sudo apt install ruby ruby-dev r-base curl libcurl4-openssl-dev libssl-dev libssh2-1-dev pkg-config software-properties-common python-software-properties libssl-dev


sudo apt full-upgrade

sudo reboot

ln -s ~/github/unreno/observations
cd observations
sudo cp bin/observations_passenger /etc/init.d/
sudo update-rc.d observations_passenger defaults

gem install bundler
#		or
gem update bundler


#	I don't use them , but they are in the Gemfile
sudo apt install mysql-client mysql-server libmysqld-dev libmysqlclient-dev sqlite3 libsqlite3-dev


bundle install


cp config/secrets.yml.original config/secrets.yml
race secret
vi config/secret.yml

cp config/database.yml.original config/database.yml
vi config/database.yml

FROM my mac ... scp github/unreno/observations/misc/Observations-20170302.tsv chirp:observations/misc/


chmod 755 misc/Observations-20170302.tsv
rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=1 ; rake db:create ; rake db:migrate ; rake db:seed

sudo reboot





### Updating


After an update, restarting or stopping/starting sometimes takes a very long time.
The system seems to run out of memory because something is buffered or cached.
One of the following helps. Not sure which yet though.

```BASH
sudo service observations_passenger stop


sudo sh -c "free && sync && echo 1 > /proc/sys/vm/drop_caches && free"

sudo sh -c "free && sync && echo 2 > /proc/sys/vm/drop_caches && free"

sudo sh -c "free && sync && echo 3 > /proc/sys/vm/drop_caches && free"


sudo service observations_passenger start
```



