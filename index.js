var solc = require('solc')
const fs = require('fs')
var ethUtil = require('ethereumjs-util')
var menu = require('appendable-cli-menu')
require('dotenv').config()
const files = require("./files.js")
var config = require('./config.js')
var dynamicApi = require('./dynamic-api.js')
var scenarioName,
    scenarioYamlFilename,
    scenarioJsonFilename,
    compiledContractsFilename,
    deployedContractsFilename,
    yaml2JsonObject,
    contractCollection,
    transactionCollection,
    _events = 0,
    compiledContracts,
    safeCompiledContracts,
    deployedContracts,
    safeDeployedContracts,
    finishedDeploying = 0,
    returns = 0,
    verbose = true
var Web3 = require('web3'), web3
var fromAcountIndex = process.env.ACCOUNT_INDEX || 0, fromAccount
var web3Provider = process.env.LEDGER_NODE || "http://localhost:8545" 


web3 = dynamicApi.initWeb3()
fromAccount = web3.eth.accounts[0]
meta = { from: fromAccount, gas: 3000000 }

function writeFile(fileName, data) {
    writeFileSync(fileName, data, function () { })
}

function writeFileSync(fileName, data, cb) {
    fs.writeFile(fileName, data, "utf8", function (err) {
        return cb()
    })
}

function compileContractCollection(collectionIndex, contractCollection, cb) {
    var input = {}
    var collection = contractCollection[collectionIndex].contract
    //console.log(collection)
    var sources = collection.sources

    var name = collection.name
    sources.forEach(function (contract, index) {
        fs.readFile(config.contractsDirectory + contract, 'utf8', function (err, data) {
            input[contract] = data
            if (index === sources.length - 1) {
                let compiledContract = solc.compile({ sources: input }, 1)
                let key = extractKey(name, compiledContract.contracts)
                if (verbose) {
                    console.log("key", key, compiledContract, name)
                    console.log("======> Debug", compiledContract.contracts, key)
                }
                let abi = compiledContract.contracts[key].interface;
                let bytecode = compiledContract.contracts[key].bytecode;
                let gasEstimate = web3.eth.estimateGas({ data: bytecode });
                let Contract = web3.eth.contract(JSON.parse(abi));
                compiledContracts[compiledContracts.length] = { 
                    contract: Contract, 
                    name: key, 
                    abi: abi, 
                    bytecode: bytecode, 
                    gasEstimate: gasEstimate, 
                    index: collectionIndex, 
                    preComputedAddress: computeContractAddress(collectionIndex) 
                }
                safeCompiledContracts[safeCompiledContracts.length] = { name: key, abi: abi, bytecode: bytecode, gasEstimate: gasEstimate, index: collectionIndex, preComputedAddress: computeContractAddress(collectionIndex) }
                //console.log("Compiled contract", name, compiledContracts.length, "of", contractCollection.length)
                if (collectionIndex === contractCollection.length - 1) {
                    writeFileSync(compiledContractsFilename, JSON.stringify(safeCompiledContracts, null, 4), function () {
                        deployContracts(compiledContracts, 0, cb)
                    })
                } else {
                    compileContractCollection(collectionIndex + 1, contractCollection, cb)
                }
            }
        })
    })
}

function extractKey(name, contracts) {
    for (var key in contracts) {
        if (contracts.hasOwnProperty(key)) {
            if (key.split(":")[1] === name)
                return key
        }
    }
}

