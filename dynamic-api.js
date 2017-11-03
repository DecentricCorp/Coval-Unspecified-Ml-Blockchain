var compiled, deployed
var TestRPC = require("ethereumjs-testrpc")
var menu = require('appendable-cli-menu')
var readline = require('readline-sync')
const files = require("./files.js")
var bodyParser = require('body-parser')
var http = require("https")
var bitcore = require('bitcore')
var dir = "./"
var config = require('./config.js')
var YAML = require('yamljs')
var Web3 = require('web3'), web3, fromAccount, meta, verbose = false
var web3Provider = process.env.LEDGER_NODE || "http://localhost:8545"

function initWeb3() {
    if (typeof web3 !== 'undefined') {
        web3 = new Web3(web3.currentProvider)
        fromAccount = web3.eth.accounts[0]
        meta = { from: fromAccount, gas: 3000000 }
    } else {
        try {    
            web3 = new Web3(new Web3.providers.HttpProvider(web3Provider));
            fromAccount = web3.eth.accounts[0]
            meta = { from: fromAccount, gas: 3000000 }
        } catch(error){
            console.log("Exiting because you need to start testrpc")
            process.exit(0)
        }        
    }
    return web3
}

initWeb3()

function getContractByName(name) {
    return web3.eth.contract(getAbiByName(name)).at(getContractAddressByName(name))
}
function getAbiByName(name) {
    return JSON.parse(compiled.filter(function (contract) { return contract.name.split(":")[1] === name })[0].abi)
}
function getContractAddressByName(name) {
    return deployed.filter(function (contract) { return contract.name === name })[0].address
}
function getHistory(contractInstance, from, to, cb, addresses) {
    try {
        var events = contractInstance.allEvents({ fromBlock: from, toBlock: to, addresses: addresses })
        events.get(function (err, logs) {
            if (err) { return cb(errorTranslate(err)) } else {
                return cb(null, logs)
            }
        })
    } catch (err) { return cb(err.toString()) }
}
function getTransaction(txid, cb) {
    try {
        console.log(txid)
        web3.eth.getTransaction(txid, function (err, tx) {
            return cb(err, tx)
        })
    } catch (err) { return cb(err, null) }
}
function ExecuteMethod(input, cb) {
    var _input = []
    if (input[0].name !== undefined) {
        _input = ["", '']
        input.forEach(function (item) {
            _input[_input.length] = item.name
        })
    }
    if (_input.length === 0) {
        _input = input
    }
    _generated = createDynamicContractMethodBody(_input || process.argv) + createMethodParameters(_input || process.argv)
    if (verbose) { console.log("To Evaluate", _generated) }
    try {
        var result = JSON.stringify((eval(_generated)))
        var raw = result
        var _result = {}
        var outputs = getFunctionOutputs({ contract: _input[2], function: _input[3] })
        var names = outputs.names
        var types = outputs.types
        names.forEach(function (output, index) {
            if (output != "" && typeof (JSON.parse(result)) === "object") {
                //console.log("Type check!!!", types[index])
                var type = types[index]
                if (type === "bytes32") {
                    _result[output] = { string: web3.toAscii(JSON.parse(result)[index]).replace(/\u0000/g, ''), bytes32: JSON.parse(result)[index] }
                } else {
                    _result[output] = JSON.parse(result)[index]
                }
            } else {
                _result = JSON.parse(result)
            }
        })
    } catch (err) {
        _result = {"Error" : err }//JSON.stringify(err)
    }
    _meta = JSON.stringify(meta)
    console.log("//=====>  Returned Value: ", JSON.stringify(_result, null, 4))
    if (cb !== undefined) {
        return cb(JSON.stringify({ result: _result, called: makePrettyFunction(_input) }))
    }
}
function createDynamicMethod(args) {
    _generated = createDynamicContractMethodBody(args) + createMethodParameters(args)
    var result = JSON.stringify(_generated)
    var _result = eval(_generated)
    return _result
}
function createDynamicContractMethodBody(args) {
    var contract = args[2]
    var method = args[3]
    console.log("//=====>   Created method: ", makePrettyFunction(args))
    var types = getFunctionInputs({ contract: contract, function: method }).types
    var val = "getContractByName('" + contract + "')['" + method.split("::")[0] + "'][" + JSON.stringify(types) + "]"
    return val
}
function makePrettyFunction(args) {
    var name = args[2]
    var method = args[3].split("::")[0]
    var _args = JSON.parse(JSON.stringify(args))
    _args.splice(0, 4)
    _args.forEach(function (arg, index) {
        _args[index] = JSON.stringify(checkForHandlebars(arg))
    })
    var result = name + "." + method + "(" + _args + ")"
    return result.replace(/"/g, "'")
}
function createMethodParameters(args) {
    var _args = JSON.parse(JSON.stringify(args))
    _args.splice(0, 4)
    if (_args.length === 0) return ("()")
    var returnVal = "("
    _args.forEach(function (arg, index) {
        arg = checkForHandlebars(arg)
        if (arg.indexOf(" ") > -1) {
            var split = arg.split(" ")
            split.forEach(function (item) {
                _args[_args.length] = item
                returnVal += JSON.stringify(item) + ","
            })
        } else {
            returnVal += JSON.stringify(arg) + ","
        }
        if (index === _args.length - 1) { returnVal += JSON.stringify(meta) + ")" }
    })
    return (returnVal)
}
function checkForHandlebars(arg) {
    _arg = arg

    if (arg.indexOf("}}") > 1 && arg.indexOf("{{") === 0) {
        _arg = _arg.replace("{{", "").replace("}}", "")
        return getDeployedPoiValue(_arg)
    }
    return arg
}
function getDeployedPoiValue(key) {
    var pieces = key.split(".")
    var poi = deployed.filter(function (contract) { return contract.name == pieces[0] })[0]
    return poi[pieces[1]]
}
function getDeployments(cb) {
    var deployments = []
    files.load(dir, ".deployed.json", function (_files) {
        if (_files.length === 0) {
            return cb([])
        }
        _files.forEach(function (file, index) {
            var pieces = file.split("/")
            deployments[index] = pieces[pieces.length - 1].split(".")[0]
            if (index === _files.length - 1) {
                return cb(deployments)
            }
        })
    })
}
function getContractNames() {
    var names = []
    deployed.forEach(function (contract) {
        names[names.length] = contract.name
    })
    return names
}
function getMethodNames(input) {
    var abi = getAbiByName(input.name).filter(function (object) { return object.type === "function" })
    var names = []
    var duplicates = {}
    abi.forEach(function (_abi, index) {
        var name = abi[index].name
        var sameNamedMethods = abi.filter(function (__abi) { return __abi.name === name }).length > 1
        if (sameNamedMethods) {
            if (!duplicates[name]) { duplicates[name] = [] }
            duplicates[name][duplicates[name].length] = name
            names[names.length] = name + "::" + duplicates[name].length
        } else {
            names[names.length] = name
        }
    })
    return names
}
function getFunctionInputs(input) {
    var abi = getAbiByContractFunctionAndIndex(input.contract, input.function)
    inputNames = []
    inputTypes = []
    //console.log("getFunctionInputs", input.contract, input.function, abi)
    abi.inputs.forEach(function (input) {
        inputNames[inputNames.length] = input.name
        inputTypes[inputTypes.length] = input.type
    })
    return { names: inputNames, types: inputTypes }
}
function getFunctionOutputs(input) {
    var abi = getAbiByContractFunctionAndIndex(input.contract, input.function)
    outputNames = []
    outputTypes = []
    abi.outputs.forEach(function (output) {
        outputNames[outputNames.length] = output.name
        outputTypes[outputTypes.length] = output.type
    })
    return { names: outputNames, types: outputTypes }
}
function getAbiByContractFunctionAndIndex(contract, method) {
    var abi = getAbiByName(contract)
    var methodIndex = 0
    var pieces = method.split("::")
    var _method = method
    if (pieces.length > 1) {
        methodIndex = Number(pieces[1]) - 1
        _method = pieces[0]
    }
    var _abi = abi.filter(function (object) { return object.name === _method })[methodIndex]
    return _abi
}


//contract
function startEngine() {
    console.log(JSON.stringify(getContractNames(), null, 4))
    doPrompt("green", "Which Contract?", ">", function (err, result) {
        _results = [result]
        console.log(JSON.stringify(getMethodNames(result), null, 4))
        doPrompt("green", "Method?", result.name, function (err, result) {
            _results[_results.length] = result
            console.log(getFunctionInputs(_results))
            doPrompt("green", "Parameters?", result.name, function (err, result) {
                _results[_results.length] = result
                ExecuteMethod(_results)
                startEngine()
            })
        })
    })
}
var dynamicMenu
function startMenuEngine() {
    getDeployments(function (deployments) {
        makeMenu("Select a deployment", deployments, "Deployment", function (selectedDeployment) {
            console.log("Selected Deployment", selectedDeployment.name)
            loadSelectedDeployment(selectedDeployment.name)
            makeMenu("Select a Contract", getContractNames(), "Contract", function (selectedContract) {
                var _results = [1, 2, selectedContract.name]
                console.log(selectedContract)
                makeMenu("Select a Function", getMethodNames(selectedContract), "Method", function (selectedMethod) {
                    _results[_results.length] = selectedMethod.name
                    console.log(selectedMethod.name)
                    var params = getFunctionInputs({ contract: selectedContract.name, function: selectedMethod.name })
                    makeRecursiveMenu(0, "Parameter", [], params.names, params.types, function (values) {
                        values.forEach(function (item) { _results[_results.length] = item.value })
                        makeMenu("Execute?", [makePrettyFunction(_results), "cancel"], "string", function (proceed) {
                            if (proceed.name !== "cancel") {
                                ExecuteMethod(_results, function (result) {
                                    console.log("==> ", result)
                                    startMenuEngine()
                                })
                            }
                        })
                    })
                })
            })
        })
    })
}

function loadSelectedDeployment(deployment) {
    compiled = require(dir + deployment + ".compiled.json")
    deployed = require(dir + deployment + ".deployed.json")
}

var makeRecursiveMenu = function (index, title, populated, items, type, final) {
    //console.log("Menu", "index",index, "title",title, "populated",populated, "items",items, "type", type)
    if (items.length === 0) {
        return final([])
    }
    var _title = title + " " + (Number(index) + 1)
    _items = items.filter(function (item) {
        return populated.filter(function (popItem) {
            return popItem.name === item
        }).length < 1
    })
    var callback = function (selected) {
        var val = readline.question(selected.name + " (" + selected.type + "): ")
        selected.value = val
        populated[populated.length] = selected
        if (index === items.length - 1) {
            return final(populated)
        } else {
            return makeRecursiveMenu(Number(index) + 1, title, populated, items, type, final)
        }
    }
    makeMenu(_title, _items, type, callback)

}

var makeMenu = function (title, items, type, cb) {
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

function startWebEngine() {
    var express = require('express')
    var app = express()
    app.set('json spaces', 4)

    app.use(function (req, res, next) {
        res.header("Access-Control-Allow-Origin", "*")
        res.header("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept")
        next()
    })
    app.use(bodyParser.json())

    app.get('/', function (req, res) {
        res.json({ author: "Shannon Code (Decentric)" })
    })

    /* History */
    app.get('/v1/history/:deployment/:contract', function (req, res) {
        if (!req.params.deployment) {
            return res.json({msg: "No deployment provided"})
        }
        try {
            loadSelectedDeployment(req.params.deployment)
            var name = checkForHandlebars(req.params.contract)
            var contractInstance = getContractByName(name)
            getHistory(contractInstance, req.query.from || 0, req.query.to || 'latest', function (err, logs) {
                var events = []
                if (err) { res.json({ 'error': err }) } else {
                    logs.forEach(function(log, index){
                        var event = log
                        event.id = index
                        event.description = event.event + " event in block # " + event.blockNumber
                        events[events.length] = event
                    })
                    res.json(events)
                }
            })
        } catch (e) {
            res.json({ 'error': e })
        }
    })

    /* Transaction */
    app.get('/v1/transaction/:txid', function(req, res){
        getTransaction(req.params.txid, function(err, transaction){
            if (err) {
                res.json({ 'error': err })
            } else {
                res.json(transaction)
            }
        })
    })    

    function replaceHandleBarsWithResult(template, results, cb){
        params = []
        var templatePotentials = template.split("{")
        if (templatePotentials.length === 1) {
            return cb(template)
        }
        return templatePotentials.forEach(function(item, index){
            if (item.indexOf("}}")>2) {
                paramPieces = item.split("}}")[0].split(".")
                if (paramPieces[0] === "results" && results[paramPieces[1]]) {
					params[params.length] = {find: "{{"+paramPieces.join(".")+"}}", replace: results[paramPieces[1]] }
                }
            }
            /* done */
            if (index === templatePotentials.length -1 ) {
                var templated = template
                return params.forEach(function(item, index){
                    templated = templated.replace(item.find, item.replace)
                    /* done */
                    if (index === params.length -1) {
                        console.log("returning", templated)
                        return cb(templated)
                    }
                })
            }
        })
    }

    function calculateIntentPath(req, cb){
        var intentAction = req.body.result.action
        var response, perform
        console.log("Intent Action", intentAction)
        switch (intentAction) {
            case "query.balance":
                response = "You have a balance of {{results.balance}}"
                perform = bootstrapAddress
            break;
            case "query.address":
                response = "Your address is {{results.address}}"
                perform = newAddressWithGrant
            break;
            case "send":
                response = "{{results.response}}"
                perform = handleSend
            break;
            case "query.prism":
                response = "Here are the top {{results.count}} Prism Portfolios of {{results.totalCount}} total Portfolios{{results.response}}"
                perform = handlePrismBotQuery
            break;
            default:
                response = "Not sure..."
                perform = function(){}
            break;
        }
        return cb({perform: perform, response:response})
    }
    

    /* Perform execution (Must remain at the end as the fallthrough finally or it will trigger for most every api call) */
    app.get('/v1/:deployment?/:contract?/:method?/:perform?', function (req, res) {
        handleDynamicApiCall(req, res)
    })


    var port = process.env.PORT || 4333
    global.app = app
    app.listen(port)
    console.log('API running at http://localhost:' + port + "/v1/")
}
function describeMethods(req) {
    var contract = req.params.contract
    var methods = getMethodNames({ name: contract })
    var result = { contract: contract, methods: methods }
    return result
}
function describeParameters(req) {
    var search = { contract: req.params.contract, function: req.params.method }
    var result = { inputs: getFunctionInputs(search), outputs: getFunctionOutputs(search) }
    var _result = { inputs: [], outputs: [] }
    result.inputs.names.forEach(function (input, index) {
        _result.inputs[_result.inputs.length] = { name: result.inputs.names[index], type: result.inputs.types[index] }
    })
    result.outputs.names.forEach(function (output, index) {
        _result.outputs[_result.outputs.length] = { name: result.outputs.names[index], type: result.outputs.types[index] }
    })
    return _result
}

function collectMethodsAndParameters(req) {
    var results = describeMethods(req)
    var _methods = []
    results.methods.forEach(function (method, index) {
        req.params.method = method
        var params = describeParameters(req)
        _methods[index] = { 
            name: method, 
            params: params,
            template: getFullUrl(req) + "/" + method
        }
    })
    result = _methods
    return result
}
var handleDynamicApiCall = function (req, res) {
    var action
    var perform = req.params.perform
    var executionArray = [1, 2]
    var deployment = req.params.deployment
    if (!deployment) {
        action = "deployments"
        return chooseAction(action, req, res)
    } else {
        action = "contracts"
        loadSelectedDeployment(deployment)
    }
    var contract = req.params.contract
    if (!contract || contract === "contracts") {
        action = "contracts"
        return chooseAction(action, req, res)
    } else {
        executionArray.push(contract)
    }
    var debug = req.query.debug
    var method = req.params.method
    if (!method) {
        action = "describe"
        return chooseAction(action, req, res)
    } else {
        executionArray.push(method)
    }
    var args = req.query.args
    if (!args && !perform) {
        var params = describeParameters(req)
        //if (params.inputs.length > 0) {
        action = "parameters"
        return chooseAction(action, req, res)
        //}
    } else {
        executionArray = arrayify(args, executionArray)
    }
    if (method === "methods" || method === "functions") {
        action = "methods"
        return chooseAction(action, req, res)
    }
    if (debug) {
        res.json({ contract: contract, method: method, args: args, executionArray: executionArray })
    } else {
        if (perform && perform === "exec") {
            ExecuteMethod(executionArray, function (executionResult) {
                var parsedResult = JSON.parse(executionResult).result
                var method = JSON.parse(executionResult).called.replace(/"/g, "'")
                res.json({ parsedResult, method: method })
            })
        }
    }
}

var chooseAction = function (action, req, res) {
    var fullUrl = getFullUrl(req)
    var result = { action: action }
    //console.log("Action", action === "deployments")
    function cb(result) {
        if (!result.action) {
            result.action = { describe: action }
        }
        res.json(result)
    }
    switch (action) {
        case "deployments":
            getDeployments(function (deployments) {
                var deploymentItems = {}
                if (deployments.length > 0) {
                    deployments.forEach(function(name, index){
                        deploymentItems[name] = {
                            id: index, 
                            deployment: name,
                            template: fullUrl + name
                        }
                        if (index === deployments.length -1 ) {
                            return cb(deploymentItems)
                        }
                    })
                } else {
                    loadFiles(config.scenariosDirectory, ".yaml", function (scenario_files) {
                        var scenarios = {}
                        deploymentItems = {"deployments": []}
                        scenario_files.forEach(function(scenario_file, index){
                            var scenario_name = scenario_file.replace(config.scenariosDirectory.replace('./',''),'').replace('.yaml','')
                            scenarios[scenario_name] = {
                                "template": fullUrl + "deploy/" + scenario_name,
                                "yaml": YAML.load(scenario_file)
                            }
                            if (index === scenario_files.length -1) {
                                deploymentItems.scenarios = scenarios
                                return cb(deploymentItems)
                            }                            
                        })
                    })                    
                }

                
            })
            break;
        case "arguments":
        case "args":
        case "parameters":
        case "params":
            result = describeParameters(req)
            result.contract = req.params.contract
            result.method = req.params.method
            result.template = createTemplateUrl(result.contract, result.method, fullUrl)
            return cb(result)
        case "methods":
        case "functions":
            result = describeMethods(req)
            return cb(result)
        case "describe":
            result = { methods: collectMethodsAndParameters(req) }
            result.action = { describe: req.params.contract }
            return cb(result)
        case "contracts":
        var contracts = getContractNames()
            var contractItems = []
                contracts.forEach(function(name, index){
                    contractItems[contractItems.length] = {
                        id: index, 
                        contract: name,
                        template: fullUrl + "/" + name   
                    }
                    if (index === contracts.length -1) {
                        return cb(contractItems)
                    }
                })
            
    }
    if (req.query.debug) {
        result.action = action
        result.method = method
        result.contract = contract
    }
}
var createTemplateUrl = function (contract, method, fullUrl) {
    var search = { contract: contract, function: method }
    var types = getFunctionInputs(search).names.join(",")
    fullUrl = fullUrl.split('?decache')[0]
    fullUrl = fullUrl + "/exec"
    if (types) {
        fullUrl = fullUrl + "?args=" + types
    }
    return fullUrl
}
function getFullUrl(req) {
    return req.protocol + '://' + req.get('host') + req.originalUrl;
}
function arrayify(args, appendable) {
    if (args) {
        var split = args.split(",")
        appendable.extend(split)
    }
    return appendable
}

Array.prototype.extend = function (other_array) {
    /* you should include a test to check whether other_array really is an array */
    other_array.forEach(function (v) { this.push(v) }, this);
}

function doPrompt(color, msg, notice, callback) {
    prompt.message = colors.grey(notice || ">");
    prompt.get({
        properties: {
            name: {
                description: colors[color || "green"](msg)
            }
        }
    }, callback)
}
if (!module.parent) {
    chooseExecutionPath()
}

function chooseExecutionPath(args) {
    if (!args) { args = process.argv }
    if (args.length < 4) {
        if (args[2] === "web" || args[1] === "web" || args[0] === "web") {
            startWebEngine()
        } else {
            startMenuEngine()
        }
    } else {
        ExecuteMethod(args)
    }
}

function loadFiles(path, ext, cb) {
    files.load(path, ext || ".json", function (_files) {
        return cb(_files)
    })
}
module.exports.initWeb3 = initWeb3
module.exports.YAML = YAML
module.exports.loadFiles = loadFiles
module.exports.setDir = function (_dir) { dir = _dir }
module.exports.exec = chooseExecutionPath
module.exports.handleDynamicApiCall = handleDynamicApiCall
module.exports.chooseAction = chooseAction
module.exports.loadSelectedDeployment = loadSelectedDeployment
