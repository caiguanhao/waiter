var http = require('http');
var fs = require('fs');
var path = require('path');
var port = 34987;
var KEY = fs.readFileSync(path.join(__dirname, 'key')).toString().trim();

var server = http.createServer(function(req, res) {
  var url = req.url;
  var method = req.method;
  var headers = req.headers;
  var ipaddr = req.headers['x-forwarded-for']
            || req.connection.remoteAddress
            || req.socket.remoteAddress;

  if (method === 'GET' && url === '/waiter') {
    if (IsIPAddrInWhiteList(ipaddr)) {
      try {
        var enabled = path.join(__dirname, 'enabled.bat');
        fs.createReadStream(enabled).pipe(res);
        return;
      } catch(e) {}
    }
    return NotFound();
  }

  if (method === 'POST' && url === '/screenshot') {
    if (!headers || !headers.key || headers.key !== KEY) return NotFound();

    var pubpath;
    pubpath = path.join(__dirname, 'public');
    MakeDir(pubpath);
    pubpath = path.join(pubpath, 'screenshots');
    MakeDir(pubpath);

    var filepath = path.join(pubpath, ipaddr + '.jpg');
    req.pipe(fs.createWriteStream(filepath));
    req.on('end', function() {
      res.end();
    });
    return;
  }

  function IsIPAddrInWhiteList(ipaddr) {
    if (!ipaddr) return false;
    var whitelist = [];
    try {
      var wl = path.join(__dirname, 'whitelist');
      whitelist = fs.readFileSync(wl).toString().trim().split('\n');
    } catch(e) {}
    if (whitelist.indexOf('all') > -1) return true;
    return whitelist.indexOf(ipaddr) > -1;
  }

  function MakeDir(path) {
    try {
      fs.mkdirSync(path);
    } catch(e) {}
  }

  function NotFound() {
    res.writeHead(404);
    res.end();
  }

  return NotFound();
});

server.listen(port, '0.0.0.0', function() {
  console.log('waiter has started listening on port ' + port + '.');
});