function deployContracts(compiledContracts, deployIndex, _cb) {
    console.log("DEPLOYING")
    var context = compiledContracts[deployIndex]
    var args = contractCollection[deployIndex].contract.args
    var argValues = []
    args.forEach(function (key) {
        argValues[argValues.length] = getDeployedPoiValue(key)
    })
    function next() {
        if (deployIndex === compiledContracts.length - 1) {
            writeFile(deployedContractsFilename, JSON.stringify(safeDeployedContracts, null, 4))
            if (transactionCollection.length > 0) {
                performTransactions(deployedContracts, 0, _cb)
            } else {
                return _cb()
            }            
        } else {
            deployContracts(compiledContracts, deployIndex + 1, _cb)
        }
    }

    var cb = function (err, Contract) {
        var computedAddress = computeContractAddress(deployIndex)
        if (!err) {
            if (!Contract.address) {
                console.log("Deployed", context.name)
            } else {
                deployedContracts[deployedContracts.length] = { name: context.name.split(":")[1], txid: Contract.transactionHash, address: Contract.address, contract: Contract, preComputedAddress: computedAddress }
                safeDeployedContracts[safeDeployedContracts.length] = { name: context.name.split(":")[1], txid: Contract.transactionHash, address: Contract.address, preComputedAddress: computedAddress }
                //watchContract(Contract, context.name.split(":")[1], _cb)
                next()
            }
        } else {
            console.log(err)
            next()
        }
    }
    //console.log(argValues)
    context.contract.new(argValues, {
        from: fromAccount,
        data: context.bytecode,
        gas: context.gasEstimate
    }, cb)
}

function performTransactions(deployedContracts, transactionIndex, cb) {
    var tx = transactionCollection[transactionIndex]    
    var target = deployedContracts.filter(function (contract) {
        return contract.name === tx.where
    })[0]
    var targetContract = target.contract
    var method = tx.call.split("(")[0]
    //console.log(target.name, method, getDeployedPoiValue(tx.args[0]), transactionIndex)
    var on = deployedContracts.filter(function (contract) { return contract.name === target.name })[0]
    var dynamic = on.contract[method]
    _events += 1
    dynamic(getDeployedPoiValue(tx.args[0]), meta, function (err, result) {
        returns = returns + 1
        //console.log(_events, returns)        
        //console.log(target.name, "return value", result)
        if (_events === returns) {
            return cb()
        }
    })

    if (transactionIndex === transactionCollection.length - 1) {

    } else {
        performTransactions(deployedContracts, transactionIndex + 1, cb)
    }
}

function watchAllContracts() {
    deployedContracts.forEach(function (context) {
        console.log("Logging events for", context.name)
        var events = context.contract.allEvents(function (err, log) {
            console.log(context.name, log);
        })
    })
}

function watchContract(contract, name) {
    return
    console.log("Logging events for", name)
    var events = contract.allEvents(function (err, log) {
        console.log(name, log);
    })
}

function getContractByName(name) {
    return deployedContracts.filter(function (contract) { return contract.name === name })[0]["contract"]
}

function createFunctionCall(name, method, args, multiplier) {
    var context = deployedContracts.filter(function (contract) { return contract.name === name })[0]
    var dynamic = context.contract[method]
    if (dynamic) {
        args[args.length] = { from: fromAccount, gas: 3000000 }
        args[args.length] = function (err, result) {
            if (err) {
                console.log(err.toString())
            } else {
                console.log("Called", name, method, "with", args.splice(0, args.length - 2))
                console.log("  `- Txid", result)
            }
        }
        return dynamic
    } else {
        console.log("Error")
    }
}

function getDeployedPoiValue(key) {
    var pieces = key.split(".")
    if (pieces.length > 1) {
        var poi = deployedContracts.filter(function (contract) { return contract.name == pieces[0] })[0]
        return poi[pieces[1]]
    } else return key
}

function computeContractAddress(providedIndex) {
    console.log("Calculate address", providedIndex)
    //process.exit()
    var modifier = providedIndex || -1
    var currentNonce = web3.eth.getTransactionCount(fromAccount) + modifier
    console.log("current nonce", currentNonce, fromAccount)
    //process.exit()
    var calculated = ethUtil.generateAddress(fromAccount, currentNonce)
    console.log("Calculated", calculated)
    return ethUtil.bufferToHex(calculated)
}

function makeMenu(title, items, type, cb) {
    var _menu = menu(title, cb)
    items.forEach(function (item, index) {
        _type = type
        if (typeof (_type) === "object") {
            _type = type[index]
            item = item
        }
        _menu.add({ name: item, value: index, type: _type })
    })
    return _menu
}

