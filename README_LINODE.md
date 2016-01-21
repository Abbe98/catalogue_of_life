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

Velger å også enable firewalld: 

    $ sudo systemctl start firewalld
    $ sudo systemctl enable firewalld

## Installasjoner

### Ruby og puppet

    $ sudo yum install ruby
    $ sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
    $ sudo yum install puppet    

# Kopierer over Catalogue of Life prosjektet

Fra egen laptop: 

    $ pwd
    $ rsync -ac