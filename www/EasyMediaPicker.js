var exec = require('cordova/exec');

var PLUGIN_NAME = 'EasyMediaPicker';

var EasyMediaPicker = {
  pick: function(success, error) {
    exec(success, error, PLUGIN_NAME, "pick", []);
  }
}

module.exports = EasyMediaPicker;