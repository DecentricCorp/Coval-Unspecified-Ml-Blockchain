var path = require('path'), 
    fs   = require('fs');
var verbose = false
/**
 * Find all files recursively in specific folder with specific extension, e.g:
 * findFilesInDir('./project/src', '.html', function(filenames){} ==> ['./project/src/a.html','./project/src/build/index.html'])
 * @param  {String} startPath    Path relative to this file or other file which requires this files
 * @param  {String} filter       Extension name, e.g: '.html'
 * @param  {Function} cb         Callback function containing result files with path string in an array
 */
function findFilesInDir(startPath, filter, cb){
    /* DEBUG */if (verbose) console.log("path",startPath, "filter",filter, "cb", cb)
    var results = [];

    if (!fs.existsSync(startPath)){
        console.log("no dir ",startPath)
        return;
    }
    
    var files=fs.readdirSync(startPath)
    for(var i=0;i<files.length;i++){
        var filename=path.join(startPath,files[i])
        var stat = fs.lstatSync(filename)
        /*if (stat.isDirectory()){
            results = results.concat(findFilesInDir(filename,filter)) //recurse
        }
        else*/ if (filename.indexOf(filter)>=0) {
            results.push(filename)
        }
    }

    return cb(results)
}

module.exports.load = findFilesInDir