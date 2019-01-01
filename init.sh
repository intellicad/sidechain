#!/bin/sh

cur=$(cd "$(dirname "$0")"; pwd)

echo === Set Parameters ===

cu1="cleos -u http://s1.eosvr.io:8888"
pubkey=EOS7xjXnjGoFv9dFPZirn6vziaKEmZhHjEcnsPJdFqZqXoEBaf1Ej
linker=eoslinker111

cd ~/git/eos/build/contracts

echo === Start to setup ===

${cu1} set contract eosio ./eosio.bios -p eosio

${cu1} create account eosio eosio.token $pubkey
${cu1} create account eosio eosio.ramfee $pubkey
${cu1} create account eosio eosio.ram $pubkey
${cu1} create account eosio eosio.stake $pubkey
${cu1} create account eosio eosio.saving $pubkey
${cu1} create account eosio eosio.bpay $pubkey
${cu1} create account eosio eosio.vpay $pubkey


echo === Issue EOS Token ===
${cu1} set contract eosio.token ./eosio.token -p eosio.token
${cu1} push action eosio.token create '{"issuer":"eosio","maximum_supply":"10000000000.0000 EOS","can_freeze":"0","can_recall":"0","can_whitelist":"0"}' -p eosio.token

${cu1} push action eosio.token issue '{"to":"eosio","quantity":"1000000000.0000 EOS","memo":"Issue all"}' -p eosio

echo === Set eosio.system ===
${cu1} set contract eosio ./eosio.system -p eosio

cd ${cur}

echo === Run deploy_contracts.js script to deploy contracts ===
node deploy_contracts.js

echo === Create linker account ===
${cu1} system newaccount eosio ${linker} $pubkey $pubkey  --stake-net '10 EOS' --stake-cpu "10 EOS" --buy-ram "10 EOS"

echo === Set issuer at side-chain ===
${cu1} push action eoslocktoken create '{"issuer":"eosio","maximum_supply":"1000000000.0000 EVD","can_freeze":"0","can_recall":"0","can_whitelist":"0"}' -p eoslocktoken

echo === Issue 1000 EVD token to linker ===
${cu1} push action eoslocktoken issue '{"to":"'${linker}'","quantity":"1000.0000 EVD","memo":"Issue to linker"}' -p eosio


echo === Set eosio.code permission, and set permission of contracts to eosio ===
${cu1} set account permission eoslocktoken active '{"threshold": 1,"keys": [],"accounts": [{"permission":{"actor":"eosio","permission":"active"},"weight":1},{"permission":{"actor":"eoslocktoken","permission":"eosio.code"},"weight":1}]}' owner -p eoslocktoken

${cu1} set account permission eosvrmarkets active '{"threshold": 1,"keys": [],"accounts": [{"permission":{"actor":"eosio","permission":"active"},"weight":1},{"permission":{"actor":"eosvrmarkets","permission":"eosio.code"},"weight":1}]}' owner -p eosvrmarkets

${cu1} set account permission eosvrrewards active '{"threshold": 1,"keys": [],"accounts": [{"permission":{"actor":"eosio","permission":"active"},"weight":1},{"permission":{"actor":"eosvrrewards","permission":"eosio.code"},"weight":1}]}' owner -p eosvrrewards

${cu1} set account permission eosvrcomment active '{"threshold": 1,"keys": [],"accounts": [{"permission":{"actor":"eosio","permission":"active"},"weight":1},{"permission":{"actor":"eosvrcomment","permission":"eosio.code"},"weight":1}]}' owner -p eosvrcomment

${cu1} set account permission evrportraits active '{"threshold": 1,"keys": [],"accounts": [{"permission":{"actor":"eosio","permission":"active"},"weight":1},{"permission":{"actor":"evrportraits","permission":"eosio.code"},"weight":1}]}' owner -p evrportraits

echo === Transfer EOS to linker ===
${cu1} transfer eosio ${linker} "10000.0000 EOS" -p eosio


echo === Invest eosvrmarkets to let the exchange work ===
${cu1} transfer eosio eosvrmarkets "10000.0000 EOS" "#INVEST#" -p eosio
${cu1} push action eoslocktoken transfer '{"from":"'${linker}'", "to":"eosvrmarkets","quantity":"100.0000 EVD","memo":"#INVEST#"}' -p ${linker}


echo === DONE ===