function startEngine() {
    process.stdout.write('\x1B[2J\x1B[0f');
    if (process.argv[2] === "web") {
        return startDynamicWebApi()
    }
    if (process.argv[2] === "info") {
        return displayNetworkDetails()
    }
    makeMenu("Select a task", [
        "Compile & Deploy Scenario",/* 
        "Compile & Deploy single Contract", */
        "Interact with deployed Contract CLI",
        "Interact with deployed Contracts REST Api",
        /* "Display Web3 Network Details" */
    ], "Action", function (result) {
        if (result.name === "Compile & Deploy Scenario") {
            startCompileScenario()
        } /* else if (result.name === "Compile & Deploy single Contract") {
            startCompileContract()
        } */ else if (result.name === "Interact with deployed Contract CLI") {
            startDynamicApi()
        } else if (result.name === "Interact with deployed Contracts REST Api") {            
            startDynamicWebApi()
        } /* else if (result.name === "Display Web3 Network Details") {
            displayNetworkDetails()
        } */
    })
}

function displayNetworkDetails(){
    var networkInfo = {
        account: web3.eth.accounts[fromAcountIndex],
        accountIndex: fromAcountIndex,
        accountBalance: web3.eth.getBalance(web3.eth.accounts[fromAcountIndex]).toNumber(),
        isMining: web3.eth.mining,
        lastBlock: web3.eth.blockNumber,
        provider: JSON.parse(JSON.stringify(web3._requestManager.provider)).host,

    }
    console.log(JSON.stringify(networkInfo, null, 4))
}

function startCompileScenario() {
    dynamicApi.loadFiles(config.scenariosDirectory, ".yaml", function (files) {
        _files = adjustFilenames(files, ".yaml")
        makeMenu("Select Scenario", _files, "Scenario", function (result) {
            scenarioName = result.name
            initFiles(scenarioName, function () {
                compileContractCollection(0, contractCollection, function () {
                    startEngine()
                })
            })
        })
    })
}

function startCompileContract() {
    dynamicApi.loadFiles(config.contractsDirectory, ".sol", function (files) {
        _files = adjustFilenames(files, ".sol")
        makeMenu("Select Contract", _files, "Contract", function (result) {
            console.log("Mocked")
            startEngine()
        })
    })
}

function startDynamicApi() {
    //var fork = require('child_process').fork
    //var child = fork('./dynamic-api.js')
    dynamicApi.exec()
}

function startDynamicWebApi() {
    //var fork = require('child_process').fork
    //var child = fork('./dynamic-api.js',['web'])
    dynamicApi.exec(["web"])
}

function adjustFilenames(files, ext) {
    var _files = []
    files.forEach(function (file) {
        var pieces = file.split("/")
        _files[_files.length] = pieces[pieces.length - 1].replace(ext, "")
    })
    return _files
}

function initFiles(scenarioName, cb) {
    //scenarioName = process.env.scenario || "Scenario2"
    events = 0
    contractCollection = []
    scenarioYamlFilename = scenarioName + ".yaml"
    scenarioJsonFilename = scenarioName + ".yaml.json"
    compiledContractsFilename = scenarioName + ".compiled.json"
    deployedContractsFilename = scenarioName + ".deployed.json"
    yaml2JsonObject = dynamicApi.YAML.load(config.scenariosDirectory + scenarioYamlFilename)
    contractCollection = yaml2JsonObject.filter(function (item) { return item.contract !== undefined })
    transactionCollection = yaml2JsonObject.filter(function (item) { return item.contract === undefined || item.call })
    writeFile(scenarioJsonFilename, JSON.stringify(yaml2JsonObject, null, 4))
    compiledContracts = []
    safeCompiledContracts = []
    deployedContracts = []
    safeDeployedContracts = []
    finishedDeploying = 0
    return cb()
}

if (!module.parent) {
    startEngine()
}

module.exports.compiler = startEngine
module.exports.interact = dynamicApi.exec
module.exports.handleDynamicApiCall = dynamicApi.handleDynamicApiCall
module.exports.setDir = dynamicApi.setDir
module.exports.chooseAction = dynamicApi.chooseAction
module.exports.loadSelectedDeployment = dynamicApi.loadSelectedDeployment