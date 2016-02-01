# Installerer på Linode

Oppretter ny linode med CentOS 7.
Root-passordet lagres i keepass databasen.

Logger inn som root og kjører update: 

    $ ssh root@139.162.217.217
    # hostnamectl set-hostname bc1
    # timedatectl set-timezone Europe/Oslo
    
    # sudo yum update
    
## Opprette bruker

    # useradd bjorn && passwd bjorn
    # usermod -aG wheel bjorn    


Fra egen laptop:

    $ brew install ssh-copy-id
    $ ssh-copy-id bjorn@139.162.217.217

Legger til i .ssh/config:

    Host bc
      Hostname 139.162.217.217
      User bjorn

Kan deretter logge på slik:

    $ ssh bc

Oppretter også brukeren bc, med sudo rettigheter, og kopierer over /home/bjorn/.ssh/authorized keys

## Ikke logge inn med passord eller root

Redigerer /etc/ssh/sshd_config og setter disse: 

    PermitRootLogin no
    PasswordAuthentication no

Deretter restarter jeg sshd: 

    $ sudo systemctl restart sshd

## brannmur

    $ sudo yum install iptables-services
    $ sudo systemctl enable iptables


Oppretter /etc/iptables.firewall.rules med innhold: 

    *filter
    #  Allow all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0
    -A INPUT -i lo -j ACCEPT
    -A INPUT -d 127.0.0.0/8 -j REJECT
    #  Accept all established inbound connections
    -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    #  Allow all outbound traffic - you can modify this to only allow certain traffic
    -A OUTPUT -j ACCEPT
    #  Allow HTTP and HTTPS connections from anywhere (the normal ports for websites and SSL).
    #-A INPUT -p tcp --dport 80 -j ACCEPT
    #-A INPUT -p tcp --dport 443 -j ACCEPT
    #  Allow SSH connections
    #
    #  The -dport number should be the same port number you set in sshd_config
    #
    -A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT
    #  Allow ping
    -A INPUT -p icmp -j ACCEPT
    #  Log iptables denied calls
    -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7
    #  Drop all other inbound - default deny unless explicitly allowed policy
    -A INPUT -j DROP
    -A FORWARD -j DROP
    COMMIT

Aktiverer og sjekker at er tatt i bruk: 

    sudo iptables-restore < /etc/iptables.firewall.rules
    sudo iptables -L

Lagrer så disse reglene aktiveres når maskinen booter: 

    sudo /sbin/service iptables save
    iptables: Saving firewall rules to /etc/sysconfig/iptables:[  OK  ]

Setter også parametrene IPTABLES_SAVE_ON_STOP og IPTABLES_SAVE_ON_RESTART til "yes" i filen/etc/sysconfig/iptables-config.


Booter og sjekker når den kommer opp at reglene er i bruk:

    $ sudo iptables -L

Velger å også enable firewalld (brukes i puppet-modulene til å åpne porter): 

    $ sudo systemctl start firewalld
    $ sudo systemctl enable firewalld

## Installasjoner

### Ruby, puppet, git, osv...

    $ sudo yum install ruby
    $ sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
    $ sudo yum install puppet
    $ sudo yum install git    

# Kloner Catalogue of Life prosjektet fra git

Logget inn som bjorn på bc1: 

    $ git clone https://github.com/Biocaching/catalogue_of_life.git
    $ cd catalogue_of_life
    $ sudo puppet apply provisioning/manifests/server.pp --modulepath provisioning/modules

Konfigurere Rails-applikasjonen: 

    $ bundle install
    $ rake db:create
    $ RAILS_ENV=production rake db:create
    $ rake db:migrate

Lag secret-key med rake: 

    $ rake secret

Legg til i ~/.bash_profile: 

    export SECRET_KEY_BASE="a315e13f71b9d8cf976b665857f287a7ad0f09c261aee74dfb992b6b5576bdc37a699f65475bd9bed7a97fb6ffc73c6a5933a933a3b769b69ae82864363f2a9b"_
    export SPECIESDB_DATABASE_PASSWORD=<passord>
    export RAILS_ENV=production

(husk å lagre passordet i keepass)

Logg ut og inn så verdiene blir satt. 

Importere data fra COL (alle kingdoms og så chordata (ryggstrengdyr)): 

    $ rake col:import_top_levels
    $ rake col:import[22032976]

Opprette indeks i Elasticsearch (får feilmelding første gang denne kjøres): 

    $ ./scripts/re_create_es_index.sh 

Indeksere ett artsnavn i Elasticsearch:

    $ rake es:import_one

Indeksere alle artsnavn i Elasticsearch: 

    $ rake es:import_all

For å kunne kjøre i passenger, må det settes rettigheter: 

    $ cd /home
    $ chmod a+rx bc
    $ cd
    $ chmod -R a+rx catalogue_of_life

### Autentisering

Legger til basic authentication ved å legge til i /etc/httpd/conf.d/speciesdb_prod.conf:

    AuthType Basic
    AuthName "Authentication Required"
    AuthUserFile "/etc/.htpasswd"
    Require valid-user

Og kommenterer ut "Require all granted" nederst

Og lager passord: 

    sudo htpasswd -c /etc/.htpasswd bc
(Passord: "Oslo2016")

Kan kalle tjenesten slik: 

    $ curl --user bc:Oslo2016 "http://api.biocaching.com:81/taxa?format=json&term=gorilla&size=2"
