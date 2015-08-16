#!/bin/bash
# Copyright 2015 Giuseppe Maxia
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# proof of concept  of operations for hub replacement
./node4/use -e "STOP  SLAVE FOR CHANNEL 'hub_node4'"
./node4/use -e "STOP  SLAVE "
./node4/use -e "RESET  SLAVE FOR CHANNEL 'hub_node4'"
./node4/use -e "RESET  SLAVE "
# HUB node4 port: 8382
# node node1 port: 8379
./node1/use -e "STOP  SLAVE FOR CHANNEL 'hub_node1'"
./node1/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8382, MASTER_AUTO_POSITION=1 for channel 'hub_node1'"
./node4/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8379, MASTER_AUTO_POSITION=1 for channel 'node1_hub'"
./node4/use -e "START SLAVE FOR CHANNEL 'node1_hub'"
./node1/use -e "START SLAVE FOR CHANNEL 'hub_node1'"
# node node2 port: 8380
./node2/use -e "STOP  SLAVE FOR CHANNEL 'hub_node2'"
./node2/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8382, MASTER_AUTO_POSITION=1 for channel 'hub_node2'"
./node4/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8380, MASTER_AUTO_POSITION=1 for channel 'node2_hub'"
./node4/use -e "START SLAVE FOR CHANNEL 'node2_hub'"
./node2/use -e "START SLAVE FOR CHANNEL 'hub_node2'"
# node node5 port: 8383
./node5/use -e "STOP  SLAVE FOR CHANNEL 'hub_node5'"
./node5/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8382, MASTER_AUTO_POSITION=1 for channel 'hub_node5'"
./node4/use -e "CHANGE MASTER TO master_host='127.0.0.1', master_user='rsandbox', master_password='rsandbox', master_port=8383, MASTER_AUTO_POSITION=1 for channel 'node5_hub'"
./node4/use -e "START SLAVE FOR CHANNEL 'node5_hub'"
./node5/use -e "START SLAVE FOR CHANNEL 'hub_node5'"
