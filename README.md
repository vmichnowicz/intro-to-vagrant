# Intro

> Vagrant provides easy to configure, reproducible, and portable work environments built on top of industry-standard technology and controlled by a single consistent workflow to help maximize the productivity and flexibility of you and your team.

## Required

* [Virtual Box](https://www.virtualbox.org/wiki/Downloads)
* [Vagrant](http://downloads.vagrantup.com/)
* [Putty](http://the.earth.li/~sgtatham/putty/latest/x86/putty.exe) (Only if you are using Windows)
* [Puttygen](http://the.earth.li/~sgtatham/putty/latest/x86/puttygen.exe) (Only if you are using Windows)

## Get ready...

This guide will walk you through setting up a very basic Vagrant setup. At the end you should have a basic Ruby application that can pull images from the host computer and serve them to a web page. The server will also be fully provisioned by Vagrant. The project directories at the completion of each step is included in this repository (`step_1`, `step_2`, `step_3`, and `step_4`).

# Step One

Open up a terminal and type the following to create a new Vagrant box. We will will create a Vagrant box based on Ubuntu Precise [Pangolin](http://en.wikipedia.org/wiki/File:Tree_Pangolin.JPG). There are many different base boxes [available through Vagrant](http://www.vagrantbox.es/). 

````
vagrant box add precise32 http://files.vagrantup.com/precise32.box
````

After we have downloaded a base box we need to create a new folder and then initializes that directory to be a Vagrant environment. This will essentially copy our base box and allow us to modify for our new project (all without changing our original base box).

`````
mkdir barcamp
cd barcamp
vagrant init precise32
vagrant up
````

Running `vagrant init` will create a `Vagrantfile` in our project directory containing all configuration related to this Vagrant instance. Now that we have our new box up and running we can SSH into it. If you are on Windows this part is a little weird. If you are using the standard Windows shell you have to use something like Putty to actually SSH into your box. Another option is to use the shell that comes with GitHub for Windows.

By default Vagrant creates a new folder on our box, `/vagrant` which is mapped to our project directory on our host machine. There is also a vagrant user and user home directory in `/home/vagrant`. Let's start by creating a file in `/vagrant'.

````
vagrant ssh
cd /vagrant
touch hello.world
echo 'Hello World!' >> hello.world
tail -f hello.world
````

Now, in your host system you should see a new file `hello.world` inside your Vagrant project directory. Open this file up and add some random text (like "Vagrant is cool!".

Now if you go back to your SSH session inside the Vagrant box you should notice that our `tail` picked up the changes to `hello-world.txt`. Press `CTRL + C to exit tail`.

# Step Two

Vagrant allows you to easily share directories on your host machine with directories on your guest virtual machine. Vagrant calls these *synced folders*.

On your host machine open up a terminal and type the following to create a new folder in your home directory:

````
cd ~ 
mkdir random-images
cd random-images
```

Next, let's grab some random images. Any `*.jpg` image will do. If you are awesome and have wget then the commands below will work. On OS X you can get wget with Hombrew `brew install wget`.

````
wget http://lorempixel.com/500/500/ -O random-1.jpg
wget http://lorempixel.com/500/500/ -O random-2.jpg
wget http://lorempixel.com/500/500/ -O random-3.jpg
wget http://lorempixel.com/500/500/ -O random-4.jpg
wget http://lorempixel.com/500/500/ -O random-5.jpg
````

Then add the following to line to your `Vagrantfile`. This line will map `~/random-images` on our host machine, to `/vagrant/public/random-images` on our guest (Ubuntu Precise 32).

````
config.vm.synced_folder("~/random-images", "/vagrant/public/random-images", :create => true)
````

Run `vagrant reload` to restart the virtual machine. After restarting you can SSH back in and navigate to `/vagrant/public/random-images` and view all of the random images.

# Step Three

You can provision your Vagrant server with:

* Shell scripts
* Puppet
* Chef

We are only going to mess with shell scripts. Add following line in your `Vagrantfile`:

````
config.vm.provision :shell, :path => "script.sh"
````

Then create a new file `script.sh` in your project directory. In this file place the following:

````
gem install sinatra
````

This shell script will be run each time we boot up our Vagrant box. For our example project we are only going to be using [Sinatra](http://www.sinatrarb.com/). But if we needed any additional software we could install it here. With the provisioning shell script complete we must either restart our Vagrant box or run `vagrant provision` to run the scripts.

````
vagrant provision
````

Now that our server has been provisioned we can create a really simple application. In the project root create a new file `barcamp.rb`.

````
require 'rubygems'
require 'sinatra'

# The default listen IP address for Sinatra is localhost not 0.0.0.0. This
# makes it so we cannot connect to this server from outside our virtual
# machine.
# http://www.sinatrarb.com/configuration.html#bind---server-hostname-or-ip-address
set :bind, '0.0.0.0'

get '/' do
  @file_names = []

  # Loop through all of the .jpg files in the random-images directory
  Dir.glob('/vagrant/public/random-images/*.jpg', File::FNM_CASEFOLD) do |filename|
    @file_names.push File.basename(filename)
  end

  erb :index
end
````

Next, we need to create a new directory `views` and inside that folder a new file `index.erb`.

````
<html>
<head>
  <title>Tampa BarCamp 2013 | Intro to Vagrant</title>
</head>
<body>
  <% @file_names.each do |file_name| %>
    <img src="/random-images/<%= file_name %>" width="100px">
  <% end %>
</body>
</html>
````

Now, in an SSH session in our virtual machine navigate to `/vagrant` and run the following:

````
ruby barcamp.rb
````

This should start up our Sinatra application and you should see something like this:

````
vagrant@precise32:/vagrant$ ruby barcamp.rb
[2013-09-28 02:03:50] INFO  WEBrick 1.3.1
[2013-09-28 02:03:50] INFO  ruby 1.8.7 (2012-02-08) [i686-linux]
== Sinatra/1.4.3 has taken the stage on 4567 for development with backup from WEBrick
[2013-09-28 02:03:50] INFO  WEBrick::HTTPServer#start: pid=1219 port=4567
````

As you can see our application is running on port 4567. 

# Step Four

With our application running on our virtual machine we currently have no way of accessing it through a web browser. The answer to this problem is port forwarding. If you noticed, when we ran `vagrant up` a port was already being forwarded.

````
[default] Clearing any previously set network interfaces...
[default] Preparing network interfaces based on configuration...
[default] Forwarding ports...
[default] -- 22 => 2222 (adapter 1)
````

By default Vagrant forwards port 22 on the guest to port 2222 on the host. This allows us to SSH into our guest machine. We need to setup another forwarded port for port 4567 on our guest virtual machine.

In the `Vagrantfile` add the following:

````
config.vm.network :forwarded_port, guest: 4567, host: 8080
````

This will forward port 8080 on our host machine to port 4567 on our guest. Next, restart the VM.

````
vagrant reload
````

If you look at the console you should now see a new line of output:

````
[default] -- 4567 => 8080 (adapter 1)
````

Now SSH into the VM with `vagrant ssh`, navigate to `/vagrant`, and run `ruby barcamp.rb`. This should again start our Sinatra application. With our port forwarding setup we should now be able to open up a web browser and navigate to http://localhost:8080 and view our new application.

When we are done with this project we can run `vagrant destroy` to remove the clone of our base box. This will free up space on your computer. When you need to start work on the project again, just run `vagrant up` and it will create a new clone of the base box for you. And will all our provisioning setup we will not have to configure anything manually. This creates a very portable format for applications.

# Caveats

It's not all rainbows and butterflies and you are still dependent in part on the capabilities of host system. Some problems can arise with:
 
 * Case-insensitive file systems (Windows NTFS and OS X HFS+ by default)
 * Symlinks (Windows)
 * Reliance on NFS

## MeteorJS

MeteorJS has [some issues](https://github.com/meteor/meteor/issues/1103) with Vagrant and Windows.

> MongoDB had an unspecified uncaught exception.
> This can be caused by MongoDB being unable to write to a local database.
> Check that you have permissions to write to .meteor/local. MongoDB does
> not support filesystems like NFS that do not allow file locking.

## Symlinks

The following will not work with a Windows host:

````
ln -s ~ /vagrant/home
````

> "ln: failed to create symbolic link `/vagrant/home': Protocol error"

## Case-insensitive file systems

SSH into your Vagrant box and navigate to `/vagrant`. Try creating a file:

````
touch abc123.txt
````

Now try creating another file

````
touch ABC123.txt
````

# Links

* https://www.virtualbox.org/
* http://vagrantup.com/
* http://www.vagrantbox.es/
* http://docs-v1.vagrantup.com/v1/docs/base_boxes.html
