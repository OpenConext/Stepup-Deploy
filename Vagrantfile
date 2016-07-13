# Copyright 2014 SURFnet bv
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

required_directories = [
    "simplesamlphp",
    "Stepup-Gateway",
    "Stepup-Middleware",
    "Stepup-RA",
    "Stepup-SelfService"
]

Vagrant.configure("2") do |config|

    required_directories.each {|dir| raise_error_if_not_dir(dir)}

    # Application Server, naming apps for convenience ;)
    config.vm.define "stepup-apps", primary: true do |apps|
        apps.vm.box = "jayunit100/centos7"
        apps.vm.hostname = "stepup-apps"
        apps.vm.network :private_network, ip: "10.10.0.100"

        apps.vm.provider :virtualbox do |vb|
            vb.name = "Stepup Applications"
            vb.memory = 1024
        end

        apps.vm.synced_folder "./", "/vagrant", type: "nfs"
        if which('ansible-playbook')
            apps.vm.provision "ansible" do |ansible|
                ansible.playbook = "ansible/stepup.yml"
                ansible.inventory_path = "ansible/inventories/development"
                ansible.limit = "stepup-apps"
            end
        else
            apps.vm.provision :shell, inline: "env PLAYBOOK=ansible/stepup.yml ansible/windows.sh"
        end

        # Mount shared folders after provisioning
        # https://github.com/mitchellh/vagrant/issues/936#issuecomment-7179034
        apps.vm.synced_folder "../Stepup-Middleware",  "/var/www/mw-dev.stepup.coin.surf.net"
        apps.vm.synced_folder "../Stepup-Gateway",     "/var/www/gw-dev.stepup.coin.surf.net"
        apps.vm.synced_folder "../Stepup-SelfService", "/var/www/ss-dev.stepup.coin.surf.net"
        apps.vm.synced_folder "../Stepup-RA",          "/var/www/ra-dev.stepup.coin.surf.net"
        apps.vm.synced_folder "../simplesamlphp",      "/var/www/idp-dev.stepup.coin.surf.net"
        apps.vm.provision :shell, run: "always", inline: "mount -t vboxsf -o uid=middleware,gid=middleware   var_www_mw-dev.stepup.coin.surf.net /var/www/mw-dev.stepup.coin.surf.net"
        apps.vm.provision :shell, run: "always", inline: "mount -t vboxsf -o uid=gateway,gid=gateway         var_www_gw-dev.stepup.coin.surf.net /var/www/gw-dev.stepup.coin.surf.net"
        apps.vm.provision :shell, run: "always", inline: "mount -t vboxsf -o uid=selfservice,gid=selfservice var_www_ss-dev.stepup.coin.surf.net /var/www/ss-dev.stepup.coin.surf.net"
        apps.vm.provision :shell, run: "always", inline: "mount -t vboxsf -o uid=ra,gid=ra                   var_www_ra-dev.stepup.coin.surf.net /var/www/ra-dev.stepup.coin.surf.net"
        apps.vm.provision :shell, run: "always", inline: "mount -t vboxsf -o uid=simplesaml,gid=simplesaml   var_www_idp-dev.stepup.coin.surf.net /var/www/idp-dev.stepup.coin.surf.net"
        apps.vm.provision :shell, run: "always", inline: "pkill mailcatcher || true"
        apps.vm.provision :shell, run: "always", inline: "/usr/local/bin/mailcatcher --ip=0.0.0.0"
    end

    config.vm.define "stepup-logging" do |logging|
        logging.vm.box = "ubuntu/trusty64"
        logging.vm.hostname = "stepup-logging"
        logging.vm.network :private_network, ip: "10.10.0.101"

        logging.vm.provider :virtualbox do |vb|
            vb.name = "Stepup Logging"
            vb.memory = 2048
        end

        # install common packages
        if which('ansible-playbook')
            logging.vm.provision "ansible" do |ansible|
                ansible.playbook = "ansible/graylog.yml"
                ansible.inventory_path = "ansible/inventories/development"
                ansible.limit = "all"
            end
         else
            logging.vm.provision :shell, inline: "env PLAYBOOK=ansible/graylog.yml ansible/windows.sh"
        end

        # see http://docs.graylog.org/en/2.0/pages/installation/vagrant.html
        # adapted for our needs
        $script = <<SCRIPT
            apt-get update
            echo 'Going to download Graylog, this may take some time...'
            curl -S -s -L -O https://packages.graylog2.org/releases/graylog-omnibus/ubuntu/graylog_latest.deb
            dpkg -i graylog_latest.deb
            rm graylog_latest.deb
            graylog-ctl set-external-ip http://127.0.0.1:12900
            graylog-ctl set-admin-username admin
            graylog-ctl set-admin-password password
            graylog-ctl set-timezone "Europe/Amsterdam"
            graylog-ctl reconfigure
SCRIPT

        logging.vm.provision "shell", inline: $script
    end
end

# Check to determine whether we're on a windows or linux/os-x host,
# later on we use this to launch ansible in the supported way
# source: https://stackoverflow.com/questions/2108727/which-in-ruby-checking-if-program-exists-in-path-from-ruby
def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable? exe
        }
    end
    return nil
end

# Define custom error with non-translated message
class StepupError < Vagrant::Errors::VagrantError
    def initialize(dir);
        @dir = dir
        super()
    end

    def error_message; "Directory " + @dir + " must exist before being able to use the VMs correctly" end
end

def raise_error_if_not_dir(directory)
    _to_check = File.dirname(__FILE__) + "/../" + directory
    unless Dir.exists?(_to_check)
        raise StepupError.new(_to_check)
    end
end
