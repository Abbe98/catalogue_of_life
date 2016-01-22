#!/bin/sh
sudo puppet apply provisioning/manifests/server.pp --modulepath provisioning/modules

