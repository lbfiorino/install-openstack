
#!/usr/bin/python3

# https://docs.openstack.org/python-novaclient/latest/user/python-api.html
# https://docs.openstack.org/python-novaclient/latest/reference/index.html
# https://docs.openstack.org//python-novaclient/latest/doc-python-novaclient.pdf

import json
import os
import datetime
import uuid
import sys
import time
import urllib3

from keystoneauth1.identity import v3
from keystoneauth1 import session
from novaclient import client as nova_client

# Disable SSL Warnings when using self-signed certificates
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# API
IDENTITY_API = "https://<openstack_server_api>:5000/v3"

# OpenStack User and Project. From the OpenRC file.
PROJECT_NAME = ""
PROJECT_DOMAIN_ID = "default"
USER_DOMAIN_NAME = "Default"
USERNAME = ""
PASSWORD = ""

auth = v3.Password(auth_url=IDENTITY_API,
                   username=USERNAME,
                   password=PASSWORD,
                   project_name=PROJECT_NAME,
                   user_domain_name=USER_DOMAIN_NAME,
                   project_domain_id=PROJECT_DOMAIN_ID)
# Create a session with the credentials
sess = session.Session(auth=auth, verify=False)
# Create nova client with the session created
nova = nova_client.Client(version='2.1', session=sess)

# Get hypervisor statistics over all compute nodes
stats = nova.hypervisor_stats.statistics()._info

# Get a list of hypervisors
hypervisors = nova.hypervisors.list()

print("\n")
print("CLOUD STATISTICS:")
print("-----------------")
for k in stats:
    print("{:>15}: {}".format(k, stats[k]))


print("\n")
print("HYPERVISORS INFO:")
print("-----------------")
for h in hypervisors:
    hinfo = h._info
    for i in hinfo:
        print("{:>25}: {}".format(i, hinfo[i]))
    print("\n")


